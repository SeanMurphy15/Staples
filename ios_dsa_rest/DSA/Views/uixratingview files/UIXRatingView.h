//
//  UIXRatingView.h
//  uixratingview
//
//  Copyright 2011 Umbright Consulting, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class UIXRatingView;

@protocol UIXRatingViewDelegate

- (void) ratingView:(UIXRatingView*) ratingView ratingChanged:(NSInteger) newRating;

@end

@interface UIXRatingView : UIView 
{
    
    CGFloat indicatorWidth;
    CGFloat indicatorHeight;
    
    NSInteger transformedViewIndex;
    
}

@property (nonatomic, strong) UIImage* unselectedImage;
@property (nonatomic, strong) UIImage* selectedImage;
@property (nonatomic, assign) NSUInteger numberOfElements;
@property (nonatomic, assign) NSInteger rating;
@property (nonatomic, unsafe_unretained) NSObject<UIXRatingViewDelegate>* delegate;
@property (nonatomic, strong) NSMutableArray* indicators;

- (id) initWithNumberOfElements: (NSUInteger) numElements 
                  selectedImage: (UIImage*) selectedImg
                unselectedImage: (UIImage*) unselectedImg;

@end
