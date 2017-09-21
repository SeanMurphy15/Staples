//
//  UIXRatingView.m
//  uixratingview
//
//  Copyright 2011 Umbright Consulting, Inc. All rights reserved.
//

#import "UIXRatingView.h"


@implementation UIXRatingView

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (NSString*) description
{
    return [NSString stringWithFormat:@"rating=%d numberOfElements=%u selectedImage=%@ unselectedImage=%@",self.rating,self.numberOfElements,self.selectedImage,self.unselectedImage];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) calculateGeometry
{
    indicatorWidth = (self.selectedImage.size.width < 44) ? 44 : self.selectedImage.size.width;
    indicatorHeight = (self.selectedImage.size.height < 44) ? 44 : self.selectedImage.size.height;;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) commonInitialization
{
    self.rating = 0;
    transformedViewIndex = -1;
    self.indicators = nil;
    self.backgroundColor = [UIColor clearColor];
    [self calculateGeometry];
}


///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (id) initWithNumberOfElements: (NSUInteger) numElements 
                  selectedImage: (UIImage*) selectedImg
                unselectedImage: (UIImage*) unselectedImg
{
    self = [self initWithFrame:CGRectZero];
    if (self != nil)
    {

        self.unselectedImage = unselectedImg;
        self.selectedImage = selectedImg;
        self.numberOfElements = numElements;
        [self commonInitialization];
        
//        [self setNeedsLayout];
    }
    
    return self;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) awakeFromNib
{
    [self commonInitialization];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) clearIndicators
{
    for (UIView* v in self.indicators)
    {
        [v removeFromSuperview];
    }
    
    self.indicators = nil;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (NSMutableArray*) indicators
{
    if (_indicators == nil && self.numberOfElements != 0)
    {
        _indicators = [NSMutableArray arrayWithCapacity:self.numberOfElements];
        
        for (NSInteger ndx=0; ndx < self.numberOfElements; ++ndx)
        {
            UIImageView* iv = [[UIImageView alloc] initWithImage:self.unselectedImage];
            iv.userInteractionEnabled = NO;
            iv.contentMode = UIViewContentModeCenter;
            
            CGRect r = CGRectMake(ndx, 0, indicatorWidth, indicatorHeight);
            iv.frame = r;
            [self addSubview:iv];
            [_indicators addObject:iv];
        }
    }
    
    return _indicators;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) layoutSubviews
{
    CGRect rect;
    
    [self calculateGeometry];

    rect.origin = self.frame.origin;
    rect.size.width = indicatorWidth * self.numberOfElements;
    rect.size.height = indicatorHeight;
    self.frame = rect;
    
    for (NSInteger ndx=0; ndx < self.numberOfElements; ++ndx)
    {
        UIImageView* iv = [[self indicators] objectAtIndex:ndx];
        CGRect r = CGRectMake(indicatorWidth * ndx, 0, indicatorWidth, indicatorHeight);
        iv.frame = r;
    }
}


///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) updateDisplayForRating
{
    for (NSInteger ndx = 0; ndx < self.numberOfElements; ++ndx)
    {
        UIImageView* iv = [[self indicators] objectAtIndex:ndx];
        
        if (self.rating < 0)
        {
            iv.image = self.unselectedImage;
        }
        else
        {
            if (ndx <= self.rating-1)
            {
                iv.image = self.selectedImage;
                [iv setNeedsDisplay];
            }
            else
            {
                iv.image = self.unselectedImage;
                [iv setNeedsDisplay];
            }
        }
    }
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) transformViewAtIndex:(NSInteger) index
{
    CGAffineTransform transform;
    if (index != transformedViewIndex)
    {
        if (transformedViewIndex >= 0)
        {
            UIView* v = [[self indicators] objectAtIndex:transformedViewIndex];
            v.transform = CGAffineTransformIdentity;
            transformedViewIndex = -1;
        }
        
        if (index >= 0)
        {
            //apply new
            transformedViewIndex = index;
            transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.2, 1.2);
            UIView* v = [[self indicators] objectAtIndex:index];
            v.transform = transform;
            [v setNeedsDisplay];
        }
    }
}
///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] == 1)
    {
        UITouch* touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self];
        NSInteger n = pt.x / indicatorWidth;
        self.rating = n+1;
        [self transformViewAtIndex:n];
//        [self updateDisplayForRating];
    }
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] == 1)
    {
        UITouch* touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self];
//        NSLog(@"tm %@",NSStringFromCGPoint(pt));
        NSInteger n = pt.x / indicatorWidth;
        if(n>4){
            n=4;
        }
        self.rating = n+1;
        [self transformViewAtIndex:n];
        [self updateDisplayForRating];
    }
    
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self transformViewAtIndex:-1];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self transformViewAtIndex:-1];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) setRating:(NSInteger) newRating
{
    _rating = newRating;
    [self updateDisplayForRating];
    [self setNeedsDisplay];
	
	[self.delegate ratingView: self ratingChanged: newRating];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) setNumberOfElements:(NSUInteger) num 
{
    _numberOfElements = num;
    [self clearIndicators];
    
    [self updateDisplayForRating];
    [self setNeedsDisplay];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) setSelectedImage:(UIImage *)selectedImage
{
    if (selectedImage != _selectedImage)
    {
        _selectedImage = selectedImage;
    }
    [self setNeedsLayout];
}

@end
