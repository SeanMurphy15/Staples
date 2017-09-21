//
//  UIGestureRecognizer+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 7/17/12.
//
//

#import <UIKit/UIKit.h>

typedef void (^gestureArgumentBlock)(UIGestureRecognizer *recog);


@interface UIGestureRecognizer (SA_SA_Additions)
@property (nonatomic, readonly) UIView *SA_touchedView;

- (id) initWithSA_Block: (gestureArgumentBlock) block;
+ (id) SA_longPressRecognizerWithPressBlock: (gestureArgumentBlock) block;
@end
