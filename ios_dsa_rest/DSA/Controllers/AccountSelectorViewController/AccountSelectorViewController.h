//
//  AccountSelectorViewController.h
//  DSA
//
//  Created by Jason Barker on 4/23/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@class ContactController;



@interface AccountSelectorViewController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *accountsTable;
@property (nonatomic, strong) ContactController *contactController;

@end
