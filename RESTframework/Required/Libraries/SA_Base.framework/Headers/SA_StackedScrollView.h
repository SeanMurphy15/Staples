//
//  SA_StackedScrollView.h
//
//  Created by Ben Gottlieb on 8/11/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SA_StackedScrollView;

@protocol SA_StackedScrollViewDelegate <NSObject>
@optional
- (void) stackedScrollView: (SA_StackedScrollView *) view didSelectRowAtIndexPath: (NSIndexPath *) path;
- (void) scrollViewDidScroll: (SA_StackedScrollView *) view;
@end

@interface SA_StackedScrollView : UITableView <UITableViewDataSource, UITableViewDelegate> {
	
}

@property (nonatomic, readwrite, weak) IBOutlet id <SA_StackedScrollViewDelegate> stackedScrollViewDelegate;
@property (nonatomic, readwrite, strong) NSMutableArray *componentViews;
@property (nonatomic) CGFloat indentationWidth;

- (void) addComponents: (UIView *) component, ...;
- (void) addComponentViews: (NSArray *) components;

- (void) addComponent: (UIView *) component animated: (BOOL) animated;
- (void) insertComponent: (UIView *) component atIndex: (NSUInteger) index animated: (BOOL) animated;
- (void) insertComponent: (UIView *) component afterComponent: (UIView *) prevComponent animated: (BOOL) animated;
- (void) replaceComponent: (UIView *) component atIndex: (NSUInteger) index animated: (BOOL) animated;
- (void) replaceExistingComponent: (UIView *) oldComponent withComponent: (UIView *) newComponent animated: (BOOL) animated;
- (void) removeComponentAtIndex: (NSUInteger) index animated: (BOOL) animated;
- (void) removeComponent: (UIView *) component animated: (BOOL) animated;
- (BOOL) isComponentInStack: (UIView *) component;
- (void) removeAllComponents;
- (void) addSpacer: (CGFloat) spacerHeight;

@end

@interface UIView (SA_StackedScrollView)
- (SA_StackedScrollView *) stackedScrollView;
@end