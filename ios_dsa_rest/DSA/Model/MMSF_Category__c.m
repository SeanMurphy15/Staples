//
//  MMSF_Category__c.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Category__c.h"
#import "MM_ContextManager.h"
#import "MMSF_Attachment.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "MMSF_Cat_Content_Junction__c.h"
#import "MMSF_ContentVersion.h"

// sort Contents: default = Title, by date = LastModifiedDate
#define kSortOrder_Title            @"Title"
#define kSortOrder_LastModifiedDate @"LastModifiedDate"
#define kSortOrder                  kSortOrder_Title

@implementation MMSF_Category__c

@dynamic CreatedDate;
@dynamic IsDeleted;
@dynamic Name;
@dynamic LastModifiedDate;
@synthesize selectedSubCategories;
@dynamic OwnerId;

MMNS_OBJECT_PROPERTY(Description__c);
MMNS_OBJECT_PROPERTY(Order__c);
MMNS_OBJECT_PROPERTY(Parent_Category__c);
MMNS_OBJECT_PROPERTY(Todays_Special__c);

- (BOOL) isEmpty {
    static NSString		*format = nil;
	
	if (format == nil) format = $S(@"%@ = %%@", MNSS(@"Parent_Category__c"));

    NSPredicate			*pred = $P(format, self);
    NSArray				*subcategories = [self.moc allObjectsOfType: [MMSF_Category__c entityName] matchingPredicate: pred];
    
    for (MMSF_Category__c *category in subcategories.copy) {
        if (!category.isEmpty) return NO;
    }
	
	if (self.hasContent) return NO;
	return YES;
}

- (NSArray *) recursiveSubCategories {
	NSMutableArray			*cats = [NSMutableArray arrayWithObject: self];
	NSString				*format = $S(@"%@ = %%@", MNSS(@"Parent_Category__c"));
	NSPredicate				*categoryPredicate = $P(format, self);
	
	NSArray *subCategories = [self.moc allObjectsOfType: [MMSF_Category__c entityName] matchingPredicate: categoryPredicate];
	
	for (MMSF_Category__c *category in subCategories.copy) {
		[cats addObjectsFromArray: [category recursiveSubCategories]];
	}
	return cats;
}

+ (NSArray*) allActiveCategoriesInContext:(NSManagedObjectContext*) context
{
    
    NSArray *catconfigArray =  [MMSF_CategoryMobileConfig__c allActiveCategoryMobileConfigurationsInContext:context];
	
    NSMutableArray *categories = [NSMutableArray array];
    
    for (MMSF_CategoryMobileConfig__c *catConfig in catconfigArray) {
        MMSF_Category__c			*category = catConfig.CategoryId__c;
		
		if (category == nil && catConfig[MNSS(@"CategoryId__c_sfid_shadow_mm")]) {
			category = [context anyObjectOfType: [MMSF_Category__c entityName] matchingPredicate: $P(@"Id = %@", catConfig[MNSS(@"CategoryId__c_sfid_shadow_mm")])];
		}
		if (category) [categories addObject: category];
        
		NSString				*format = $S(@"%@ = %%@ || %@ = %%@", MNSS(@"Parent_Category__c"), MNSS(@"Parent_Category__c_sfid_shadow_mm"));
        NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:format, category, category.Id];
        
        NSArray *subCategories = [context allObjectsOfType: [MMSF_Category__c entityName] matchingPredicate:categoryPredicate];
        
        for(MMSF_Category__c *subCategory in subCategories) {
			if (![categories containsObject: subCategory])
				[categories addObjectsFromArray: [subCategory recursiveSubCategories]];
        }
    }

    return categories; // The list of categories mapped to active CMC and its associated subcategories
}

- (NSComparisonResult) compareForNLevelDisplay: (MMSF_Category__c *) category {
	NSNumber				*myTodaysSpecial = self.Todays_Special__c, *theirTodaysSpecial = category.Todays_Special__c;
	
	if (myTodaysSpecial.boolValue && !theirTodaysSpecial.boolValue) return NSOrderedAscending;
	if (theirTodaysSpecial.boolValue && !myTodaysSpecial.boolValue) return NSOrderedDescending;

	#if CATEGORIES_ORDERED_ON
		NSNumber				*myOrder = self.Order__c, *theirOrder = category.Order__c;
		
		if (myOrder.intValue && theirOrder.intValue) return [myOrder compare: theirOrder];
		
		if (myOrder.intValue) return NSOrderedAscending;
		if (theirOrder.intValue) return NSOrderedDescending;
	#endif
    
	return [self.Name caseInsensitiveCompare: category.Name];
}

- (NSArray *) sortedSubcategories {
    NSString	*format = $S(@"%@ = %%@ || %@ = %%@", MNSS(@"Parent_Category__c"), MNSS(@"Parent_Category__c_sfid_shadow_mm"));
    NSPredicate *pred   = [NSPredicate predicateWithFormat:format, self, self.Id];
    
    NSArray	*subs         = [self.moc allObjectsOfType: [MMSF_Category__c entityName] matchingPredicate:pred];
    NSMutableArray *array = [NSMutableArray array];
    
    for (MMSF_Category__c *record in subs.copy) {

        if(![record isEmpty]) {
            [array addObject:record];
        }
    }

    _sortedSubCategories = array;
	
	return _sortedSubCategories;
}

- (NSArray *)parentCategories {
    NSArray *outArray = nil;
    NSMutableArray *parentArray = [NSMutableArray arrayWithCapacity:0];
    MMSF_Category__c *parent = self.Parent_Category__c;
    
    while (parent != nil) {
        [parentArray insertObject:parent atIndex:0];
        parent = parent.Parent_Category__c;
    }
    
    if (parentArray.count) {
        outArray = parentArray.copy;
    }
	
    return outArray;
}

- (NSPredicate *) contentPredicate {
    NSString            *format = $S(@"%@.Id == %%@", MNSS(@"Category__c"));
    NSPredicate         *pred = $P(format, self.Id);
	
    
    BOOL isInternalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
    
    if (isInternalMode) {
        
        
    } else {
        format = $S(@"%@ == %%@ || %@ == nil", MNSS(@"Internal_Document__c"), MNSS(@"Internal_Document__c"));
		
        pred = [NSCompoundPredicate andPredicateWithSubpredicates: @[ pred, $P(format, @NO) ]];
    }
	return pred;
}

- (NSArray *)sortedContents {
    NSPredicate			*pred = [self contentPredicate];
    NSArray				*subs = [self.moc allObjectsOfType: [MMSF_Cat_Content_Junction__c entityName] matchingPredicate: pred];
	NSMutableArray		*contents = [[subs valueForKey: @"contentVersion"] mutableCopy];
    
    // added a step to prevent returning objects whose data isn't loaded.
    //!!!gmu 
    [contents filterUsingPredicate:[NSPredicate predicateWithFormat:@"isFileDownloaded == YES"]];

	[contents removeObject: [NSNull null]];
    
    NSSortDescriptor *sort = nil;
    if ([kSortOrder isEqualToString:kSortOrder_LastModifiedDate]) {
        // latest first
        sort = [[NSSortDescriptor alloc] initWithKey:kSortOrder_LastModifiedDate ascending:NO selector:@selector(compare:)];
    } else if ([kSortOrder isEqualToString:kSortOrder_Title]) {
        sort = [[NSSortDescriptor alloc] initWithKey:kSortOrder_Title ascending: YES selector: @selector(localizedCaseInsensitiveCompare:)];
    }
    if (sort != nil)
    {
        _sortedContents = [contents sortedArrayUsingDescriptors: @[ sort ]] ;
    }
    
    return _sortedContents;
}

- (BOOL) hasContent {
	NSPredicate	*pred = [self contentPredicate];
    NSArray *catContentJuncs = [self.moc allObjectsOfType:[MMSF_Cat_Content_Junction__c entityName] matchingPredicate: pred];
    
    BOOL contentExists = NO;
    for (MMSF_Cat_Content_Junction__c *junk in catContentJuncs)
    {
        NSString *contentId = [junk valueForKey:MNSS(@"ContentId__c")];
        MMSF_ContentVersion *content = [MMSF_ContentVersion versionMatchingDocumentID:contentId inContext:self.moc];
        if (content != nil)
        {
            contentExists = YES;
            break;
        }
    }
    
    if (!contentExists) MMLog(@"Suppressing category named \"%@\" because it has no offline content.", self.Name);
    
    return contentExists;
}

- (NSArray *) contentsAndSubcategoriesMatchingPredicate: (NSPredicate *) predicate
{	
    NSMutableArray					*results = [NSMutableArray array];

    for (MMSF_Category__c *category in self.sortedSubcategories.copy) {
			[results addObject: category];
		}
	    
    for (MMSF_Object *category in self.sortedContents) {
        [results addObject: category];
    }
    

return results;

}

- (MMSF_Category__c *) selectedSubCategoryForKey: (NSString *) key 
{
    NSString			*objectID = [self.selectedSubCategories objectForKey: key];
	return [self.moc objectWithIDString: objectID];
}

- (void) selectSubCategory: (MMSF_Category__c *) category forKey: (NSString *) key {
	if (self.selectedSubCategories == nil) self.selectedSubCategories = [NSMutableDictionary dictionary];
	
	if (category)
    {
       [self.selectedSubCategories setObject: category.objectIDString forKey: key];
    }
	else{
        [self.selectedSubCategories removeObjectForKey: key];

    }
}

- (NSArray *) allDocumentsMatchingPredicate: (NSPredicate *) predicate includingSubCategories: (BOOL) includingSubCategories {
	NSMutableArray					*results = nil;
	
    results = [NSMutableArray arrayWithArray:[[self sortedContents] subarrayWithObjectsSatisfyingPredicate:predicate]];/*Fixed DE373*/
	if (results == nil) results = [NSMutableArray array];
	
    if (includingSubCategories) {
		for (MMSF_Category__c *category in [self sortedSubcategories].copy) {
			[results addObjectsFromArray: [category allDocumentsMatchingPredicate: predicate includingSubCategories: YES]];
		}
	}

	return results;
}

#pragma mark - Attachment

- (MMSF_Attachment *)attachment {
    NSPredicate	*pred = [NSPredicate predicateWithFormat:@"ParentId = %@", self.Id];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"CreatedDate" ascending:NO];
    
    MMSF_Attachment	*attachment = [[[MM_ContextManager sharedManager] threadContentContext] firstObjectOfType:@"Attachment"  matchingPredicate:pred sortedBy:@[sd]];
    
    return  attachment;
}

- (BOOL)hasAttachment {
    MMSF_Attachment *attachment = [self attachment];
    
    return attachment ? YES : NO;
}

- (UIImage *) attachmentImage {
    //There are instances where more than one attachment exists (seems like after the first time changed)
    //but upon subsequent changes seems to clean up properly and only 1 attachment persists.  This is
    //definitely only treating the symptom and not the disease (DE187)
    
    UIImage *image = nil;
    MMSF_Attachment* attachment = [self attachment];
    
	if (attachment) {
        image = [UIImage imageWithContentsOfFile:[attachment filepath]];
    } else {
        image = [UIImage imageNamed: @"default_category_image.png"];
    }
    
    return image;
}

@end
