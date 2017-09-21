//
//  DSARestClient.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DSARestClient.h"
#import "DSA_AppDelegate.h"
#import "MM_SyncManager.h"
#import "MM_Config.h"
#import "MM_Notifications.h"
#import "Network.h"
#import "MMSF_User.h"
#import "DSA_RemoteObjectStatusClient.h"
#import "DSARestClient+SyncStatus.h"
#import "DSA_SyncProgressViewController.h"
#import "DSA_BaseTabsViewController.h"
#import "MM_OrgMetaData.h"
#import "MMSF_Playlist_Content_Junction__c.h"
#import "MMSF_DSA_Playlist__c.h"

@interface DSARestClient ()
@property (nonatomic, assign) BOOL metaDataRefresh;
@end

@implementation DSARestClient

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(DSARestClient, sharedInstance);

- (void)observe {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver: self selector: @selector(syncBegan:) name: kNotification_SyncBegan object: nil];
    [center addObserver: self selector: @selector(syncResumed:) name: kNotification_SyncResumed object: nil];
    [center addObserver: self selector: @selector(syncCompleted:) name: kNotification_SyncComplete object: nil];

    [center addObserver: self selector: @selector(networkStatusChanged:) name: RKReachabilityDidChangeNotification object: nil];
    [center addObserver: self selector: @selector(connectionStateChanged:) name: kConnectionNotification_ConnectionStateChanged object: nil];
    //[self addAsObserverForName: kOAuthTokenWasRevokedNotification selector: @selector(tokenRevoked:)];
    
    [center addObserver: self selector: @selector(modelUpdateBegan:) name: kNotification_ModelUpdateBegan object: nil];
    [center addObserver: self selector: @selector(objectsImported:) name: kNotification_ObjectsImported object: nil];
    [center addObserver: self selector: @selector(objectSyncCompleted:) name: kNotification_ObjectSyncCompleted object: nil];
    [center addObserver: self selector: @selector(syncBatchReceived:) name: kNotification_SyncBatchReceived object: nil];
    [center addObserver: self selector: @selector(prepareThePostSyncOperations) name: kNotification_PostSyncOpsDone object: nil];
    
    [center addObserver:self selector:@selector(loginControllerDidDismiss:) name:kNotification_LoginViewControllerDidDismiss object:nil];
    [center addObserver:self selector:@selector(queueingComplete:) name:kNotification_QueueingComplete object:nil];
    [center addObserver:self selector:@selector(missingLinksConnectionStarting:) name:kNotification_MissingLinksConnectionStarting object:nil];
}

- (id) init {
	if ((self = [super init])) {
        completedSyncObjects = [[NSMutableArray alloc] init];
        [self observe];
        attachmentCounter = 0;
        contentCounter = 0;
	}
    
	return self;
}

- (void)presentSyncProgress {
    if (!self.syncProgressViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DSA_SyncProgress" bundle:nil];
        self.syncProgressViewController = [storyboard instantiateViewControllerWithIdentifier:@"DSA_SyncProgressViewController"];
        self.syncProgressViewController.titleLabel.text = @"Preparing to Synchronize...";
        if (self.metaDataRefresh) {
            self.syncProgressViewController.titleLabel.text = @"Updating MetaData...";
            self.syncProgressViewController.updatingMetaData = YES;
        }
        self.syncProgressViewController.delegate = self;
        [g_appDelegate.baseViewController presentViewController:self.syncProgressViewController animated:YES completion:nil];
    }
}

-(void)syncPaused:(NSNotification*)note {
    [self.syncProgressViewController noticeSyncInterupted:note];
}

- (void) connectionStateChanged: (NSNotification *) note {
    [self.syncProgressViewController noticeSyncInterupted:note];
}

- (void) networkStatusChanged:(NSNotification *) note {
	if ([SA_ConnectionQueue sharedQueue].offline) {
        [self.syncProgressViewController noticeSyncInterupted:note];
    }
}

// called from App Delegate
- (void) connectWithSalesForce:(NSNotification*)note {
    MMSF_Object			*user = [[MM_SyncManager currentUserInContext: nil] valueForKey: @"Id"];
    BOOL				isNewUser = [[note.userInfo objectForKey: LOGIN_NEW_USER_LOGGED_IN_KEY] boolValue] || user == nil;
    
    [self presentSyncProgress];
    
    if (isNewUser) {
#if IF_CONTENT_DELETE_TESTING
        [SA_AlertView showAlertWithTitle: @"New User Logged In" message: @"Deleting all existing data"];
#endif
        NSFileManager *filemgr =[NSFileManager defaultManager];
        NSString* path = [@"~/Library/Private Documents" stringByExpandingTildeInPath];
        
        for (NSString* item in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil])
        {
            MMLog(@"Deleting item: %@", [NSString stringWithFormat:@"%@/%@",path,item]);
            if ([filemgr removeItemAtPath: [NSString stringWithFormat:@"%@/%@",path,item] error: nil] == NO)
            {
                MMLog(@"UserChanged:Not Able to remove %@", item);
            }
        }
        [[MM_ContextManager sharedManager] removeAllDataIncludingMetaData: NO withDelay: 0.3];
        [MM_SFObjectDefinition clearServerObjectNames];
    }
    
    
    [NSObject performBlock: ^{
        MMLog(@"Logged in with user %@", user ?: @"new user");
        
        if ([[MM_OrgMetaData sharedMetaData] isMetadataAvailableForObjects: nil] && isNewUser) {
            /*
             * Remove main DB .
             */
            if ([[NSFileManager defaultManager] fileExistsAtPath: [MM_ContextManager sharedManager].contentContextPath]) {
                NSError			*error = nil;
                
                [[NSFileManager defaultManager] removeItemAtPath: [MM_ContextManager sharedManager].contentContextPath error: &error];
                if (error) [SA_AlertView showAlertWithTitle: NSLocalizedString(@"An error occurred while clearing out data.", @"An error occurred while clearing out data.") error: error];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_DidRemoveAllData object: nil];
            
            /*
             * Remove data from metadata DB to handle adding new fields in metadata.
             */
            NSArray *oldContentToRemove = [NSArray arrayWithObjects:@"SFChange",@"SFObjectDefinition", nil];
            NSError * error = nil;
            
            for (NSInteger i = 0; i < [oldContentToRemove count]; i++) {
                NSFetchRequest* fetch = [[NSFetchRequest alloc] init];
                [fetch setEntity:[NSEntityDescription entityForName:[oldContentToRemove objectAtIndex:i] inManagedObjectContext:[MM_ContextManager sharedManager].mainMetaContext]];
                NSArray* configs = [[MM_ContextManager sharedManager].mainMetaContext executeFetchRequest:fetch error:&error];
                for (NSManagedObject *config in configs) {
                    [[MM_ContextManager sharedManager].mainMetaContext deleteObject:config];
                }
                MMLog(@"Removing all records from %@", [oldContentToRemove objectAtIndex:i]);
                [[MM_ContextManager sharedManager].mainMetaContext save:&error];
            }
            
            [[NSUserDefaults standardUserDefaults] setValue:nil forKey:kUserDefaultKey_selectedMobileAppConfig];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_UserChange object:nil];
            
            [self performSync: NO];
            
        }
        else
        {
            [self performSync: NO];
        }
    } afterDelay: 1.0];
}

// TODO: make all syncs follow the same path: only initial sync uses this path
- (void) performSync: (BOOL) full {
	if (full) {
		[[MM_SyncManager sharedManager] fullResync: nil withCompletionBlock: nil];
		return;
	}

	// TODO: move to MM_SyncManager
    simpleBlock			fetchAndSyncBlock = ^{
		[[MM_SyncManager sharedManager] fetchRequiredMetaData: NO withCompletionBlock: ^{
            [[MM_SyncManager sharedManager] synchronize: nil withCompletionBlock:nil];
		}];
	};
	
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
    if (![[MM_OrgMetaData sharedMetaData] isMetadataAvailableForObjects: nil]) {
		[[MM_SyncManager sharedManager] downloadObjectDefinitionsWithCompletionBlock: fetchAndSyncBlock];
	} else {
		[[MM_SyncManager sharedManager] performDeltaSyncWithCompletion: nil];
	}
}

- (void) deltaSync {
    BOOL started = [[MM_SyncManager sharedManager] deltaSyncWithCompletionBlock:nil];
    if (started) {
        [self presentSyncProgress];
    }
}

- (void) fullSync {
    BOOL started = [[MM_SyncManager sharedManager] resyncAllDataIncludingMetadata: NO withCompletionBlock: nil];
    if (started) {
        [self presentSyncProgress];
    }
}

#pragma mark - Meta Data refresh

- (void)rememberCurrentVersion {
    NSString *currentVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:currentVersionString forKey:kUserDefaultKey_lastUpgradedVersion];
}

- (BOOL)refreshMetaDataIfNeeded {
    BOOL shouldRefreshMetaData = NO;
    
#ifdef METADATA_REFRESH
    MMLog(@"%@", @"Checking if metadata refresh needed...");

    NSString *currentVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastUpgradedVersionString = [defaults objectForKey:kUserDefaultKey_lastUpgradedVersion];
    
    // has the last upgraded version been written
    if (!lastUpgradedVersionString || !lastUpgradedVersionString.length) {
        // new install? previous content sync will be non-nil and in the distant past
        NSDate *previousContentSyncDate = [defaults valueForKey:kUserDefaultKey_previousContentSyncDate];
        if (previousContentSyncDate && [previousContentSyncDate isEqualToDate:[NSDate distantPast]]) {
            MMLog(@"%@", @"New install - no metadata refresh needed");
            [self rememberCurrentVersion];
        } else {
            shouldRefreshMetaData = YES;
            MMLog(@"%@", @"Will refresh metadata - no upgrade version found");
       }
    } else if ([currentVersionString compare:lastUpgradedVersionString options:NSNumericSearch] == NSOrderedDescending) {
        shouldRefreshMetaData = YES;
        MMLog(@"Will update metadata - last upgrade version: %@ is older than current version: %@", lastUpgradedVersionString, currentVersionString);
    }
        
    if (shouldRefreshMetaData) {
        self.metaDataRefresh = YES;
        [[MM_SyncManager sharedManager] fetchRequiredMetaData:YES withCompletionBlock: ^ {
            // metadata refresh complete, write version number
            MMLog(@"%@", @"Metadata fetch complete");
            [self rememberCurrentVersion];
            
            // clear out anything metadata refresh might have touched
            [[MM_SyncStatus status] markSyncComplete];
            [MM_SyncManager sharedManager].isSyncInProgress = NO;
            [MM_SyncManager sharedManager].syncInterrupted = NO;
            
            [[MM_SyncManager sharedManager] connectMissingLinks];
        }];
    }
    
#endif  // METADATA_REFRESH
    
    return shouldRefreshMetaData;
}

#pragma mark - DSA_SyncProgressViewControllerDelegate

- (void)syncProgressControllerDidFinish:(DSA_SyncProgressViewController *)controller {
    if (controller == self.syncProgressViewController) {
        MMLog(@"%s", __FUNCTION__);
        [g_appDelegate.baseViewController dismissViewControllerAnimated:YES completion:^ {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_SyncProgressDidDismiss object:nil];
            self.syncProgressViewController = nil;
        }];
    }
}

#pragma mark - MM Notification Handlers

- (void) syncCompleted:(NSNotification*)note {
    dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
		MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
		
		for (MMSF_Cat_Content_Junction__c *junction in [moc allObjectsOfType: [MMSF_Cat_Content_Junction__c entityName] matchingPredicate: nil]) {
			junction[MNSS(@"Internal_Document__c")] = junction.contentVersion[MNSS(@"Internal_Document__c")];
		}
		
		[moc save];
		[MM_ContextManager saveContentContext];
	});
	
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncCompleted:note];
        });
		return;
	}
    
    [self cleanUpConfigs];
    [completedSyncObjects removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_PostSyncOpsDone object:nil];
    
    /**
     * Don't want to bombard users with notifications. Once they sync after being
     * initially notified of updated content the flag is toggled to NO so that 
     * the banner will show again.
     */
    
    DSA_RemoteObjectStatusClient *client = [[DSA_RemoteObjectStatusClient alloc] init];
    client.notified = NO;
}

- (void) tokenRevoked: (id) sender {
    MMLog(@"%s", __func__);
	[MM_LoginViewController logout];
	
	[[NSNotificationCenter defaultCenter] addFireAndForgetBlockFor: kNotification_DidLogOut object: nil block: ^(NSNotification *note)  {
		[g_appDelegate login];
	}];
}

- (void) prepareThePostSyncOperations{
	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
    NSArray							*mobileAppArray = [MMSF_MobileAppConfig__c allActiveMobileConfigurationsInContext: moc];
    MMLog(@"prepareThePostSyncOperations: logged in: %d active mac cnt: %lu",[MM_LoginViewController isLoggedIn],(unsigned long)mobileAppArray.count);
    if(mobileAppArray.count==0 && [MM_LoginViewController isLoggedIn]){
		if (self.resyncingDueToNoActiveConfigurations) {
			self.resyncingDueToNoActiveConfigurations = NO;
			[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Mobile Configurations", @"Mobile Configurations") message: NSLocalizedString(@"All Mobile Configurations are inactive", @"All Mobile Configurations are inactive")];
		} else {
			self.resyncingDueToNoActiveConfigurations = YES;
			MM_SFObjectDefinition	*def = [MM_SFObjectDefinition objectNamed: [MMSF_MobileAppConfig__c entityName] inContext: nil];
			[def resetLastSyncDate];
			[def save];
			[[MM_SyncManager sharedManager] deltaSyncWithCompletionBlock: nil];
		}
    }
}

- (void) cleanUpConfigs{
    NSManagedObjectContext *moc = [[MM_ContextManager sharedManager] threadContentContext];
    
    NSString* profileId = [[MM_SyncManager currentUserInContext:nil] valueForKey:@"UserProfileId"];
    if(profileId == nil) {
		MMLog(@"%@", @"User not available");
		return;
	}
    
    for(MMSF_Object *record in [MMSF_MobileAppConfig__c allActiveMobileConfigurationsInContext:moc]) {
        NSArray *profiles = [(NSString*)[record valueForKey:MNSS(@"Profiles__c")] componentsSeparatedByString:@";"];
  
        MMVerboseLog(@"Active Profile: %@, all Profiles: %@", profileId ?: @"none", profiles);
        
        if([record valueForKey:MNSS(@"Profiles__c")] == nil )
        {
            MMLog(@"%@", @" App config not available");
            [moc deleteObject:record];
            [moc save];
//            return;
        }
        
        if(![profiles containsObject:profileId])
        {
            //Deleting the records which are not mapped to current user's profile
			MMLog(@"Deleting MAC: %@", record);
            [moc deleteObject:record];
            [moc save];
        }
    }
}

- (void) syncBegan:(NSNotification*)note {
    if(![MM_SyncManager sharedManager].syncInterrupted) {
        [completedSyncObjects removeAllObjects];
    }
    
    if (!self.syncProgressViewController) {
        [self presentSyncProgress];
    }
	
    attachmentCounter = 0;
    contentCounter = 0;
}

- (void) syncResumed:(NSNotification*)note {
    [self syncBegan:note];
}

- (void)loginControllerDidDismiss:(NSNotification*)note {
    BOOL justLoggedIn = [note.object boolValue];
    if (justLoggedIn && [MM_LoginViewController isLoggedIn]) {
        [self presentSyncProgress];
    }
}

- (void) syncBatchReceived:(NSNotification*)note {
	if ([note.object isEqualToString:@"Contact"]) {
        // Getting the Total Contacts count
        NSManagedObjectContext *metaContext = [MM_ContextManager sharedManager].metaContextForWriting;
        MM_SFObjectDefinition *def_con = [metaContext anyObjectOfType: @"SFObjectDefinition" matchingPredicate: [NSPredicate predicateWithFormat:@"name = %@",@"Contact"]];
        NSInteger totalCount_contacts = def_con.serverObjectCountValue;
        
        
		NSUInteger fetchLimit = [[def_con metadataValueForKey:@"fetch-limit"] integerValue];
		
        if([[def_con metadataValueForKey:@"fetch-limit"] length]!=0){
            if(totalCount_contacts > fetchLimit) {
                totalCount_contacts = fetchLimit;
            }
        }
        
        NSManagedObjectContext *moc = [[MM_ContextManager sharedManager] contentContextForWriting];
        NSInteger currentCount_con = [moc numberOfObjectsOfType:@"Contact" matchingPredicate:nil];
        
        if(totalCount_contacts!=0) {
            float progressValue = ((float)( currentCount_con)/(float)(totalCount_contacts));
            NSLog(@"%f",progressValue);
            
            //if(progressValue == 1.0)
                //[self handlePleaseWaitDisplayWithText:[NSString stringWithFormat:@"Successfully Downloaded Contacts(%ld)",(long)totalCount_contacts] andProgressBarValue:1.0];
            //else
                //[self handlePleaseWaitDisplayWithText:[NSString stringWithFormat:@"Downloading Contacts (%ld/%ld)", (long)currentCount_con,(long)totalCount_contacts ]andProgressBarValue:progressValue];
        }
    }
}

// kNotification_MissingLinksConnectionStarting
- (void)missingLinksConnectionStarting:(NSNotification*)note {
    if (self.metaDataRefresh) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_SyncComplete object:nil];
        self.metaDataRefresh = NO;
    }
}

- (void)modelUpdateBegan:(NSNotification*)note {
    if (!self.syncProgressViewController) {
        [self presentSyncProgress];
    }    
}

- (void) objectsImported:(NSNotification*)note {
    NSString *objectName = note.userInfo[@"name"];

     if([objectName isEqualToString:@"Account"] || [objectName isEqualToString:@"Contact"])
        return;
    
    NSString *name;
    if([objectName isEqualToString:MNSS(@"MobileAppConfig__c")])
        name = @"MobileAppConfiguration";
    else if([objectName isEqualToString:MNSS(@"CategoryMobileConfig__c")])
        name= @"CategoryMobileConfiguration";
    else if([objectName isEqualToString:MNSS(@"Category__c")])
        name = @"Categories";
    else
        name = objectName;

    NSManagedObjectContext *metaContext = [MM_ContextManager sharedManager].metaContextForWriting;
    MM_SFObjectDefinition *def = [metaContext anyObjectOfType: @"SFObjectDefinition" matchingPredicate: [NSPredicate predicateWithFormat:@"name = %@",name]];
    NSInteger count = def.serverObjectCountValue;
    
    if (count > 0 && [objectName isEqualToString:@"ContentVersion"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSyncDate = [MM_Config sharedManager].lastSyncDate;
        if (!lastSyncDate) { lastSyncDate = [NSDate distantPast]; }

        // save the previous sync date for Content
        [defaults setValue:lastSyncDate forKey:kUserDefaultKey_previousContentSyncDate];
        [defaults synchronize];
    }

    /* clean the config while downloading contentversion fixes DE255 issue*/
    if([[note.userInfo valueForKey:@"name"] isEqualToString:@"ContentVersion"]){
        [self cleanUpConfigs];
    }
}


- (void) objectSyncCompleted:(NSNotification*)note {
    NSString* objectName = note.object;
    
    if ([objectName isEqualToString:@"User"]) {
        [[MMSF_User currentUser] requestProfileId];
        if(![MM_SyncManager sharedManager].hasSyncedOnce){
            NSString *permission = [MMSF_User currentUser][@"UserPermissionsSFContentUser"];
            if(![permission boolValue]){
                [[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_no_permission];
                [SA_AlertView showAlertWithTitle: @"You do not have the permission to view contents and will be unable to log in." message: nil];
            }
        }
    }
        
    [completedSyncObjects addObject:objectName];
}

- (NSString *)featuredItemsFolderName {
    NSString *outFolderName = @"";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sync_objects" ofType:@"plist"];
    if (path) {
        NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:path];
        NSString *value = plistDict[@"Featured Library Name"];
        if (value && value != (NSString*)[NSNull null]) {
            outFolderName = value;
        }
    }
    
    return outFolderName;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)requestFeaturedContent {
    static NSString *featuredItemQueryFormat = @"SELECT ContentDocument.LatestPublishedVersionId FROM ContentWorkspaceDoc WHERE ContentWorkspace.Name LIKE '%@%%'";
    
    NSString *folderName = [self featuredItemsFolderName];
    if (folderName.length) {
        NSString *query = [NSString stringWithFormat:featuredItemQueryFormat, folderName];
        MM_SOQLQueryString *mmSoqlQuery = [MM_SOQLQueryString queryWithSOQL:query];
        MM_RestOperation *operation = [MM_RestOperation operationWithQuery:mmSoqlQuery groupTag:nil completionBlock:nil sourceTag:nil];
        operation.completionBlock = ^(NSError *error, id jsonResponse, MM_RestOperation *completedOp) {
            if ([jsonResponse[@"totalSize"] integerValue] > 0) {
                NSArray *recordArray = jsonResponse[@"records"];
                NSArray *featuredContentIdArray = [recordArray valueForKeyPath:@"ContentDocument.LatestPublishedVersionId"];
                NSLog(@"Found %d Featured Content items", featuredContentIdArray.count);
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:featuredContentIdArray forKey:kUserDefaultKey_featuredContentItems];
                [defaults synchronize];
            }
            return NO;
        };
        [[MM_SyncManager sharedManager] queueOperation:operation atFrontOfQueue:NO];
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)queueingComplete:(NSNotification*)note
{
    [self requestFeaturedContent];
}

@end
