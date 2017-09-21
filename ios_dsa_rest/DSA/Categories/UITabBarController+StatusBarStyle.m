//
//  UINavigationController+StatusBarStyle.m
//  DSA
//
//  Created by Mike McKinley on 3/17/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

@implementation UITabBarController (StatusBarStyle)

-(UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

-(UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

@end