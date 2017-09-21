//
//  MMSF_Cat_Content_Junction__c.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 11/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Cat_Content_Junction__c.h"
#import "MM_ContextManager.h"
#import "MMSF_Category__c.h"
#import "MMSF_ContentDocument.h"
#import "MMSF_ContentVersion.h"

static NSArray			*s_categoryIDList = nil;

@implementation MMSF_Cat_Content_Junction__c
+ (void) initialize {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(syncBegan:) name: kNotification_SyncBegan object: nil];
	}
}

+ (void) syncBegan: (NSNotification *) note {
	s_categoryIDList = nil;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
+ (void) processCategory:(MMSF_Category__c*) category categorySet:(NSMutableSet*) categorySet {
    if (category.Id) {
        [categorySet addObject:category.Id];
    }
    
    for (MMSF_Category__c* currCat in category.sortedSubcategories.copy) {
        [self processCategory:currCat categorySet:categorySet];
    }
}

- (MMSF_ContentVersion *) contentVersion {
	return [MMSF_ContentVersion versionMatchingDocumentID: self[MNSS(@"ContentId__c")] inContext: self.moc];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs
{
    
    NSManagedObjectContext  *metaContext = [MM_ContextManager sharedManager].threadMetaContext;
    MM_SFObjectDefinition   *def = [MM_SFObjectDefinition objectNamed:@"Cat_Content_Junction__c" inContext: metaContext];

    // Getting the all the Category ID's that are to be added in the Where Clause
    NSManagedObjectContext  *mainContext = [MM_ContextManager sharedManager].threadContentContext;
    
    
    //Get the Query object from the definition and add the filters
    MM_SOQLQueryString *query = [def baseQueryIncludingData:NO];
    
	if (s_categoryIDList == nil) {
		NSArray      *categoryArray = [MMSF_Category__c allActiveCategoriesInContext:mainContext];
		
		NSMutableSet* categorySet = [NSMutableSet set];
		
		for (MMSF_Category__c* category in categoryArray.copy)
		{
			[self processCategory:category categorySet:categorySet];
		}
    
		s_categoryIDList = [categorySet allObjects];
	}
		
    NSString* filter;
    
    if (s_categoryIDList.count) {
		[query addAndPredicate: [MM_SOQLPredicate predicateWithFilteredIDs: s_categoryIDList forField: MNSS(@"Category__c")]];
    } else {
		query.fetchLimit = 1;
        
    }
    
    [query addPredicateString:filter];
    return query;
}

@end
