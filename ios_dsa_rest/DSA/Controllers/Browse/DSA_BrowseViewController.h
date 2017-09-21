//
//  ZM_BrowseViewController.h
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_MediaDisplayViewController.h"

#define kBrowserColumnItemSelectedNotification @"com.modelmetrics.dsaapp.browserColumnItemSelected"

@interface DSA_BrowseViewController : UIViewController <UIAlertViewDelegate, DSA_MediaDisplayViewControllerDelegate>

@property (nonatomic, readwrite, weak) IBOutlet UIScrollView *browserView;
@property (nonatomic, readwrite, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, readwrite, weak) IBOutlet UIView *spacerBarView;

+ (id) controller;
+ (id) controllerWithPredicate: (NSPredicate *) predicate andTabBarItem: (UITabBarItem *) item tableColor: (UIColor *) tableColor;

@end
