//
//  RequiredInfoCell.h
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef NS_ENUM(NSInteger, RequiredState) {
    RequiredStateNotRequired,
    RequiredStateRequiredButNotValidated,
    RequiredStateRequiredAndValidated
};



@interface RequiredInfoCell : UITableViewCell

@property (nonatomic) RequiredState requiredState;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextField *valueTextField;
@property (nonatomic, weak) IBOutlet UIView *requiredIndicatorView;

- (void) setRequiredState: (RequiredState) requiredState animated: (BOOL) animated;

@end
