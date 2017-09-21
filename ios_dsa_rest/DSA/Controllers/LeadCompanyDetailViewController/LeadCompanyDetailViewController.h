//
//  LeadCompanyDetailViewController.h
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@class LeadController;



@interface LeadCompanyDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) LeadController *leadController;
@property (nonatomic, weak) IBOutlet UITableView *detailsTableView;

+ (NSArray *) companyInfoFieldNames;

- (void) setDefaultsForLeadController: (LeadController *) leadController;
+ (NSArray *) sortFields: (NSArray *) fields withOrder: (NSArray *) order;

@end
