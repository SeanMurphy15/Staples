//
//  MeetingDetailsViewController.h
//  DSA
//
//  Created by Jason Barker on 5/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface MeetingDetailsViewController : UIViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *notesPlaceholderLabel;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;

@property (weak, nonatomic) IBOutlet UISwitch *accountingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *accountManagementSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *customerServiceSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *invoicingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *multipleVendorsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *orderingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *placementMethodSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *pricingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *procurementSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *productAssortmentSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *reportingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *shippingReceivingSwitch;

+ (void) resetMeetingNotes;
- (IBAction) flippedSwitch: (id) sender;

@end
