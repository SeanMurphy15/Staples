//
//  CheckoutReviewViewController.h
//  ios_dsa
//
//  Created by Guy Umbright on 9/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DocumentTracker.h"

#define kCheckoutDone @"com.modelmetrics.dsaapp.checkoutDone"
#define kCheckoutCanceled @"com.modelmetrics.dsaapp.checkoutCanceled"
#define kContactSelectedAtCheckout @"com.modelmetrics.dsaapp.contactSelectedAtCheckout"

#define CHECKOUT_POPOVER_PRESENTED @"com.modelmetrics.dsa.checkoutpresented"
#define CHECKOUT_POPOVER_DISMISSED @"com.modelmetrics.dsa.checkoutdismissed"

@interface CheckoutReviewViewController : UITableViewController <UITextViewDelegate>

+ (void) popOverFromBarButtonItem: (UIBarButtonItem *) item; 
+ (void) popOverFromButton: (UIButton *) button;
+ (void) dismissPopover;

@property (nonatomic) BOOL allDocumentsRated;

@end
