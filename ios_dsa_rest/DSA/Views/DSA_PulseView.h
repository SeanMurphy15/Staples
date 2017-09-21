//
//  MSPulse.h
//  Pulse
//
//  Created by Cory D. Wiles on 9/25/13.
//  Copyright (c) 2013 Cory D. Wiles. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * DSA_PulseView provides reusable "red circle" view for user notifications.
 */

@interface DSA_PulseView : UIImageView

/**
 * Explicitly starts CABaseAnimation for "pulse", but will only repeat
 * 5 times.
 */

- (void)startAnimation;

/**
 * Explicitly removes all animations from view layer
 */

- (void)stopAnimation;

@end
