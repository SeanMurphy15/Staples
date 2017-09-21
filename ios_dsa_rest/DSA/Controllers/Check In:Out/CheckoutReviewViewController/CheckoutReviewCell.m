//
//  CheckoutReviewCell.m
//  ios_dsa
//
//  Created by Guy Umbright on 9/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CheckoutReviewCell.h"
#import <MessageUI/MessageUI.h>
#import "MMSF_ContentVersion.h"
#import "Branding.h"

@implementation CheckoutReviewCell

//////////////////////////////////////////////
//
//////////////////////////////////////////////
- (void) awakeFromNib {
	self.rating.delegate = self;
    [self.emailSwitch setOnTintColor: [Branding blueColor]];
	self.rating.unselectedImage.accessibilityLabel = @"Unselected Star Rating Image";
}

//////////////////////////////////////////////
//
//////////////////////////////////////////////
- (void) displayDocumentHistory:(DocumentHistory*) docHist {
    self.rating.selectedImage = [UIImage imageNamed:@"star_on"];
    self.rating.unselectedImage = [UIImage imageNamed:@"star_off"];
    self.rating.numberOfElements = 5;

    self.documentHistory = docHist;
    
    MMSF_ContentVersion* contentItem = [MMSF_ContentVersion contentItemBySalesforceId:docHist.salesforceId];
    self.documentTitle.text = contentItem.Title;
    
    self.rating.rating = docHist.rating;
    
    NSDateComponents* dc = [[NSDateComponents alloc] init];
    [dc setSecond:docHist.totalSecondsViewed];
    NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:dc];

    dc = [[NSCalendar currentCalendar] components:NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit fromDate:date];
    
    NSMutableString* fmt = [NSMutableString stringWithString:@"'Duration:' "];
    
    if ([dc hour] > 0){
        [fmt appendString:@"h 'hrs.' "];
    }
    
    CGSize thumbSize = CGSizeMake(80.f, 80.f);
    __weak typeof(self) weakSelf = self;
    [contentItem generateThumbnailSize:thumbSize completionBlock:^(UIImage *image) {
        weakSelf.thumbnail.image = image;
    }];
    self.documentType.image = contentItem.tableCellImage;
    
    if (self.thumbnail.image == nil)
    {
        // no thumbnail available
        self.thumbnail.image = contentItem.tableCellImage;
        self.thumbnail.contentMode = UIViewContentModeCenter;
    }
    
    if ([MFMailComposeViewController canSendMail]) {
        if (contentItem.canEmail) {
            self.emailSwitchLabel.hidden = NO;
            self.emailSwitch.hidden = NO;
            self.restrictedView.hidden = YES;
            self.emailSwitch.on = docHist.markedToSend;
        }
        else {
            self.emailSwitch.hidden = YES;
            self.emailSwitchLabel.hidden = YES;
            self.restrictedView.hidden = NO;
        }
    }
    else {
        self.emailSwitchLabel.hidden = YES;
        self.emailSwitch.hidden = YES;
    }
}


- (void) ratingView:(UIXRatingView*) ratingView ratingChanged:(NSInteger) newRating {
    self.documentHistory.rating = newRating;
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_DocumentWasRated object: self.documentHistory];
}

//////////////////////////////////////////////
//
//////////////////////////////////////////////
- (IBAction) emailSwitchChanged:(UISwitch*) sender {
    self.documentHistory.markedToSend = sender.on;
}

@end
