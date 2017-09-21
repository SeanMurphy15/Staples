//
//  ZM_SearchViewController.h
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ZM_SearchViewController : UIViewController {

}

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UIImageView *headerImage;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UISegmentedControl *searchScopeControl;


+ (id) controller;

- (void) updateForOrientation: (UIInterfaceOrientation) newOrientation;
@end
