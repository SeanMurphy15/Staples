//
//  DSA_SettingsMenuViewController.h
//  ios_dsa
//
//  Created by Guy Umbright on 11/2/11.
//  Copyright (c) 2011 Kickstand Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#define SETTINGS_POPOVER_PRESENTED @"com.modelmetrics.dsa.settingspresented"
#define SETTINGS_POPOVER_DISMISSED @"com.modelmetrics.dsa.settingsdismissed"

@interface DSA_SettingsMenuViewController : UIViewController <UIPopoverControllerDelegate,
MFMailComposeViewControllerDelegate> {
    BOOL isAboutPressed;
}

@property (nonatomic, strong) IBOutlet UITableView* table;
@property (nonatomic, assign) BOOL canDismiss;

+ (DSA_SettingsMenuViewController *) controller;
+ (void) popOverFromBarButtonItem: (UIBarButtonItem *) item;
+ (void) popOverFromBarButtonItem: (UIBarButtonItem *) item dismissable:(BOOL) dismissable;

+ (void) popOverFromButton: (UIButton *) item;
+ (void) popOverFromButton: (UIButton *) item dismissable:(BOOL) dismissable;


- (void) buildMenu;

@end
