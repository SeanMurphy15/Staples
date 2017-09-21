//
//  EmailSubjectController.h
//  DSA
//
//  Created by Adam Walters on 9/6/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmailSubjectControllerDelegate

- (void)emailSubjectSelected:(NSString *)subject;
- (void)emailSubjectCanceled;

@end

@interface EmailSubjectController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id<EmailSubjectControllerDelegate> delegate;

+ (EmailSubjectController *)creaetEmailSubjectController;
- (IBAction)cancelTapped:(id)sender;

@end
