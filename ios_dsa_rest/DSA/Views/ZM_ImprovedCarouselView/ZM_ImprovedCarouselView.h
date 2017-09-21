//
//  ZM_ImprovedCarouselView.h
//  ModelMetrics
//
//  Created by Ben Gottlieb on 2/3/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_Category__c.h"


@class ZM_CarouselScrollView;
@interface ZM_ImprovedCarouselView : UIView <UIScrollViewDelegate> {
	
	ZM_CarouselScrollView *_scrollView;
    BOOL _isVertical;
    BOOL _firstRun;
    CGFloat _currentSelection;

}

@property (nonatomic, readwrite, strong) NSArray *categoriesToDisplay;	
@property (nonatomic, readwrite, strong) ZM_CarouselScrollView *scrollView;
@property (nonatomic, readwrite, assign) BOOL isVertical;
@property (unsafe_unretained, nonatomic, readonly) MMSF_Category__c *currentSelectedCategory;  //???
@property (nonatomic, readwrite, strong) UIImageView *background;
@property (nonatomic, strong) UIImageView *tick;
- (void) setCategories: (NSArray *) categories animated: (BOOL) animated;

- (void) setSelectedCategory:(MMSF_Category__c*) category;
@end
