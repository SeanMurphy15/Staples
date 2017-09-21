//
//  DSA_SyncProgressViewController.h
//  DSA
//
//  Created by Mike McKinley on 3/19/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSA_SyncProgressImageView;
@class DSA_SyncProgressViewController;

@protocol DSA_SyncProgressViewControllerDelegate <NSObject>
- (void)syncProgressControllerDidFinish:(DSA_SyncProgressViewController*)controller;
@end

#pragma mark -

@interface DSA_SyncProgressViewController : UIViewController

@property (assign, nonatomic) CGFloat nibHeight, nibWidth;
@property (weak, nonatomic) id<DSA_SyncProgressViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL updatingMetaData;

@property (weak, nonatomic) IBOutlet UIView *innerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *overallProgressView;
@property (weak, nonatomic) IBOutlet UILabel *stepOneLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepTwoLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepThreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *stepFourLabel;
@property (weak, nonatomic) IBOutlet DSA_SyncProgressImageView *stepOneImageView;
@property (weak, nonatomic) IBOutlet DSA_SyncProgressImageView *stepTwoImageView;
@property (weak, nonatomic) IBOutlet DSA_SyncProgressImageView *stepThreeImageView;
@property (weak, nonatomic) IBOutlet DSA_SyncProgressImageView *stepFourImageView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailDownloadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailTotalLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailRateLabel;

- (IBAction)cancelTouched:(id)sender;
- (IBAction)doubleTapRecognized:(id)sender;

- (void)noticeSyncInterupted:(NSNotification*)note;

@end


