//
//  MMSF_Category__c.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"

@class MMSF_Attachment;

@interface MMSF_Category__c : MMSF_Object {
    NSArray	*_sortedSubCategories,*_sortedContents;
}

@property (nonatomic, readonly) NSArray *sortedSubcategories,*sortedContents; //???
@property(nonatomic,strong) NSDate *CreatedDate;
@property(nonatomic,strong) NSNumber *IsDeleted;
@property(nonatomic,strong) NSString *Name;
@property (nonatomic,strong) NSDate *LastModifiedDate;
@property(nonatomic,strong) NSString *Description__c;
@property(nonatomic,strong) MMSF_Category__c *Parent_Category__c;
@property(nonatomic, assign,readonly) BOOL isEmpty;
@property(nonatomic,strong) NSNumber *Order__c;
@property(nonatomic,strong) NSNumber *Todays_Special__c;

@property (nonatomic,strong) id OwnerId;
@property (nonatomic, readwrite, strong) NSMutableDictionary *selectedSubCategories;

- (NSArray *) contentsAndSubcategoriesMatchingPredicate: (NSPredicate *) predicate;

- (MMSF_Category__c *) selectedSubCategoryForKey: (NSString *) key;


/**
 *  Iterate through Parent_Category__c to get the full list of categories.
 *
 *  @return Array of categories in descending (top-to-bottom) order
 */
- (NSArray *)parentCategories;

- (NSArray *) allDocumentsMatchingPredicate: (NSPredicate *) predicate includingSubCategories: (BOOL) includingSubCategories ;
- (void) selectSubCategory: (MMSF_Category__c *) category forKey: (NSString *) key;
+ (NSArray*) allActiveCategoriesInContext:(NSManagedObjectContext*) context;

- (NSComparisonResult) compareForNLevelDisplay: (MMSF_Category__c *) category;

- (BOOL)hasAttachment;
- (MMSF_Attachment *)attachment;
- (UIImage *) attachmentImage;

@end
