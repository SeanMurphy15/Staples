//
//  RequiredInfoCell.m
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "RequiredInfoCell.h"
#import "Branding.h"


@implementation RequiredInfoCell


/**
 *
 */
- (void) setRequiredState: (RequiredState) requiredState {
    
    _requiredState = requiredState;
    [self configureRequiredIndicatorView];
}


/**
 *
 */
- (void) setRequiredState: (RequiredState) requiredState animated: (BOOL) animated {
    
    if (animated)
        [UIView animateWithDuration: 0.3 animations: ^{ [self setRequiredState: requiredState]; }];
    else
        [self setRequiredState: requiredState];
    
}


/**
 *
 */
- (void) configureRequiredIndicatorView {
    
    UIColor *color = [UIColor clearColor];
    
    if (_requiredState == RequiredStateRequiredButNotValidated)
        color = [Branding redColor];
    else if (_requiredState == RequiredStateRequiredAndValidated)
        color = [UIColor lightGrayColor];
    
    [self.requiredIndicatorView setBackgroundColor: color];
}

@end
