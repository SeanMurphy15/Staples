//
//  LeadSearchViewController.h
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface LeadSearchViewController : UIViewController <UIPopoverControllerDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak)   IBOutlet UISegmentedControl  *segmentedControl;
@property (nonatomic, weak)   IBOutlet UITableView         *leadsTableView;
@property (nonatomic, strong) IBOutlet UISearchBar         *searchBar;
@property (nonatomic, weak)   IBOutlet UIButton            *deferButton;
@property (nonatomic)         BOOL                          showsDeferButton;

+ (UIPopoverController*) popOverFromBarButtonItem: (UIBarButtonItem *) item;
+ (UIPopoverController*) popOverFromButton: (UIButton *) item;
+ (void) dismissPopover;

- (IBAction) deferSelection: (id) sender;

@end
