//
//  ZM_BrowseColumnView.h
//
//  Created by Ben Gottlieb on 9/2/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_User.h"
#import "MMSF_Category__c.h"
#define kNotification_CategorySelected @"categorySelected"


@interface DSA_BrowseColumnView : UIView <UITableViewDelegate, UITableViewDataSource> {

}

@property (nonatomic, readwrite, strong) UILabel *noContentLabel;
@property (nonatomic, readwrite, strong) UINavigationBar *navigationBar;
@property (nonatomic, readwrite, strong) UITableView *tableView;
@property (nonatomic, readwrite, strong) MMSF_Category__c *category;
@property (nonatomic, readwrite, strong) MMSF_User *user;
@property (nonatomic, readonly) NSUInteger selectedRow;
@property (nonatomic, readonly) BOOL hasContent;
@property (nonatomic, readwrite, strong) NSString *subCategoryKey;
@property (nonatomic, readwrite, strong) NSPredicate *filterPredicate;
@property (nonatomic, readwrite, strong) UIColor *tableBackgroundColor;
@property (nonatomic, readwrite, strong) NSArray *visibleCategoriesAndItems;

+ (id) rootColumnViewWithUser: (MMSF_User *) user;
+ (id) columnViewWithCategory: (MMSF_Category__c *) category;
- (void) clearCaches;

@end
