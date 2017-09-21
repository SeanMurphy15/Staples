//
//  ZM_LibraryShelfView.h
//  Zimmer
//
//  Created by Ben Gottlieb on 5/7/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DSA_LibraryShelfView : UIView <SA_LazyLoadingScrollViewDataSource> {
    
}

@property (nonatomic, strong) SA_LazyLoadingScrollView *contentView;
@property (nonatomic, strong) NSArray *contentItems;
@property (nonatomic, assign) UIViewController *viewController;
@property (nonatomic, strong) UIImageView *shadowView;
@property (nonatomic, strong) NSString *shelfName;

+ (NSString *) identifier;
+ (id) tableCellWithContentItems: (NSArray *) contentItems inViewController: (UIViewController *) controller;
@end

@interface UITableViewCell (ZM_LibraryShelfView) 
- (void) setContentItems: (NSArray *) items;
- (void) setShelfName: (NSString *) name;
@end