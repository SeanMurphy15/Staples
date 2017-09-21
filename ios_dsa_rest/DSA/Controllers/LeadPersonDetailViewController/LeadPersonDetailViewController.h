//
//  LeadPersonDetailViewController.h
//  DSA
//
//  Created by Jason Barker on 4/29/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@class LeadController;



@interface LeadPersonDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) LeadController *leadController;
@property (nonatomic, weak) IBOutlet UITableView *detailsTableView;

@end
