//
//  DSA_BaseTabsViewController.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/21/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSA_MediaDisplayViewController.h"

@class DSA_TabBar;

@interface DSA_BaseTabsViewController : UIViewController <UITabBarControllerDelegate, DSA_MediaDisplayViewControllerDelegate>

@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic, strong) DSA_TabBar *tabBar;
extern const CGFloat kTabBarHeight;
extern const CGFloat kTabWidth;

- (void)enableTabBar:(BOOL)enable;

@end
