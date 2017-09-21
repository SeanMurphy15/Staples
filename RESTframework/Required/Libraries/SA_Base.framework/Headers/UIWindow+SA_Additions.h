//
//  UIWindow+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 5/26/14.
//
//

#import <UIKit/UIKit.h>

@interface UIWindow (SA_Additions)

+ (CGAffineTransform) sa_transformForUserInterfaceOrientation: (UIInterfaceOrientation) orientation;
+ (CGAffineTransform) sa_transformForCurrentUserInterfaceOrientation;

+ (UIWindow *) sa_fullScreenWindowWithBaseView: (UIView *) baseView;
+ (CGAffineTransform) sa_baseTransformForOrientation: (UIInterfaceOrientation) orientation;
@end
