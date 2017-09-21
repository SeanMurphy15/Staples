//
//  CheckoutReviewCell.h
//  ios_dsa
//
//  Created by Guy Umbright on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIXRatingView.h"
#import "DocumentTracker.h"

#define kNotification_DocumentWasRated			@"kNotification_DocumentWasRated"

@interface CheckoutReviewCell : UITableViewCell <UIXRatingViewDelegate>

@property (nonatomic, strong) IBOutlet UIImageView* thumbnail;
@property (nonatomic, strong) IBOutlet UILabel* documentTitle;
@property (nonatomic, strong) IBOutlet UIXRatingView* rating;
@property (nonatomic, strong) IBOutlet UIImageView* documentType;
@property (nonatomic, strong) IBOutlet UISwitch* emailSwitch;
@property (nonatomic, strong) IBOutlet UILabel* emailSwitchLabel;
@property (nonatomic, strong) IBOutlet UIView* restrictedView;
@property (nonatomic, weak) DocumentHistory* documentHistory;  //???

- (void) displayDocumentHistory:(DocumentHistory*) docHist;

- (IBAction) emailSwitchChanged:(UISwitch*) sender;

@end
