//
//  UIViewController+SA_Additions.h
//
//  Created by Ben Gottlieb on 8/8/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	viewControllerAnimationDirection_none,
	viewControllerAnimationDirection_left,
	viewControllerAnimationDirection_right,
	viewControllerAnimationDirection_top,
	viewControllerAnimationDirection_bottom,
	viewControllerAnimationDirection_dropDown,
	viewControllerAnimationDirection_fadeIn
} UIViewControllerAnimationDirection;

@interface UIViewController (UIViewController_SA_Additions)
@property (nonatomic, readonly) UIViewController *focusedViewControllerAncestor;

+ (id) simpleController;

- (NSSet *) childControllers;

- (void) slideViewController: (UIViewController *) controller inToView: (UIView *) view fromDirection: (UIViewControllerAnimationDirection) direction withBounce: (BOOL) bounce;
- (void) slideViewController: (UIViewController *) controller outTowardsDirection: (UIViewControllerAnimationDirection) direction;
- (void) removeAllChildViewControllers;
- (void) addFullSizeChildViewController: (UIViewController *) controller;
- (void) addChildViewController: (UIViewController *) controller withViewInFrame: (CGRect) frame;
- (void) removeFromParentViewControllerAndView;
@end


@interface UINavigationController (UINavigationController__SA_Additions)
@property (nonatomic, readonly) UIViewController *rootViewController;
@end

@interface SA_ViewController : UIViewController
+ (UIViewController *) frontmostFocusedViewController;

- (BOOL) canBeFrontmostFocusedViewController;
@end

@interface SA_TableViewController : UITableViewController
@end