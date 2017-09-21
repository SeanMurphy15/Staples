//
//  UIView+DSA_Additions.h
//
//  Created by Cory Wiles on 7/19/13.
//  Copyright (c) 2013 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^DSA_UIViewGestureComplectionBlock)();

/**
 * Provides additional convienence methods for UIView classes.
 */

@interface UIView (DSA_Additions)

/**
 * Sets void block to execute when any UIView class/subclass is tapped.
 * Delegate methods aren't called.
 *
 * @param typedef block
 */

- (void)setTapActionWithBlock:(DSA_UIViewGestureComplectionBlock)block;

/**
 * Sets void block to execute when any UIView class/subclass is long pressed.
 * Delegate methods aren't called.
 *
 * @param typedef block
 */

- (void)setLongPressActionWithBlock:(DSA_UIViewGestureComplectionBlock)block;

@end
