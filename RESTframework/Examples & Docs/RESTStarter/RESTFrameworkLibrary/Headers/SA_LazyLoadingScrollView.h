//
//  SA_LazyLoadingScrollView.m
//
//  Created by Ben Gottlieb on 5/25/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SA_LazyLoadingScrollView, SA_LazyLoadingScrollViewPage;

@protocol SA_LazyLoadingScrollViewDataSource <NSObject>
- (NSUInteger) numberOfPagesInScrollView: (SA_LazyLoadingScrollView *) lazyLoadingScrollView;
- (SA_LazyLoadingScrollViewPage *) pageViewAtIndex: (NSUInteger) index;
@optional
- (void) configurePageView: (SA_LazyLoadingScrollViewPage *) pageView forIndex: (NSUInteger) index;
- (void) scrollView: (SA_LazyLoadingScrollView *) scrollView didChangeMainIndexTo: (NSUInteger) index;
@end



@interface SA_LazyLoadingScrollView : UIScrollView <UIScrollViewDelegate> {
}

@property (nonatomic, readwrite, weak) IBOutlet id <SA_LazyLoadingScrollViewDataSource> dataSource;
@property (nonatomic, readwrite, strong) NSMutableSet *unusedPageViews, *visiblePageViews;
@property (nonatomic, readwrite) NSUInteger mainPageIndex;
@property (nonatomic, readonly) SA_LazyLoadingScrollViewPage *mainPageView;
@property (nonatomic) CGFloat interPageSpacing, pageWidth;
@property (nonatomic, readonly) NSUInteger numberOfVisiblePageViews;

- (id) dequeueReusablePageViewWithClass:(Class) pageViewClass;

- (void) reloadData;
- (void) updateContentOffset;
- (SA_LazyLoadingScrollViewPage *) visiblePageViewAtIndex: (NSUInteger) index;
- (void) setMainPageIndex: (NSUInteger) index animated:(BOOL) animated;
- (void) hideOffscreenPagesForRotation;
- (void) scrollViewDidScroll: (UIScrollView *) scrollView;
@end



@interface SA_LazyLoadingScrollViewPage : UIView {
}

@property (nonatomic, readwrite, strong) id representedObject;
@property (nonatomic, readwrite) NSUInteger pageIndex;
@property (nonatomic, readwrite) BOOL isMainPageView;
@property (nonatomic, readonly) CGRect contentFrame, visibleBounds;

@end
