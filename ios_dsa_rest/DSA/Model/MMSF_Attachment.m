//
//  MMSF_Attachment.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Attachment.h"
#import "MMSF_Category__c.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "MM_ContextManager.h"
#import "MMSF_MobileAppConfig__c.h"

#define			ATTACHMENT_DIRECTORY_NAME					@"attachments"

@implementation MMSF_Attachment

@synthesize documentsPath = _documentsPath;

@dynamic Body;
@dynamic BodyLength;

- (NSString *) filepath {
	return [self pathForDataField:@"Body"];
}

- (NSString *) documentsPath {
    if (_documentsPath == nil)
        self.documentsPath = [@"~/Library/Private Documents/" stringByExpandingTildeInPath];
    
    return _documentsPath;
}

+ (MMSF_Attachment*) attachmentWithSalesforceId:(NSString*) salesforceId {
	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
	NSPredicate						*predicate = [NSPredicate predicateWithFormat: @"Id BEGINSWITH %@",salesforceId];
	
	MMSF_Attachment* attachment = [moc anyObjectOfType:@"Attachment" matchingPredicate: predicate];

	return attachment;
}

+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs {
    NSManagedObjectContext  *metaContext = [MM_ContextManager sharedManager].metaContextForWriting;
    MM_SFObjectDefinition   *def = [MM_SFObjectDefinition objectNamed: @"Attachment" inContext: metaContext];
    MM_SOQLQueryString *query = [def baseQueryIncludingData:NO];
    NSManagedObjectContext  *moc = [MM_ContextManager sharedManager].threadContentContext;
   
    //Categories mapped to active configs
    NSArray      *categoryArray = [MMSF_Category__c allActiveCategoriesInContext:moc];
    // Category Mobile Configs mapped to active configs
    NSArray      *categoryConfigArray = [MMSF_CategoryMobileConfig__c allActiveCategoryMobileConfigurationsInContext:moc];
    //active configs
    NSArray      *appConfigArray = [MMSF_MobileAppConfig__c allActiveMobileConfigurationsInContext:moc];
        
    NSMutableSet* idSet = [NSMutableSet setWithCapacity:100];
    
    for (MMSF_Category__c* category in categoryArray.copy) {
        [idSet addObject:category.Id];
        }
    
    for (MMSF_CategoryMobileConfig__c* categoryConfig in categoryConfigArray) {
		MMSF_MobileAppConfig__c			*maConfig = categoryConfig[MNSS(@"MobileAppConfigurationId__c")];
		
		if (maConfig == nil) {
			NSPredicate			*pred = [NSPredicate predicateWithFormat: @"Id == %@", categoryConfig[MNSS(@"MobileAppConfigurationId__c_sfid_shadow_mm")]];

			maConfig = [moc anyObjectOfType: [MMSF_MobileAppConfig__c entityName] matchingPredicate: pred];
		}

        if (![maConfig[MNSS(@"Active__c")] boolValue] || [categoryConfig[MNSS(@"IsDraft__c")] boolValue]) continue;
        [idSet addObject:categoryConfig.Id];
        }
        
    for (MMSF_MobileAppConfig__c* mobileAppConfig in appConfigArray) {
        if (![mobileAppConfig[MNSS(@"Active__c")] boolValue]) continue;
        [idSet addObject: mobileAppConfig.Id];
        }
    
    NSArray * parentIds = [idSet allObjects];
    
    if ([parentIds count]) {
        [query filterForIDs:parentIds inField:@"ParentId"];
    } else {
        query.fetchLimit = 1;
    }
    
    return query;
}

@end
