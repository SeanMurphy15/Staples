//
//  DSA_FeaturedItemsViewController.h
//  DSA
//
//  Created by Mike McKinley on 3/14/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_MediaDisplayViewController.h"

@interface DSA_FeaturedItemsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DSA_MediaDisplayViewControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSArray *featuredContentArray;
@property (strong, nonatomic) NSArray *updatedContentArray;
@property (assign, nonatomic) BOOL presentingViewMenu;

@property (weak, nonatomic) IBOutlet UITableView *spotlightTableView;

@end
