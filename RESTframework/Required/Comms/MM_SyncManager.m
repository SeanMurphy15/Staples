//
//  MM_SyncManager.m
//
//  Created by Ben Gottlieb on 11/14/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_SyncManager.h"
#import "MM_RestOperation.h"
#import "MM_SFObjectDefinition.h"
#import "MM_ContextManager+Model.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_OrgMetaData.h"
#import "MM_Notifications.h"
#import "MM_Config.h"
#import "MM_Constants.h"
#import "MM_SOQLQueryString.h"
#import "MM_SFChange.h"
#import "MM_LoginViewController.h"
#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"
#import "MM_Log.h"
#import "MMSF_Object.h"
#import <SalesforceNativeSDK/SFRestAPI.h>
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import "MM_ContextManager+Atomic.h"

@interface MM_SyncManager ()
@property (nonatomic, strong) NSMutableSet *completedSyncObjects;
@property (nonatomic, copy) booleanArgumentBlock syncCompletionBlock;
@property (nonatomic, strong) MM_RestOperation *validationOperation;
@property (nonatomic, strong) NSMutableSet *missingObjectNames;
@property (nonatomic, strong) NSMutableArray *objectsToConnect, *failedObjects;
@property (nonatomic, copy) simpleBlock connectionCompleteBlock;
@property (nonatomic, strong) NSString *currentConnectingObject;

- (void) advanceQueue;
- (BOOL) areObjectDefinitionSyncsPending;
- (void) queueSyncCompleteWithCompletionBlock: (booleanArgumentBlock) completionBlock;
- (NSArray *)clearDependenciesForObject:(NSString *)objectName;
@end


NSMutableData* data;
BOOL isrunning = FALSE;

#define kRESTLibraryResumesSyncOnLaunch   1

@implementation MM_SyncManager

@synthesize parseDispatchQueue = _parseDispatchQueue, syncDispatchQueue = _syncDispatchQueue;

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(MM_SyncManager, sharedManager);

+ (void) initialize {
	@autoreleasepool {
		[MM_SyncManager sharedManager];
		[MM_RestOperation setAPIVersion: @"v32.0"];
	}
}
- (void) dealloc {
	[self removeAsObserver];
}

- (id) init {
	if ((self = [super init])) {
		self.syncFailureHandling = syncFailureHandling_autoPerformDelta;
		self.maxSimultaneousConnections = 1;
		[self addAsObserverForName: kNotification_ConnectionStatusChanged selector: @selector(connectionStateChanged:)];
		[self addAsObserverForName: UIApplicationWillResignActiveNotification selector: @selector(resignedActiveState:)];
#if kRESTLibraryResumesSyncOnLaunch
		[self addAsObserverForName: UIApplicationDidFinishLaunchingNotification selector: @selector(applicationDidFinishLaunching:)];
#endif
		[self addAsObserverForName: UIApplicationDidEnterBackgroundNotification selector: @selector(didEnterBackground:)];
		[self addAsObserverForName: UIApplicationWillEnterForegroundNotification selector: @selector(willEnterForeground:)];
		self.maxAttachmentSize = 5 * 1024 * 1024;		//5 meg max attachment size
	}
	return self;
}

- (dispatch_queue_t) parseDispatchQueue {
	if (_parseDispatchQueue == nil) {
		_parseDispatchQueue = dispatch_queue_create("parseDispatchQueue", DISPATCH_QUEUE_SERIAL);
	}
	return _parseDispatchQueue;
}

- (dispatch_queue_t) syncDispatchQueue {
	if (_syncDispatchQueue == nil) {
		_syncDispatchQueue = dispatch_queue_create("syncDispatchQueue", DISPATCH_QUEUE_SERIAL);
	}
	return _syncDispatchQueue;
}

- (BOOL)shouldSyncResume {
    BOOL shouldResume = NO;
    
	if ([MM_SyncStatus status].isSyncInProgress && self.syncFailureHandling == syncFailureHandling_autoPerformDelta && !self.isSyncInProgress && ![MM_LoginViewController isEnteringCredentials]) {
        shouldResume = YES;
        MMLog(@"Sync will resume, MM_SyncStatus isSyncInProgress = %hhd", [MM_SyncStatus status].isSyncInProgress);
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncWillResume object: nil];
    }
    
    return shouldResume;
}

- (BOOL) isSyncInProgress {
	if (_isSyncInProgress) {
		return self.active.count > 0 || self.pending.count > 0 || self.cleanup.count > 0;
	}
	return NO;
}

//================================================================================================================
#pragma mark - Legacy Sync

- (void) syncDefaultObjectSet { [self performDeltaSyncWithCompletion: nil]; }
- (BOOL) synchronize: (NSArray *) objects withCompletionBlock: (booleanArgumentBlock) completionBlock { [self _performSyncWithCompletion: completionBlock]; return YES; }
- (BOOL) performSynchronize: (NSArray *) objects withCompletionBlock: (booleanArgumentBlock) completionBlock { [self performDeltaSyncWithCompletion: completionBlock]; return YES; }
- (BOOL) deltaSyncWithCompletionBlock: (booleanArgumentBlock) completionBlock { [self performDeltaSyncWithCompletion: completionBlock]; return YES; }
- (BOOL) fullResync: (NSArray *) objects withCompletionBlock: (booleanArgumentBlock) completionBlock { [self performFullSyncWithCompletion: completionBlock]; return YES; }


//================================================================================================================
#pragma mark - Synchronization Methods

- (void) performFullSyncWithCompletion: (booleanArgumentBlock) completion {
	if (self.hasSyncedOnce) {
		self.currentSyncType = syncType_fullResync;
		self.hasSyncedOnce = NO;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_FullResyncWillBegin object: nil];
		[MM_SFChange pushPendingChangesWithCompletionBlock: ^(BOOL completed) {
			if (completed) {
				if (self.syncCancelled) return;
				[[MM_ContextManager sharedManager] mainContentContext];
				
				dispatch_after_main_queue(0.25, ^{
					[[MM_ContextManager sharedManager] clearAllDataWithCompletion:^(NSError *error) {
						[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_FullResyncWillBegin object: nil];
						[self _performSyncWithCompletion: completion];
					}];
				});
			} else {
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncCancelled object: nil];
			}
		}];
	} else {
		self.currentSyncType = syncType_initial;
		[self _performSyncWithCompletion: completion];
	}
}

- (void) performDeltaSyncWithCompletion: (booleanArgumentBlock) completion {
	if (!self.hasSyncedOnce) {
		[self performFullSyncWithCompletion: completion];
	} else {
		self.currentSyncType = syncType_delta;
		[self _performSyncWithCompletion: completion];
	}
}

- (void) _performSyncWithCompletion: (booleanArgumentBlock) completion {		//private method called by above
	if ([SA_ConnectionQueue sharedQueue].offline || ![[SFNetworkEngine sharedInstance] isReachable]) return;			//can't sync while offline
	[MMSF_Object clearSFIDCache];

	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncWillBegin object: nil];
	
	if (!self.oauthValidated) {
		[self validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) { [self _performSyncWithCompletion: completion]; }];
		return;
	}
	
	self.syncCancelled = NO;
	self.isSyncInProgress = YES;

	if (![[MM_OrgMetaData sharedMetaData] isMetadataAvailableForObjects: nil]) {
		[[MM_SyncManager sharedManager] downloadObjectDefinitionsWithCompletionBlock: ^{ [self _performSyncWithCompletion: completion]; }];
		return;
	}
	
	MMLog(@"synchronize:withCompletionBlock: %@", @"");

	if (self.syncCancelled) return;
	self.autorefreshDisabled = YES;
	self.syncCompletionBlock = completion;
	self.lastSyncedObjectNames = [self.objectsToSync valueForKey: @"name"];

	[MM_SFChange pushPendingChangesWithCompletionBlock: ^(BOOL completed) {
		if (self.useAtomicSync && self.hasSyncedOnce) {
			[[MM_ContextManager sharedManager] copyExistingDataOffWithCompletion: ^(NSError *error) {
				if (error) {
					[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Your Sync Has Failed", nil) message: NSLocalizedString(@"Please restart your iPad and try again.", nil)];
					[self cancelSync: mm_sync_cancel_reason_low_memory];
				} else
					[self beginSynchronization];
			}];
		} else {
			dispatch_async_main_queue(^{ [self beginSynchronization]; });
		}
	}];
}

- (BOOL) resyncAllDataIncludingMetadata: (BOOL) resyncMetadata withCompletionBlock: (booleanArgumentBlock) completionBlock {
	if ([SA_ConnectionQueue sharedQueue].offline) return NO;
	
	if (!self.oauthValidated) {
		[self validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) { [self resyncAllDataIncludingMetadata: resyncMetadata withCompletionBlock: completionBlock]; }];
		return NO;
	}
	
    if (self.isSyncInProgress) return NO;
    
	self.currentSyncType = syncType_fullResync;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_FullResyncWillBegin object: nil];
	self.hasSyncedOnce = NO;
	
	for (MM_SFObjectDefinition *def in self.objectsToSync.copy) {
		[def resetLastSyncDate];
	}
	
	MMLog(@"Resyncing ALL data %@", @"");
	[[NSNotificationCenter defaultCenter] addFireAndForgetBlockFor: kNotification_DidRemoveAllData object: nil block: ^(NSNotification *note) {
		[[MM_SyncManager sharedManager] fetchRequiredMetaData: resyncMetadata withCompletionBlock: ^{
			[NSUserDefaults syncObject: [NSDate date] forKey: LAST_METADATA_SYNCDATE];
			dispatch_async(dispatch_get_main_queue(), ^{ [self fullResync: nil withCompletionBlock: completionBlock]; });
		}];
	}];
	
	[[MM_ContextManager sharedManager] pushAllPendingChangesAndRemoveAllData];
	return YES;
}


//================================================================================================================
#pragma mark - Metadata

- (BOOL) downloadObjectDefinitionsWithCompletionBlock: (simpleBlock) block {
	if ([SA_ConnectionQueue sharedQueue].offline) return NO;
	
	if (!self.oauthValidated) {
		[self validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) { [self downloadObjectDefinitionsWithCompletionBlock: block]; }];
		return NO;
	}
	
	
	SFRestRequest				*request = [[SFRestAPI sharedInstance] requestForDescribeGlobal];
	
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
	[self queueOperation: [MM_RestOperation operationWithRequest: request completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		if (error) {
			MMLog(@"Failed %@", @"");
		}
		[MM_SFObjectDefinition importGlobalObjectList: [json objectForKey: @"sobjects"] withCompletion: ^(BOOL success) {
			MMLog(@"- Object Download: Complete %@", @"");
			dispatch_async(dispatch_get_main_queue(),  ^{ [[MM_SyncManager sharedManager] fetchRequiredMetaData: NO withCompletionBlock: block]; });
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ObjectDefinitionsImported object: nil];
			[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
		}];
		return NO;
	} sourceTag: CURRENT_FILE_TAG]];
	return YES;
}

- (BOOL) fetchRequiredMetaData: (BOOL) refetch withCompletionBlock: (simpleBlock) completionBlock {
	if ([MM_ContextManager sharedManager].deletingAllData) return NO;
	
	if (!self.oauthValidated) {
		[self validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) { [self fetchRequiredMetaData: refetch withCompletionBlock: completionBlock]; }];
		return NO;
	}
	
	if ([SA_ConnectionQueue sharedQueue].offline) return NO;
	
	NSMutableArray				*syncThese = [NSMutableArray array];
	
	self.isModelUpdateInProgress = YES;
	self.isSyncInProgress = YES;
	
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ModelUpdateBegan object: nil];
	for (MM_SFObjectDefinition *object in self.objectsToSync.copy) {
		MM_RestOperation	*op = [object fetchMetaData: refetch];
		if (op) {
			[self queueOperation: op];
			[syncThese addObject: object];
		}
	}
	
	BOOL updatingMetadata = syncThese.count;
	if (updatingMetadata) {
		MMLog(@"Fetching metadata for %d objects", syncThese.count);
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:kNotification_MetaDataFetchStarted object: nil];
	} else {
		self.isModelUpdateInProgress = NO;
	}
	MM_RestOperation		*finale = [MM_RestOperation operationWithRequest: nil completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (updatingMetadata) {
				MMLog(@"- Metadata Import: Complete %@", @"");
				[[MM_ContextManager sharedManager] updateContentModel];
				[[MM_ContextManager sharedManager] saveMetaContext];
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_MetaDataDownloadsComplete object: nil];
				self.isModelUpdateInProgress = NO;
			}
			self.isSyncInProgress = NO;
            
			if (completionBlock) {
				completionBlock();
            }
			else {
				[[MM_SyncManager sharedManager] synchronize: nil withCompletionBlock: ^(BOOL completed) {
				}];
			}
			
			[MM_SyncManager sharedManager].isModelUpdateInProgress = NO;
			[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ModelUpdateComplete object: nil];
			
			[completedOp dequeue];
		});
		return YES;
	} sourceTag: CURRENT_FILE_TAG];
	finale.iWorkAlone = YES;
	finale.isCleanupOperation = YES;
	[self queueOperation: finale];
	return YES;
}

#pragma mark - Validation

- (void) validateLogoutWithCallback: (booleanArgumentBlock) completion {
	if (self.oauthValidating || [SA_ConnectionQueue sharedQueue].offline || ([[MM_SyncManager sharedManager] hasSyncedOnce] && ![[SFNetworkEngine sharedInstance] isReachable])) return;		//already waiting for something
	
	MMLog(@"Sniffing for valid OAuth before logging out… %@", @"");
	self.oauthValidating = YES;
	
	SFRestRequest				*request = [[SFRestAPI sharedInstance] requestForRetrieveWithObjectType: @"User" objectId: [SFOAuthCoordinator fullUserId] fieldList: @"Id"];
	__weak MM_RestOperation		*restOp = [MM_RestOperation operationWithRequest: request completionBlock: nil sourceTag: CURRENT_FILE_TAG];
	
	restOp.completionBlock = ^(NSError *error, id jsonResponse, MM_RestOperation *completedOp) {
		if (self.validationOperation != restOp) return NO;
		self.validationOperation = nil;
		self.oauthValidated = YES;
		self.oauthValidating = NO;
		completion(error == nil);
		return NO;
	};
	
	self.validationOperation = restOp;
	self.validationOperation.isSniffingRequest = YES;
	[self.validationOperation start];
}

- (void) validateOAuthTagged: (NSString *) tag withCompletionBlock: (booleanArgumentBlock) block {
	if ([SA_ConnectionQueue sharedQueue].offline || ([[MM_SyncManager sharedManager] hasSyncedOnce] && ![[SFNetworkEngine sharedInstance] isReachable])) {
		if (block) block(NO);
		return;
	}
	
	if (block && tag) {
		if (self.validationCompletionBlocks == nil) self.validationCompletionBlocks = [SA_ThreadsafeMutableDictionary new];
		
		self.validationCompletionBlocks[tag] = block;
	}
	
	if (self.oauthValidating) {
		MMLog(@"Already validating, adding %@ to validationCompletionBlocks, moving on.", tag);
		return;
	}
	
	MMLog(@"Sniffing for valid OAuth… %@", @"");
	self.oauthValidating = YES;
	self.oauthValidationTimer = [NSTimer scheduledTimerWithTimeInterval: 60.0 target: self selector: @selector(oauthValidationTimedOut:) userInfo: nil repeats: NO];
	
	SFRestRequest				*request = [[SFRestAPI sharedInstance] requestForRetrieveWithObjectType: @"User" objectId: [SFOAuthCoordinator fullUserId] fieldList: @"Id"];
    NSLog(@"%@",[SFOAuthCoordinator fullUserId]);
	__weak MM_RestOperation		*restOp = [MM_RestOperation operationWithRequest: request completionBlock: nil sourceTag: CURRENT_FILE_TAG];
	
	
	
	restOp.completionBlock = ^(NSError *error, id jsonResponse, MM_RestOperation *completedOp) {
		[self.oauthValidationTimer invalidate];
		NSLog(@"%@",jsonResponse);
        NSLog(@"%@",error.localizedDescription);
		self.validationOperation = nil;
		if (error == nil) {
			MMLog(@"Got a valid OAuth connection %@", @"");
			self.oauthValidated = YES;
			self.oauthValidating = NO;
			
			[self fireOAuthCompletionBlocks: YES];
		} else {
			MMLog(@"No valid OAuth connection, re-authenticating. %@", @"");
			
			self.oauthValidating = NO;
			
			if (![[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_HAS_LOGGED_IN_AT_LEAST_ONCE]
				|| [error.domain isEqualToString:@"com.salesforce.OAuth.ErrorDomain"]) {
				[MM_LoginViewController logout];
			}
		}
		return NO;
	};
	
	self.validationOperation = restOp;
	self.validationOperation.isSniffingRequest = YES;
	
    dispatch_async(dispatch_get_main_queue(), ^{ [self.validationOperation start]; });
}

- (void) oauthValidationTimedOut: (NSTimer *) timer {
	if (timer) MMLog(@"Validation timed out", @"");
	self.oauthValidationTimer = nil;
	[self fireOAuthCompletionBlocks: YES];
	[self cancelSync: mm_sync_cancel_reason_auth_failed];
	if (![SA_ConnectionQueue sharedQueue].offline) [MM_LoginViewController logout];
}

- (void) fireOAuthCompletionBlocks: (BOOL) validated {
	SA_ThreadsafeMutableDictionary				*dict = self.validationCompletionBlocks;
	
	self.validationCompletionBlocks = nil;
	
	[dict safelyAccessInBlock:^(NSMutableDictionary *dictionary) {
		NSArray			*blocks = dictionary.allValues;
		
		self.validationCompletionBlocks = nil;
		
		for (booleanArgumentBlock b in blocks) b(validated);
	}];
}

#pragma mark - Syncing

- (void) connectMissingLinksInObjects: (NSArray *) objectsToConnect withCompletion: (simpleBlock) block {
//	NSUInteger					completed = 0, total = 0;

	self.connectionCompleteBlock = block;
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
	self.objectsToConnect = [objectsToConnect mutableCopy];
	dispatch_async(self.parseDispatchQueue, ^{ [self connectMissingLinks]; });

//	for (MM_SFObjectDefinition *object in self.objectsToConnect) {
//		if (object.requiresPostSyncLink) total += [object numberOfMissingLinkRecordsInContext: ctx];
//	}
//	MMLog(@"%d records to link.", total);

}

- (void) connectMissingLinks {
    // If the sync was interrupted, probably don't want to go down this path
    if(self.syncInterrupted || self.syncCancelled) {
        NSLog(@"Bailing out of connectMissingLinks");
        return;
    }

	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:kNotification_MissingLinksConnectionStarting object: nil];
    
	if (self.objectsToConnect.count == 0) {
		[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
	
		self.fullRelinkRequired = NO;
		self.objectTypesToReLink = nil;

		if (self.connectionCompleteBlock) self.connectionCompleteBlock();
		self.connectionCompleteBlock = nil;
		[MMSF_Object logSFIDCache];
		[MMSF_Object clearSFIDCache];

		return;
	}
	
	if (self.objectTypesToReLink == nil) {
		self.objectTypesToReLink = [NSMutableSet new];
	}
	
	NSManagedObjectContext		*ctx = [[MM_ContextManager sharedManager] threadContentContext];
	MM_SFObjectDefinition		*def = self.objectsToConnect[0];
	NSUInteger					found = 0;
	
	if (def.requiresPostSyncLink && ctx) {
		if ([self.objectTypesToReLink containsObject: def.name]) {
			[self.objectTypesToReLink removeObject: def.name];
			[def incrementLinkRequiredTagInContext: ctx];
		}
		found = [def countAndConnectAllMissingLinksInContext: ctx showingProgress: NO];
	}
	
	[ctx save];
	[ctx reset];
	
	if ([NSThread isMainThread])
		[[MM_ContextManager sharedManager] saveAndClearContentContext];
	else
		dispatch_sync(dispatch_get_main_queue(), ^{ [[MM_ContextManager sharedManager] saveAndClearContentContext]; });

	if (found == 0) [self.objectsToConnect removeObjectAtIndex: 0];
	dispatch_async(self.parseDispatchQueue, ^{ [self connectMissingLinks]; });
}

- (void) clearAllObjectsOfType: (NSString *) type {
	self.fullRelinkRequired = YES;
	NSManagedObjectContext			*moc = [[MM_ContextManager sharedManager] threadContentContext];
	NSEntityDescription				*entity = [NSEntityDescription entityForName: type inManagedObjectContext: moc];
	
	if (self.objectTypesToReLink == nil) self.objectTypesToReLink = [NSMutableSet new];
	
	for (NSRelationshipDescription *rel in entity.relationshipsByName.allValues) {
		[self.objectTypesToReLink addObject: rel.destinationEntity.name];
	}
	
	MMLog(@"Clearing out %d partially synced %@ objects, will also relink %@.", [moc numberOfObjectsOfType: type matchingPredicate: nil], type, self.objectTypesToReLink);
	
	self.fullRelinkRequired = YES;
	
	[moc deleteObjectsOfType: type matchingPredicate: nil withFetchLimit: 1000];		//clear out any previous partial syncs
	[moc save];
	[[MM_ContextManager sharedManager] saveContentContext];
}

- (void) pauseSynchronization: (BOOL) cancelPending {
	MMLog(@"Sync Paused %@", @"");
	self.oauthValidating = NO;
	self.oauthValidated = NO;
	self.syncInterrupted = YES;
	self.isSyncInProgress = NO;
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncPaused object: nil];

	[self stopQueue];
	for (MM_RestOperation *op in self.active.copy ) {
		[op pause];
		if (!cancelPending) {
			MMLog(@"Pausing %@, will restart after wifi regained", op);
			[self.pending insertObject: op atIndex: 0];
			
		}
	}
	self.active = [NSMutableArray array];
	if (cancelPending) {
		self.pending = [NSMutableArray array];
		[self finishSynchronization: NO];
	}
	
	[MM_SFObjectDefinition clearCachedObjectDefinitions];
}

- (void) beginSynchronization {
    if ([SA_ConnectionQueue sharedQueue].offline) return;
    
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_LAST_CANCEL_REASON];
	[[NSUserDefaults standardUserDefaults] synchronize];

	self.failedObjects = nil;
	[MM_SFObjectDefinition clearCachedObjectDefinitions];
	self.syncCancelled = NO;
	s_parseCount = 0;
	self.lastDependencyLock = nil;
	self.cycleOfDependencyAlertShown = NO;
	self.isSyncInProgress = YES;
	MMLog(@"--- Sync Starting -------------------------------------------------- %@", @"");
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncBegan object: @(self.currentSyncType)];

	self.cleanup= [NSMutableArray array];
	self.pending = [NSMutableArray array];
	self.completedSyncObjects = self.missingObjectNames ? self.missingObjectNames.mutableCopy : [NSMutableSet set];
	
	[self completeSyncSpinUp];
}

- (void) completeSyncSpinUp {
	NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].threadMetaContext;
	NSMutableArray						*syncedObjectNames = NSMutableArray.array;
	
	for (NSString *objectName in self.lastSyncedObjectNames.copy) {
		MM_SFObjectDefinition		*def = [MM_SFObjectDefinition objectNamed: objectName inContext: moc];
//		MM_SFObjectDefinition		*def = [object objectInContext: moc];
		if (!def.shouldSyncServerData || [self.completedSyncObjects containsObject: def.name]) continue;	//sync_objects.plist key
		
		[syncedObjectNames addObject: def.name];
		[def preflightSync];
		[MM_RestOperation queueSyncOperationsForObjectDefintion: def];
	}
	[[MM_SyncStatus status] beginSyncWithObjectNames: syncedObjectNames];
	MMLog(@"--- Queueing Complete -------------------------------------------------- %@", @"");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_QueueingComplete object:nil];
	self.isSyncInProgress = YES;
	if (self.syncInterrupted) self.currentSyncType = syncType_continuation;
	self.syncInterrupted = NO;
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	[self queueSyncCompleteWithCompletionBlock: ^(BOOL complete) {
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		[[MM_ContextManager sharedManager] clearBackedUpDataWithCompletion:^(NSError *error) {
			[self finishSynchronization: complete];
		}];
	}];
	[moc save];
}

- (void) resumeSynchronization {
	MMLog(@"--- Sync Resuming -------------------------------------------------- %@", @"");
	if (!self.oauthValidated) {
		[self validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) { [self resumeSynchronization]; }];
		return;
	}
	
	if (self.isModelUpdateInProgress && (self.active.count || self.pending.count || self.cleanup.count)) {
		[self fetchRequiredMetaData: NO withCompletionBlock: nil];
		return;
	}

	self.isSyncInProgress = YES;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncResumed object: nil];
	
	self.lastDependencyLock = nil;
	self.pending = [NSMutableArray array];
	self.active = [NSMutableArray array];
	self.cleanup = [NSMutableArray array];
	
	for (NSString *objectName in @[ @"ContentVersion", @"Attachment"]) {
		if ([self.completedSyncObjects containsObject: objectName]) [[MM_SFObjectDefinition objectNamed: objectName inContext: nil] refreshAllDataBlobs: YES];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self performSelector: @selector(completeSyncSpinUp) withObject: nil afterDelay: 0.1];
	});
}

- (void) finishSynchronization: (BOOL) complete {
	self.oauthValidated = NO;
	if (self.syncCompletionBlock) {
		self.syncCompletionBlock(complete);
		self.syncCompletionBlock = nil;
	}
	
	[[MM_SyncStatus status] markSyncComplete];
	self.syncInterrupted = NO;
	self.lastSyncedObjectNames = nil;
	self.isSyncInProgress = NO;
	[MM_SFObjectDefinition clearCachedObjectDefinitions];
}

- (void) queueCountCompleteWithCompletionBlock {
	MM_RestOperation		*intermission = [MM_RestOperation operationWithRequest: nil completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncCountsReceived object: nil];
		return NO;
	} sourceTag: CURRENT_FILE_TAG];
	
	intermission.iWorkAlone = YES;
	[self queueOperation: intermission];
}

- (void) queueSyncCompleteWithCompletionBlock: (booleanArgumentBlock) completionBlock {
	MM_RestOperation		*finale = [MM_RestOperation operationWithRequest: nil completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([[MM_SyncManager sharedManager] areObjectDefinitionSyncsPending]) {
				[[MM_SyncManager sharedManager] performSelector: @selector(queueSyncCompleteWithCompletionBlock:) withObject: completionBlock afterDelay: 0.1];
				[completedOp dequeue];
				return;
			}
			//MMLog(@"- Synchronization: Complete, Mem: %dk", (NSInteger) [UIDevice availableMemory] / 1024);
			[[MM_SyncManager sharedManager] connectMissingLinksInObjects: self.objectsToSync withCompletion: ^{
				[[MM_ContextManager sharedManager] saveMetaContext];
				[[MM_ContextManager sharedManager] saveContentContext];
				
				self.hasSyncedOnce = YES;
				
				[MM_Config sharedManager].lastSyncDate = [NSDate date];
				if (completionBlock) completionBlock(YES);
				[MM_SyncManager sharedManager].isSyncInProgress = NO;
				[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
				[SA_ConnectionQueue sharedQueue].activityIndicatorCount = 0;
				MMLog(@"Sync finished at: %@", [MM_Config sharedManager].lastSyncDate);
				self.autorefreshDisabled = NO;
				
				[MM_SFObjectDefinition removeDeletedRecords:^{
					[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncComplete object: nil];
				}];
				[completedOp dequeue];
			}];
		});
		return YES;
	} sourceTag: CURRENT_FILE_TAG];
	
	finale.isCleanupOperation = YES;
	finale.iWorkAlone = YES;
	[self queueOperation: finale];
}

- (void) queuePendingDefinitionSync: (MM_SFObjectDefinition *) objectDef {
	if (self.pendingObjectNames == nil) self.pendingObjectNames = [NSMutableArray array];
	if (![self.pendingObjectNames.copy containsObject: objectDef.name]) [self.pendingObjectNames addObject: objectDef.name];
	
	if (self.remainingObjectDependencies == nil) self.remainingObjectDependencies = [NSMutableDictionary dictionary];
	
	NSArray			*dependencyNames = [objectDef.syncDependencies componentsSeparatedByString: @","];
	if (![objectDef.name isEqual: @"User"]) dependencyNames = [dependencyNames ?: @[] arrayByAddingObject: @"User"];
	
	if (dependencyNames.count) {
		NSMutableArray	*dependencies = [NSMutableArray array];
	
		for (NSString *name in dependencyNames) {
			BOOL					checkDependenciesEachSync = [name hasPrefix: @"*"];
			NSString				*trimmedName = checkDependenciesEachSync ? [name substringFromIndex: 1] : name;
			
			if ([self.completedSyncObjects containsObject: trimmedName]) continue;
			
			MM_SFObjectDefinition	*def = [MM_SFObjectDefinition objectNamed: trimmedName inContext: objectDef.moc];
			if (!checkDependenciesEachSync && def.lastSyncedAt_mm) continue;
			
			[dependencies addObject: trimmedName];
		}
		
		self.remainingObjectDependencies[objectDef.name] = dependencies;
	}

	MMLog(@"Queuing sync for %@, remaining dependencies: %@", objectDef.name, [self.remainingObjectDependencies[objectDef.name] componentsJoinedByString: @", "]);
	if ([self areDependenciesMetForObject: objectDef.name])
    {
        [objectDef queueSyncOperationsForQuery: nil retrying: NO];
    }

}

- (BOOL) areObjectDefinitionSyncsPending {
	if (!_isSyncInProgress || self.pendingObjectNames.count == 0) return NO;
	
	NSUInteger				pendingCount = self.pending.count;
    
    [self clearDependenciesForObject:nil];
	
	for (NSString *name in self.pendingObjectNames.copy) {
		MM_SFObjectDefinition		*def = [MM_SFObjectDefinition objectNamed: name inContext: nil];
		
		if ([self.remainingObjectDependencies[def.name] count] == 0 && ![self.failedObjects containsObject: def.name]) {
			[self.pendingObjectNames removeObject: name];
			[MM_RestOperation queueSyncOperationsForObjectDefintion: def];
			return YES;
		}
	}
	
	if (self.pending.count && self.pending.count == pendingCount && !self.cycleOfDependencyAlertShown) {
		NSMutableString				*message = [NSMutableString stringWithString: @"There are unresolved dependencies for: "];
		
		for (NSString *objectName in self.remainingObjectDependencies) {
			NSArray						*dep = self.remainingObjectDependencies[objectName];
			
			[message appendFormat: @"\n%@ (%@)", objectName, [dep componentsJoinedByString: @", "]];
		}
		
		[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Please Check Your Sync Objects", nil) message: message
								 buttons: @[@"Continue", @"Stop Sync"] buttonBlock: ^(NSInteger index) {
									 if (index == 1) [self cancelSync: mm_sync_cancel_reason_dependenciesFailed];
									 self.cycleOfDependencyAlertShown = NO;
								 }];
		
		self.cycleOfDependencyAlertShown = YES;
	}
	
	return self.pendingObjectNames.count > 0;
}

- (BOOL) areOperationsPendingForObjectType: (NSString *) objectName {
	for (MM_RestOperation *op in [self.pending arrayByAddingObjectsFromArray: self.active]) {
		if (![op.query.objectName isEqual: objectName]) continue;
		if (op.isRunning || !op.completed) return YES;
	}
	return NO;
}


//================================================================================================================
#pragma mark - Error handling

- (void) receivedError: (NSError *) error forQuery: (MM_SOQLQueryString *) query {
	if ([error.userInfo[@"NSLocalizedFailureReason"] isEqual: @"INVALID_QUERY_LOCATOR"] && query.objectName) {
		NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].threadMetaContext;
		MM_SFObjectDefinition				*def = [MM_SFObjectDefinition objectNamed: query.objectName inContext: moc];
		
		def.moreResultsURL_mm = nil;
		[def save];
		[[MM_ContextManager sharedManager] saveMetaContext];
		return;
	}
	if (self.failedObjects == nil) self.failedObjects = [NSMutableArray array];
	
	[self.failedObjects addObject: query.objectName];
	
	[SA_AlertView showAlertWithTitle:$S(NSLocalizedString(@"Error Synchronizing %@", nil), query.objectName) message:error.localizedDescription];
}



//=============================================================================================================================
#pragma mark - Queue management

- (void) queueOperation: (MM_RestOperation *) op { [self queueOperation: op atFrontOfQueue: NO]; }
- (void) queueOperation: (MM_RestOperation *) op atFrontOfQueue: (BOOL) atFrontOfQueue {
	if (op == nil) return;
	
	dispatch_async(self.parseDispatchQueue, ^{
		if (op.isCleanupOperation) {
			if (self.cleanup == nil) self.cleanup = [[NSMutableArray alloc] init];
			[self.cleanup addObject: op];
		} else {
			if (self.pending == nil) self.pending = [[NSMutableArray alloc] init];
			
			[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
			if (atFrontOfQueue) 
				[self.pending insertObject: op atIndex: 0];
			else
				[self.pending addObject: op];
		}
		
		self.queueStopped = NO;
		if (self.active.count == 0) [NSObject performBlock: ^{ dispatch_async(self.parseDispatchQueue, ^{ [self advanceQueue]; }); } afterDelay: 0.1];
	});
}

- (BOOL) areOperationsInFlight {
	return self.pending.count > 0 || self.active.count > 0;
}

- (void) stopQueue {
	self.queueStopped = YES;
}

- (BOOL) cancelSync: (mm_sync_cancel_reason) reason {
	BOOL				syncing = self.isSyncInProgress;
	
	if (syncing) [self pauseSynchronization: YES];
	[self stopQueue];
	
	mm_sync_cancel_reason		originalReason = [[NSUserDefaults standardUserDefaults] integerForKey: DEFAULTS_LAST_CANCEL_REASON];
	
	if (originalReason) reason = originalReason;
	
	NSString			*reasonDescription = [MM_SyncManager descriptionForCancelReason: reason];
	
	MMLog(@"Sync Cancelled: %@", reasonDescription);
	
	[NSUserDefaults syncObject: @(reason) forKey: DEFAULTS_LAST_CANCEL_REASON];

	self.active = [NSMutableArray array];
	self.cleanup= [NSMutableArray array];
	self.pending = [NSMutableArray array];
	self.isSyncInProgress = NO;
	self.syncInterrupted = NO;
	self.syncCancelled = YES;
	
	self.syncCompletionBlock = nil;
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount = 0;
	if (reason != mm_sync_cancel_reason_programatic) [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SyncCancelled object: @(reason)];
	
	if (syncing && self.useAtomicSync && [MM_ContextManager sharedManager].isBackedUpDataAvailable) {
		[[MM_ContextManager sharedManager] restoreBackedUpDataWithCompletion:^(NSError *error) {
			self.syncInterrupted = NO;
		}];
	}
	
	if (reasonDescription.length && syncing) [SA_AlertView showAlertWithTitle: NSLocalizedString(@"Synchronization Cancelled", nil) message: reasonDescription];

	return YES;
}

+ (NSString *) descriptionForCancelReason: (mm_sync_cancel_reason) reason {
	switch (reason) {
		case mm_sync_cancel_reason_none: return nil;
		case mm_sync_cancel_reason_programatic: return nil;
		case mm_sync_cancel_reason_auth_failed: return NSLocalizedString(@"Your sync was cancelled because of an authentication error.", nil);
		case mm_sync_cancel_reason_offline: return NSLocalizedString(@"Your sync was cancelled because the connection was lost.", nil);
		case mm_sync_cancel_reason_left_app: return NSLocalizedString(@"Your sync was cancelled because you left the app or locked the screen.", nil);
		case mm_sync_cancel_reason_crashed: return NSLocalizedString(@"Your sync was cancelled because the application crashed.", nil);
		case mm_sync_cancel_reason_low_memory: return NSLocalizedString(@"Your sync was cancelled because there's not enough memory available, or some other error occurred.", nil);
		case mm_sync_cancel_reason_user: return nil;
		case mm_sync_cancel_reason_no_permission: return NSLocalizedString(@"Missing proper permissions", nil);
		case mm_sync_cancel_reason_api_disabled: return NSLocalizedString(@"The REST API is disabled", nil);
		case mm_sync_cancel_reason_auth_server_error: return NSLocalizedString(@"The server returned an error", nil);
		case mm_sync_cancel_reason_inaccessible_object: return NSLocalizedString(@"Tried to access an object without proper permissions", nil);
		case mm_sync_cancel_reason_dependenciesFailed: return NSLocalizedString(@"Object dependencies were not met", nil);
		default: return nil;
	}
}


- (void) dequeueOperation: (MM_RestOperation *) op completed: (BOOL) completed {
//	[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
	if (op.query) self.lastDependencyLock = nil;
	dispatch_async(self.parseDispatchQueue, ^{
		if (![self.active containsObject: op]) return;
		
		[self.active removeObject: op];
		if (completed) [NSObject performBlock: ^{ dispatch_async(self.parseDispatchQueue, ^{ [self advanceQueue]; }); } afterDelay: 0.1];
		[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
	});
}

static MM_SyncManager			*s_mgr = nil;

- (void) advanceQueue {
	s_mgr = self;
	dispatch_async(self.parseDispatchQueue, ^{
		if (self.queueStopped) return;

		NSArray				*activeTags = [self.active.copy valueForKey: @"groupTag"];
		for (MM_RestOperation *op in self.active.copy) {
			if (!op.isRunning && !op.completed) {ENSURE_MAIN_THREAD({
				[op start];
			});}

		}

		NSArray					*allPending = [MM_SyncManager isParsing] ? self.pending.copy : [self.pending ?: @[] arrayByAddingObjectsFromArray: self.cleanup];
		
		for (MM_RestOperation *op in allPending) {
			if (self.active.count >= self.maxSimultaneousConnections || allPending.count == 0) break;
			if (op.iWorkAlone && self.active.count) break;					//make sure loners are left... alone
			if (self.active.count == 1 && [self.active.SA_firstObject iWorkAlone]) continue;
			
			if (op.isCleanupOperation) {
				if ([MM_SyncManager isParsing]) break;
			}
			
			if ([self.cleanup containsObject: op]) {
                MMLog(@"Cleaning up: Pending: %d, Active: %d, Pending Objects: %d", self.pending.count, self.active.count, self.pendingObjectNames.count);
			}
			
			if (op.groupTag && [activeTags containsObject: op.groupTag]) continue;
			if (self.active == nil) self.active = [[NSMutableArray alloc] init];
			[self.active addObject: op];
			[self.pending removeObject: op];
			[self.cleanup removeObject: op];
			dispatch_async_main_queue(^{
				[op start];
			});
		}
	});
}

- (NSArray *) objectsToSync {
	NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadMetaContext;
	NSMutableArray				*objectsToSync = [NSMutableArray arrayWithCapacity: [[MM_OrgMetaData sharedMetaData] objectsToSync].count];
	NSMutableArray				*inaccessibleObjects = [NSMutableArray array];
	
    self.missingObjectNames = nil;
	for (NSDictionary *objectInfo in [[MM_OrgMetaData sharedMetaData] objectsToSync]) {
		NSString						*name = [objectInfo objectForKey: @"name"];
		
		#if ALLOW_OBJECT_REMAPPING
			if (objectInfo[@"server-name"]) name = objectInfo[@"server-name"];
		#endif
		
		MM_SFObjectDefinition			*object = [MM_SFObjectDefinition objectWithServerName: name inContext: moc];
		
		if (object) {
			NSDictionary			*existingSyncInfo = (id) object.syncInfo_mm;
			
			if (![existingSyncInfo isEqualToDictionary: objectInfo]) {
				object.syncInfo_mm = objectInfo;
				#if ALLOW_OBJECT_REMAPPING
					if (objectInfo[@"server-name"]) object.serverObjectName_mm = objectInfo[@"server-name"];
					object.name = objectInfo[@"name"];
				#endif
				[object save];
			}
			[objectsToSync addObject: object];
		} else if (![self.missingObjectNames containsObject: objectInfo[@"name"]]) {
			if (self.missingObjectNames == nil) self.missingObjectNames = [NSMutableSet set];
			[self.missingObjectNames addObject: objectInfo[@"name"]];
			if (![objectInfo objectForKey: @"ignore-errors"]) [inaccessibleObjects addObject: objectInfo[@"name"]];		//sync_objects.plist key
		}
		
	}
	
	if (inaccessibleObjects.count) {
		NSString		*title = $S(@"Trying to Sync an Inaccessible Object (%@)", inaccessibleObjects[0]);
		
		if (inaccessibleObjects.count > 1) title = $S(@"Trying to Sync Inaccessible Objects (%@)", [inaccessibleObjects componentsJoinedByString: @", "]);
        
        if (!self.allowIncompleteObjectSyncs) {
            [NSObject performBlock: ^{
                [self cancelSync: mm_sync_cancel_reason_inaccessible_object];
                [MM_LoginViewController logout];
                [[MM_ContextManager sharedManager] removeAllDataIncludingMetaData: YES withDelay: 0.0];
                [SA_AlertView showAlertWithTitle: title message: @"Please make sure the administrator has given your user access as required." tag: 4524];
            } afterDelay: 1.0];
            return nil;
        } else
            [SA_AlertView showAlertWithTitle: title message: @"Please make sure the administrator has given your user access as required." tag: 4524];
	}
	
	return objectsToSync;
}

#pragma mark - Notifications

- (void) resignedActiveState: (NSNotification *) note {
	if (self.oauthValidating) {
		self.validationOperation = nil;
		self.oauthValidated = NO;
		self.oauthValidating = NO;
	}
}

- (void) connectionStateChanged: (NSNotification *) note {
	BOOL					online = ![SA_ConnectionQueue sharedQueue].offline;
	
	if (self.isSyncInProgress && !online) {
		[NSObject performBlock: ^{
			if (!_isSyncInProgress) return;		//already cancelled
			[self pauseSynchronization: NO];
			[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Sorry, Your Internet Connection was Lost" , @"Sorry, Your Internet Connection was Lost")
									 message: NSLocalizedString(@"Please try synchronizing later.", @"Please try synchronizing later.")];
		} afterDelay: 0.1];
	} else if (online && self.syncInterrupted && [MM_LoginViewController isLoggedIn]) {
		[self performSelector: @selector(resumeSynchronization) withObject: nil afterDelay: 2.0];
	}
}


//================================================================================================================
#pragma mark - Background task management

- (void) willEnterForeground: (NSNotification *) note {
	if (!self.isSyncInProgress && _isSyncInProgress) {
		[self finishSynchronization: YES];
	}
	[self.backgroundCleanupTimer invalidate];
	dispatch_sync(self.syncDispatchQueue, ^{
		[[UIApplication sharedApplication] endBackgroundTask: self.backgroundTaskIdentifier];
		self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
	});
}

- (void) didEnterBackground: (NSNotification *) note {
	if (self.isSyncInProgress) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSTimeInterval				remainingTime = [UIApplication sharedApplication].backgroundTimeRemaining;
			NSTimeInterval				alertTime = 1;//MAX(0, remainingTime - 60.0);			//show the alert immediately
			NSTimeInterval				cleanupTime = MAX(0, remainingTime - 30.0);
			
			
			MMLog(@"You have %.0f sec remaining", remainingTime);
			self.backgroundSyncReminder = [UILocalNotification new];
			self.backgroundSyncReminder.fireDate = [NSDate dateWithTimeIntervalSinceNow: alertTime];
			self.backgroundSyncReminder.alertBody = $S(@"Please return to %@ to complete your synchronization.", [NSBundle visibleName]);
			self.backgroundSyncReminder.alertAction = @"Return";
			[[UIApplication sharedApplication] scheduleLocalNotification: self.backgroundSyncReminder ];
			
			self.backgroundCleanupTimer = [NSTimer scheduledTimerWithTimeInterval: cleanupTime target: self selector: @selector(cancelDueToBackgroundTaskExpiration) userInfo: nil repeats: NO];
		});
		
		self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
			[self cancelDueToBackgroundTaskExpiration];
		}];
	}
}

- (void) cancelDueToBackgroundTaskExpiration {
	MMLog(@"Cancelling the sync due to task expiration", @"");
	[self.backgroundCleanupTimer invalidate];
	dispatch_sync(self.syncDispatchQueue, ^{
		if (self.backgroundSyncReminder) [[UIApplication sharedApplication] cancelLocalNotification: self.backgroundSyncReminder];
		if (self.isSyncInProgress) [self cancelSync: mm_sync_cancel_reason_left_app];
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
			[[UIApplication sharedApplication] endBackgroundTask: self.backgroundTaskIdentifier];
			self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		}
	});
}

- (void) returnToAppAndContinueSync {
	MMLog(@"returning to the app.", @"");
	[self.backgroundCleanupTimer invalidate];
	dispatch_sync(self.syncDispatchQueue, ^{
		[[UIApplication sharedApplication] cancelLocalNotification: self.backgroundSyncReminder];
		if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
			[self cancelSync: mm_sync_cancel_reason_left_app];
			[[UIApplication sharedApplication] endBackgroundTask: self.backgroundTaskIdentifier];
			self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
		}
	});
}

#if kRESTLibraryResumesSyncOnLaunch
- (void) applicationDidFinishLaunching:(NSNotification *)note {
	if ([MM_SyncManager sharedManager].hasSyncedOnce && [MM_SyncStatus status].isSyncInProgress && self.syncFailureHandling == syncFailureHandling_autoPerformDelta && !self.isSyncInProgress && ![MM_LoginViewController isEnteringCredentials]) {
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_SyncWillResume object: nil];
		[self deltaSyncWithCompletionBlock: nil];
	}
}

#endif

#pragma mark - properties

- (BOOL) hasSyncedOnce {
	if (![[NSUserDefaults standardUserDefaults] boolForKey: kMMDefaults_SyncCompletedOnce]) return NO;

//this causes a huge lag
//	for (MM_SFObjectDefinition *def in self.objectsToSync) {
//		if (def.shouldSyncServerData && def.lastSyncedAt_mm == nil) return NO;
//	}
	return YES;
}

- (void) setHasSyncedOnce: (BOOL) hasSyncedOnce {
	[[NSUserDefaults standardUserDefaults] setBool: hasSyncedOnce forKey: kMMDefaults_SyncCompletedOnce];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Misc

static id currentUser = nil;

+ (id) currentUserInContext: (NSManagedObjectContext *) ctx {
    
    NSString					*userID = [SFOAuthCoordinator fullUserId];
	if (userID == nil) return nil;
	if (ctx == nil) ctx = [[MM_ContextManager sharedManager] threadContentContext];
    
    if (currentUser == nil || ![[currentUser Id] isEqualToString:userID] || ![[currentUser managedObjectContext] isEqual:ctx]) {
        currentUser = [ctx anyObjectOfType: @"User" matchingPredicate: $P(@"Id == %@", userID)];
    }
    
	return currentUser;
}

#pragma mark - Dependencies

- (BOOL) areConnectionsPending {
	for (MM_RestOperation *op in [self.pending arrayByAddingObjectsFromArray: self.active]) {
		if (op.query) return YES;
	}
	return NO;
}

- (BOOL) areDependenciesMetForObject: (NSString *) objectName {
	return ([self.remainingObjectDependencies[objectName] count] == 0);
}

- (void) markObjectAsSynced: (MM_SFObjectDefinition *) objectDef {
	for (MM_RestOperation *op in self.pending.copy) {
		if ([op.query.objectName isEqual: objectDef.name]) return;			//not fully complete
	}
	
    [self clearDependenciesForObject:objectDef.name];
	
	[self.pendingObjectNames removeObject: objectDef.name];
	[self.remainingObjectDependencies removeObjectForKey: objectDef.name];
	[self.completedSyncObjects addObject: objectDef.name];
}

- (NSArray *)clearDependenciesForObject:(NSString *)objectName {
    NSMutableSet *clearedDependencies = [NSMutableSet set];
    
    NSMutableSet *objectsToCheck = [self.completedSyncObjects mutableCopy];
    if (objectName) [objectsToCheck addObject:objectName];
    
    for (NSString *pendingObject in self.remainingObjectDependencies.copy) {
        NSMutableArray *dependencies = self.remainingObjectDependencies[pendingObject];
        
        if (!dependencies.count)
            continue;
        
        for (NSString *objectName in objectsToCheck) {
            if ([dependencies containsObject: objectName]) {
                [dependencies removeObject: objectName];
                if (dependencies.count)
                    self.remainingObjectDependencies[pendingObject] = dependencies;
                else {
                    MMLog(@"All dependencies met for %@", pendingObject);
                    [self.remainingObjectDependencies removeObjectForKey: pendingObject];
                    [clearedDependencies addObject:pendingObject];
                }
            }
        }
    }
    
    return clearedDependencies.count ? clearedDependencies.allObjects : nil;
}

#pragma mark - Parsing

static NSUInteger					s_parseCount = 0;
+ (void) incrementParseCount {
	@synchronized (self) {
		s_parseCount++;
	}
}

+ (void) decrementParseCount {
	@synchronized (self) {
		if (s_parseCount)
			s_parseCount--;
		else {
		//	IF_SIM([SA_AlertView showAlertWithTitle: @"Trying to decrement parse count when it was 0." message: nil]);
		}
	}
	
	if (![self isParsing] && [MM_SyncManager sharedManager].active.count == 0)
		[NSObject performBlock: ^{
			if (![self isParsing]) {
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ParseCompleted object: nil];
				dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
					[[MM_SyncManager sharedManager] advanceQueue];
				});
			}} afterDelay: 10.0];
}

+ (BOOL) isParsing {
	return s_parseCount > 0;
}

@end

