//
//  MMSF_User.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_User.h"
#import "MM_LoginViewController.h"
#import "MM_ContextManager.h"
#import "MMSF_MobileAppConfig__c.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "MMSF_Category__c.h"
#import "MM_Constants.h"
#import "RKXMLParserLibXML.h"
#import "DSA_AppDelegate.h"
#import "MMSF_ContentVersion.h"

static MMSF_User				*s_currentUser = nil;

@interface MMSF_User ()
@property (nonatomic, strong) NSMutableDictionary *selectedSubCategories;
@end

@implementation MMSF_User
@synthesize selectedSubCategories;
@synthesize name;


+ (MMSF_User *) currentUser {
	return [MM_SyncManager currentUserInContext: nil];    
}

- (void) clearSelectedCategories {
	self.selectedSubCategories = nil;
}

+ (void) setCurrentUser:(MMSF_User*)user {
    s_currentUser = user;
}

static NSArray				*s_topLevelCategories = nil;

+ (void) resetCachedtopLevelCatgories {
	s_topLevelCategories = nil;
}

- (NSArray *) topLevelCategoriesForCurrentConfig
{
	if (s_topLevelCategories == nil) {
		NSMutableArray* result = [NSMutableArray array];
		
		MMSF_MobileAppConfig__c* mac = nil;
		
		NSString* configObjectId = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultKey_selectedMobileAppConfig];
		if (configObjectId != nil)
		{
			mac = [[MM_ContextManager sharedManager].threadContentContext anyObjectOfType:@"MobileAppConfig__c" matchingPredicate:[NSPredicate predicateWithFormat:@"Id == %@",configObjectId]];
		}
		
		if (mac != nil)
		{
			NSManagedObjectContext *context = [MM_ContextManager sharedManager].threadContentContext;
			NSString			*format = $S(@"%@ = %%@", MNSS(@"MobileAppConfigurationId__c"));

			NSArray* categoryConfigs= [context allObjectsOfType:@"CategoryMobileConfig__c" matchingPredicate:[NSPredicate predicateWithFormat: format,mac]];
			format = $S(@"Id = %%@ AND %@ == nil", MNSS(@"Parent_Category__c"));
			
			for (MMSF_CategoryMobileConfig__c * catConfig in categoryConfigs)
			{
				NSString* catId = catConfig.CategoryId__c.Id;
				MMSF_Category__c *cat = [context anyObjectOfType:@"Category__c" matchingPredicate:[NSPredicate predicateWithFormat: format,catId]];
				if (cat != nil && ![result containsObject: cat])
				{
					[result addObject: cat];
				}
			}
			//get cat configs for app config
			//get cats for cat configs
		}

		NSSortDescriptor * sd = [NSSortDescriptor descriptorWithKey:MNSS(@"Order__c") ascending:YES];
		NSSortDescriptor * sn = [NSSortDescriptor descriptorWithKey:@"Name" ascending:YES];
		s_topLevelCategories = [result sortedArrayUsingDescriptors:@[sd,sn]];
	}
	return s_topLevelCategories;
}

- (MMSF_Category__c *) selectedSubCategoryForKey:(NSString *) key 
{
    NSString			*objectID = [self.selectedSubCategories objectForKey: key];
	
	return [self.moc objectWithIDString: objectID];
}


- (void) selectSubCategory: (MMSF_Category__c *) category forKey: (NSString *) key {
    
    if (self.selectedSubCategories == nil) self.selectedSubCategories = [NSMutableDictionary dictionary];
	if (category)
		[self.selectedSubCategories setObject:category.objectIDString forKey: key];
	else
		[self.selectedSubCategories removeObjectForKey: key];
}

+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs {
    // Get the Query object from the definition and add the filters
    NSManagedObjectContext  *metaContext = [MM_ContextManager sharedManager].metaContextForWriting;
    MM_SFObjectDefinition   *def = [MM_SFObjectDefinition objectNamed:[MMSF_User entityName] inContext:metaContext];
    MM_SOQLQueryString      *query = [def baseQueryIncludingData:NO];
    query.fields = [NSArray arrayWithObjects: @"Id",@"LastModifiedDate",@"CreatedDate",@"Username",@"Name"
                    ,@"FirstName",@"LastName",@"Email", @"UserPermissionsSFContentUser", nil];
    

    query.predicate = [MM_SOQLPredicate predicateWithString: [NSString stringWithFormat:@"Id = '%@'",[SFOAuthCoordinator fullUserId] ]];
    
    return query;
}

- (BOOL) isLoggedIn {
    
	return ([[NSUserDefaults standardUserDefaults] valueForKey:kDefaults_CurrentLoggedInUserID] != nil); 
}

- (void) setIsLoggedIn: (BOOL) loggedIn {	
    
    NSUserDefaults					*defaults = [NSUserDefaults standardUserDefaults];
	
	if (self.isLoggedIn) {
		if (!loggedIn) {
			[defaults setObject: nil forKey: kDefaults_CurrentLoggedInUserID];
			[defaults synchronize];
		}
	} else if (loggedIn) {
		[defaults setObject: self.objectIDString forKey: kDefaults_CurrentLoggedInUserID];
		[defaults synchronize];
	}
}


// Be aware that now allDocumentsMatchingPredicate implicitly returns only documents related to currently selected configuration
- (NSArray *) allDocumentsMatchingPredicate: (NSPredicate *) predicate {
	NSMutableSet					*results = [NSMutableSet set];
    
    MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];

    for (MMSF_CategoryMobileConfig__c* catConfig in [mac sortedCategoryConfigurations])
    {
        MMSF_Category__c *category = [catConfig valueForKey:MNSS(@"CategoryId__c")];
        
        /*to remove empty categories*/
        //NSArray* subsWithContent = [category sortedSubcategories];
       // if(subsWithContent.count==0)
         //   continue;
        
        [results addObjectsFromArray: [category allDocumentsMatchingPredicate:predicate includingSubCategories:YES]];
    }
	
	NSMutableArray		*filteredResults = [NSMutableArray new];
	for (MMSF_ContentVersion *content in results) {
		if (content.categoryLocationPath.length > 0) [filteredResults addObject: content];
	}
	return filteredResults;
	
//	return [results allObjects];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) requestProfileId {
	NSString			*soap = $S(@"<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns='urn:partner.soap.sforce.com'>"
								   @"<s:Header>"
								   @"<SessionHeader><sessionId>%@</sessionId></SessionHeader>"
								   @"</s:Header>"
								   @"<s:Body>"
								   @"<getUserInfo />"
								   @"</s:Body>"
								   @"</s:Envelope>", [SFOAuthCoordinator currentAccessToken]);
	NSData				*soapData = [NSData dataWithString: soap];
	NSString			*soapURL = [[NSUserDefaults standardUserDefaults] objectForKey: DEFAULTS_SOAP_URL];
	
	if (soapURL == nil) return;
	
	SA_Connection		*connection = [SA_Connection connectionWithURL: [NSURL URLWithString: soapURL] payload: soapData method: @"POST" priority: 5 completionBlock: ^(SA_Connection *incoming, int result, NSError *error) {
		NSDictionary			*results = [[[RKXMLParserLibXML alloc] init] parseXML: incoming.dataString];
		
		results = [[[[results objectForKey: @"Envelope"] objectForKey: @"Body"] objectForKey: @"getUserInfoResponse"] objectForKey: @"result"];
        
        NSManagedObjectContext* ctx = [[MM_ContextManager sharedManager] contentContextForWriting];
        MMSF_User* me = [MM_SyncManager currentUserInContext:ctx];
        NSString* profileId = [results objectForKey:@"profileId"];
        
        [me setValue:profileId forKey:@"UserProfileId"];
        [me save];
        
	}];
	[connection addHeader: $S(@"OAuth %@", [SFOAuthCoordinator currentAccessToken]) label: @"Authorization"];
	[connection addHeader: @"text/xml" label: @"Content-Type"];
	[connection addHeader: @"\"\"" label: @"Soapaction"];
	[connection queue];
}

@end
