//
//  MMSF_User.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"
#import "MM_SOQLQueryString.h"
#import "MMSF_Category__c.h"
#import "DSARestClient.h"

@class MMSF_Category__c;
@interface MMSF_User : MMSF_Object

@property (nonatomic,assign) BOOL isLoggedIn;
@property (nonatomic,strong) NSString *name;

+ (MMSF_User *) currentUser ;
+ (void) setCurrentUser:(MMSF_User*)user;

+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs;

- (void) clearSelectedCategories ;
- (MMSF_Category__c *) selectedSubCategoryForKey:(NSString *) key;
- (void) selectSubCategory: (MMSF_Category__c *) category forKey:(NSString *) key;

- (NSArray *) topLevelCategoriesForCurrentConfig;

- (NSArray *) allDocumentsMatchingPredicate: (NSPredicate *) predicate;

- (void) requestProfileId;
+ (void) resetCachedtopLevelCatgories;
@end
