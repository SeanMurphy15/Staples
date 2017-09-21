//
//  DSA_SyncProgressImageView.m
//  DSA
//
//  Created by Mike McKinley on 3/27/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_SyncProgressImageView.h"

@interface DSA_SyncProgressImageView ()
@property(assign,nonatomic) BOOL rotating;
@end

@implementation DSA_SyncProgressImageView

- (void)oneLastRotation {
    // one last rotation
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^ {
        self.transform = CGAffineTransformRotate(self.transform, M_PI/2);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
        self.image = [UIImage imageNamed:@"sync-step-done.png"];
    }];
}

- (void) rotateWithAnimationOptions:(UIViewAnimationOptions)options {
    [UIView animateWithDuration:0.5 delay:0 options:options animations:^ {
        // one rotation every 2 seconds
        self.transform = CGAffineTransformRotate(self.transform, M_PI/2);
    } completion:^ (BOOL finished) {
         if (finished) {
             if (self.rotating) {
                 // still rotating
                 [self rotateWithAnimationOptions:UIViewAnimationOptionCurveLinear];
             } else { //if (options != UIViewAnimationOptionCurveEaseOut) {
                 self.transform = CGAffineTransformIdentity;
                 self.image = [UIImage imageNamed:@"sync-step-done.png"];
                 [self.layer removeAllAnimations];
             }
         }
     }];
}

- (void)startRotating {
    if (!self.layer.animationKeys) {
    //if (!self.rotating) {
        self.rotating = YES;
        [self rotateWithAnimationOptions:UIViewAnimationOptionCurveEaseIn];
    }
}

- (void)setSyncState:(DSA_SyncProgressState)syncState {
    if (_syncState == DSA_SyncProgressState_Finished) { return; }
    
    _syncState = syncState;
    
    switch (syncState) {
        default:
        case DSA_SyncProgressState_Waiting:
            self.image = [UIImage imageNamed:@"sync-step-waiting.png"];
            self.transform = CGAffineTransformIdentity;
            self.rotating = NO;
            break;
            
        case DSA_SyncProgressState_Syncing:
            self.image = [UIImage imageNamed:@"sync-step-progress.png"];
            [self startRotating];
            break;
            
        case DSA_SyncProgressState_Finished:
            if(!self.rotating) {
               self.image = [UIImage imageNamed:@"sync-step-done.png"];
            }
            self.rotating = NO;
            break;
    }
}

@end
