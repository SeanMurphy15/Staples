//
//  ZM_ImprovedCarouselView.m
//  ModelMetrics
//
//  Created by Ben Gottlieb on 2/3/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "ZM_ImprovedCarouselView.h"
#import "ZM_CarouselCategoryView.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "ZM_CarouselScrollView.h"
#import "debugtools.h"

#define kScrollViewWidth 160
#define kScrollViewHeight 168

@interface ZM_ImprovedCarouselView ()

- (void) setup;
- (void) buildScrollViewContent;

@end


@implementation ZM_ImprovedCarouselView
@synthesize categoriesToDisplay, scrollView = _scrollView, isVertical = _isVertical, background, tick;

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark init methods

- (ZM_ImprovedCarouselView *) initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self setup];
	}
	
	return self;
}

- (ZM_ImprovedCarouselView *) initWithFrame:(CGRect)aFrame {

	if ((self = [super initWithFrame:aFrame])) {
		[self setup];
	}
	
	return self;
}

-(void)setup {
    _firstRun = YES;
    [self setClipsToBounds:YES];
    self.backgroundColor = [UIColor blackColor];
	self.scrollView = [[[ZM_CarouselScrollView alloc] initWithFrame:CGRectZero] autorelease];
	[self.scrollView setClipsToBounds:NO];
	[self.scrollView setPagingEnabled:YES];
	[self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator: NO];
	[self.scrollView setDelegate:self];
	[self addSubview:self.scrollView];	
    
	[[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector(didSelectSubcategory:) 
                                                 name: kNotification_CarouselDidTouchSubcategory 
                                               object: nil];
}

- (void) didSelectSubcategory: (NSNotification*) notification
{
    MMSF_Category__c* category = [notification object];
    _currentSelection = [self.categoriesToDisplay indexOfObject:category];
    /*
     * After the content is viewed for any subcategory we need to call this function to maintain the scaling of the scroll view's subviews.
     */

    [self scrollViewDidScroll:self.scrollView];

}

//=============================================================================================================================
#pragma mark Properties

//=============================================================================================================================
#pragma mark Actions
- (void) setCategories: (NSArray *) categories animated: (BOOL) animated {
#if CATEGORIES_ORDERED_ON
    ///////////////////////////////////////
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: @"Name" ascending: YES];
    self.categoriesToDisplay = [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Order__c") ascending:YES];
    
    NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Todays_Special__c") ascending:NO];
    
    
    self.categoriesToDisplay = [[self.categoriesToDisplay sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] 
                                sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor2]];
    /////////////////////////////////
#else
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: @"Name" ascending: YES];
    self.categoriesToDisplay = [categories sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
#endif
    _firstRun = YES;
    [self buildScrollViewContent];
    [self scrollViewDidScroll:self.scrollView];
    _firstRun = NO;
}

#pragma mark Touch event methods

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

	if ([self pointInside:point withEvent:event]) {
		return self.scrollView;
	}
	else {
		return nil;
	}

}
#pragma mark Scroll View Delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {

	CGPoint offset = aScrollView.contentOffset;
	MMLog(@"offset: %@", NSStringFromCGPoint(offset));
	for (ZM_CarouselCategoryView *view in aScrollView.subviews) {
		
		if ([view class] != [ZM_CarouselCategoryView class]) {
			continue;
		}
		
        if (self.isVertical) {
            CGFloat y = view.frame.origin.y;
            CGFloat delta = (offset.y - y) / 10;
            delta = (CGFloat)floorf(delta);
            delta = ABS(delta);
            delta = MIN(delta, 30);
            delta = MAX(delta, 0);
            view.innerView.frame = CGRectInset(view.originalFrame, delta, delta);

        }
        else {
            CGFloat x = view.frame.origin.x;
            CGFloat delta = (offset.x - x) / 10;
            delta = (CGFloat)floorf(delta);
            delta = ABS(delta);
            delta = MIN(delta, 30);
            delta = MAX(delta, 0);
            view.innerView.frame = CGRectInset(view.originalFrame, delta, delta);

        }

	}
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
	 for (ZM_CarouselCategoryView *view in aScrollView.subviews) {
		 
		 if ([view class] != [ZM_CarouselCategoryView class]) {
			 continue;
		 }
		 if (CGRectIntersectsRect(view.frame, aScrollView.bounds)) {
			 [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CarouselDidSelectSubcategory object:view.category];
             CGFloat contentSize = self.isVertical ? self.scrollView.frame.size.height : self.scrollView.frame.size.width;
             CGFloat contentOffset =  self.isVertical ? self.scrollView.contentOffset.y : self.scrollView.contentOffset.x;
             _currentSelection = contentOffset / contentSize; 
             if (_currentSelection < 0) {
                 _currentSelection = 0;
             }
		 }

	 }
	 
 }

#pragma mark Layout methods

-(void)layoutSubviews 
{
    if (self.isVertical) 
    {
        CGRect scrollViewFrame = CGRectMake(0, (self.bounds.size.height - kScrollViewHeight) / 2, kScrollViewWidth, kScrollViewHeight);
        if (!CGRectEqualToRect(self.scrollView.frame, scrollViewFrame)) 
               {
                  self.scrollView.frame = scrollViewFrame;
                  [self.scrollView scrollRectToVisible:[[self.scrollView viewWithTag:_currentSelection + 100] frame] animated:NO];
               }
    }
    else 
    {
        CGRect scrollViewFrame = CGRectMake((self.bounds.size.width - kScrollViewWidth) / 2 , 0, kScrollViewWidth, kScrollViewHeight);
               if (!CGRectEqualToRect(self.scrollView.frame, scrollViewFrame)) 
               {
                   self.scrollView.frame = scrollViewFrame;
                   [self.scrollView scrollRectToVisible:[[self.scrollView viewWithTag:_currentSelection + 100] frame] animated:NO];
               }
    }
}

- (void)setIsVertical:(BOOL)vertical {

    _isVertical = vertical;
    [self buildScrollViewContent];
    [self setNeedsLayout];
}

- (MMSF_Category__c *) currentSelectedCategory {
	return _currentSelection < self.categoriesToDisplay.count ? [self.categoriesToDisplay objectAtIndex: _currentSelection] : nil;
}

- (void)buildScrollViewContent {

    self.scrollView.frame = self.bounds; //GMU
    [self.scrollView removeAllSubviews];
    
    [self.background removeFromSuperview];
    NSString *filename = self.isVertical ? @"product-chooser-background-glow-vertical" : @"product-chooser-background-glow"; 
    self.background = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]] autorelease];
    self.background.frame = self.bounds;
    [self insertSubview:self.background belowSubview:self.scrollView];
    
    [self.tick removeFromSuperview];
    filename = self.isVertical ? @"product-chooser-tick-vertical" : @"product-chooser-tick";
    self.tick = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]] autorelease];
    
    self.tick.center = self.isVertical ? CGPointMake(0 + self.tick.bounds.size.width / 2 + 2, self.bounds.size.height / 2) : CGPointMake(self.bounds.size.width / 2, 0 + self.tick.bounds.size.height / 2);
    
    [self insertSubview:self.tick aboveSubview:self.scrollView];
    
    NSInteger count = [self.categoriesToDisplay count];
    if (count == 0) {
        return;
    }
    
    if (_firstRun) {
        NSInteger selection = 0;//(count > 1) ? count / 2 : count;
        NSArray* arr = self.categoriesToDisplay;
        MMSF_Category__c * category = [arr objectAtIndex:0];
        //SF_Category *category = selection > count ? [self.categoriesToDisplay objectAtIndex:selection] : nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CarouselDidSelectSubcategory object:category];
        _currentSelection = selection;
    }

    CGFloat delta = 0;
    for (NSInteger i = 0; i < [self.categoriesToDisplay count]; i++) {
        CGRect aFrame = self.isVertical ? CGRectMake(0, delta, kScrollViewWidth, kScrollViewHeight) : CGRectMake(delta, 0, kScrollViewWidth, kScrollViewHeight);
        ZM_CarouselCategoryView *view = [[ZM_CarouselCategoryView alloc] initWithFrame:aFrame];
        view.category = [self.categoriesToDisplay objectAtIndex:i];
        view.tag = i + 100;
        [self.scrollView addSubview:view];
        delta += self.isVertical ? kScrollViewHeight : kScrollViewWidth;
    }
    
    self.scrollView.contentSize = self.isVertical ? CGSizeMake(kScrollViewWidth, delta) : CGSizeMake(delta, kScrollViewHeight);
    self.scrollView.contentOffset = CGPointZero;
    
}

//////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////
- (void) setSelectedCategory:(MMSF_Category__c*)category 
{
    [self.scrollView selectCategory:category];
}

@end
