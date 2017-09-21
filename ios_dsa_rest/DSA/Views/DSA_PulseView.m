//
//  MSPulse.m
//  Pulse
//
//  Created by Cory D. Wiles on 9/25/13.
//  Copyright (c) 2013 Cory D. Wiles. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DSA_PulseView.h"
#import "DSA_RemoteObjectStatusClient.h"

static NSString * const DSA_PulseViewAnimationKeyPath = @"transform.rotation";
static NSString * const DSA_PulseViewAnimationKey     = @"animateTransformScale";

@interface DSA_PulseView()

@property (nonatomic, strong) CABasicAnimation *animation;

@end

@implementation DSA_PulseView

- (void)preparePulseView {
    self.backgroundColor        = [UIColor clearColor];
    self.alpha                  = [DSA_RemoteObjectStatusClient hasBeenNotifed] ? 0.35f : 0.0f;
    self.image                  = [UIImage imageNamed:@"sync_button"];
    self.userInteractionEnabled = YES;
    
    _animation = [CABasicAnimation animationWithKeyPath:DSA_PulseViewAnimationKeyPath];
    
    _animation.duration     = 0.65;
    _animation.repeatCount  = FLT_MAX;
    _animation.fromValue    = @0.0;
    _animation.toValue      = @(2 * M_PI);
    _animation.delegate     = self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self preparePulseView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self preparePulseView];
    }
    return self;
}

- (void)startAnimation {
    self.alpha = 0.35;
    [self.layer addAnimation:self.animation forKey:DSA_PulseViewAnimationKey];
}

- (void)stopAnimation {
    [self.layer removeAllAnimations];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.alpha = 0.0f;
}

@end
