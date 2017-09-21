//
//  UIScrollView+SA_Additions.h
//
//  Created by Ben Gottlieb on 10/5/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIScrollView (SA_Additions)

//@property (nonatomic, readonly) BOOL isAdjustedForKeyboard;
//
//- (void) setupForKeyboardEditing;
//- (void) endKeyboardEditing;
//- (void) showNewFirstResponder: (UIView *) newResponder;
- (CGRect) SA_visibleContentFrame;
@end
