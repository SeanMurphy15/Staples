//
//  UINavigationController+StatusBarStyle.m
//  DSA
//
//  Created by Mike McKinley on 3/17/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

@implementation UINavigationController (StatusBarStyle)

-(UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

-(UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

@end