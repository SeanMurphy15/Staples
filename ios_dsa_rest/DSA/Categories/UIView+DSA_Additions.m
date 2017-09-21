//
//  UIView+SFDCAdditions.m
//  McGraw Hill
//
//  Created by Cory Wiles on 7/19/13.
//  Copyright (c) 2013 Model Metrics. All rights reserved.
//

#import "UIView+DSA_Additions.h"

#import <objc/runtime.h>

static char kDSAActionHandlerTapBlockKey;
static char kDSAActionHandlerTapGestureKey;
static char kDSAActionHandlerLongPressBlockKey;
static char kDSAActionHandlerLongPressGestureKey;

@implementation UIView (DSA_Additions)

- (void)setTapActionWithBlock:(DSA_UIViewGestureComplectionBlock)block {
  
	UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kDSAActionHandlerTapGestureKey);
  
	if (!gesture) {
    
		gesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                          action:@selector(__handleActionForTapGesture:)];
    
        [self addGestureRecognizer:gesture];
    
        objc_setAssociatedObject(self, &kDSAActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
    }
  
	objc_setAssociatedObject(self, &kDSAActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)setLongPressActionWithBlock:(DSA_UIViewGestureComplectionBlock)block {
  
	UILongPressGestureRecognizer *gesture = objc_getAssociatedObject(self, &kDSAActionHandlerLongPressGestureKey);
  
	if (!gesture) {
    
		gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(__handleActionForLongPressGesture:)];
    
        [self addGestureRecognizer:gesture];
    
        objc_setAssociatedObject(self, &kDSAActionHandlerLongPressGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
    }
  
	objc_setAssociatedObject(self, &kDSAActionHandlerLongPressBlockKey, block, OBJC_ASSOCIATION_COPY);
}

#pragma mark - Private Methods

- (void)__handleActionForTapGesture:(UITapGestureRecognizer *)gesture {
  
	if (gesture.state == UIGestureRecognizerStateRecognized) {
    
        void(^action)(void) = objc_getAssociatedObject(self, &kDSAActionHandlerTapBlockKey);
    
		if (action) {
			action();
        }
    }
}

- (void)__handleActionForLongPressGesture:(UITapGestureRecognizer *)gesture {
  
	if (gesture.state == UIGestureRecognizerStateBegan) {
    
		void(^action)(void) = objc_getAssociatedObject(self, &kDSAActionHandlerLongPressBlockKey);
    
		if (action) {
			action();
        }
   }
}

@end
