//
//  CheckinContactSelectorViewController.h
//  ios_dsa
//
//  Created by Guy Umbright on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RecentContacts.h"
#import "DSA_AppDelegate.h"

#define CHECKIN_POPOVER_PRESENTED @"com.modelmetrics.dsa.checkinpresented"
#define CHECKIN_POPOVER_DISMISSED @"com.modelmetrics.dsa.checkindismissed"

@interface CheckinContactSelectorViewController : UIViewController <UIPopoverControllerDelegate, UITextFieldDelegate,UISearchBarDelegate>

//@property (nonatomic, strong) IBOutlet UITextField* searchField; //???
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UISegmentedControl* listSelector;  //???
@property (nonatomic, strong) IBOutlet UIButton* addButton;  //???
@property (nonatomic, strong) IBOutlet UIButton* chooseLaterButton;

@property (nonatomic, assign) BOOL checkoutMode;
@property (nonatomic, assign) BOOL hideChooseLaterButton;

@property (nonatomic, strong) NSManagedObjectContext *moc;

+ (UIPopoverController*) popOverFromBarButtonItem: (UIBarButtonItem *) item;
+ (UIPopoverController*) popOverFromButton: (UIButton *) item;
+ (void) dismissPopover;
+ (CheckinContactSelectorViewController *) controller;

@end
