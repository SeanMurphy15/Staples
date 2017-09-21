//
//  CreateContactViewController.h
//  DSA
//
//  Created by Jason Barker on 4/24/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@class ContactController;



@interface CreateContactViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *accountNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountNumberLabel;
@property (weak, nonatomic) IBOutlet UITableView *detailsTableView;

@property (nonatomic, strong) ContactController *contactController;

@end
