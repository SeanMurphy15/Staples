//
//  SA_LazyLoadingScrollView.m
//
//  Created by Ben Gottlieb on 5/25/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SA_LazyLoadingScrollView, SA_LazyLoadingScrollViewPage;

@protocol SA_LazyLoadingScrollViewDataSource <NSObject>
- (NSInteger) numberOfPagesInScrollView: (SA_LazyLoadingScrollView *) lazyLoadingScrollView;
- (SA_LazyLoadingScrollViewPage *) pageViewAtIndex: (NSInteger) index;
@optional
- (void) configurePageView: (SA_LazyLoadingScrollViewPage *) pageView forIndex: (NSInteger) index;
- (void) scrollView: (SA_LazyLoadingScrollView *) scrollView didChangeMainIndexTo: (NSInteger) index;
@end



@interface SA_LazyLoadingScrollView : UIScrollView <UIScrollViewDelegate> {
}

@property (nonatomic, readwrite, weak) IBOutlet id <SA_LazyLoadingScrollViewDataSource> dataSource;
@property (nonatomic, readwrite, strong) NSMutableSet *unusedPageViews, *visiblePageViews;
@property (nonatomic, readwrite) NSInteger mainPageIndex;
@property (nonatomic, readonly) SA_LazyLoadingScrollViewPage *mainPageView;
@property (nonatomic) CGFloat interPageSpacing, pageWidth;
@property (nonatomic, readonly) NSInteger numberOfVisiblePageViews;

- (id) dequeueReusablePageViewWithClass:(Class) pageViewClass;

- (void) reloadData;
- (void) updateContentOffset;
- (SA_LazyLoadingScrollViewPage *) visiblePageViewAtIndex: (NSInteger) index;
- (void) setMainPageIndex: (NSInteger) index animated:(BOOL) animated;
- (void) hideOffscreenPagesForRotation;
- (void) scrollViewDidScroll: (UIScrollView *) scrollView;
@end



@interface SA_LazyLoadingScrollViewPage : UIView {
}

@property (nonatomic, readwrite, strong) id representedObject;
@property (nonatomic, readwrite) NSInteger pageIndex;
@property (nonatomic, readwrite) BOOL isMainPageView;
@property (nonatomic, readonly) CGRect contentFrame, visibleBounds;

@end
