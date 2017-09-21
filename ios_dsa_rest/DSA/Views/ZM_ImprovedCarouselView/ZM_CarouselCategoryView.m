//
//  ZM_CarouselCategoryView.m
//  ModelMetrics
//
//  Created by Chris Cieslak on 2/4/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "ZM_CarouselCategoryView.h"

#define kImageInset 40

@implementation ZM_CarouselCategoryView

@synthesize originalFrame, category = _category, categoryImageView, categoryLabel, innerView;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		self.innerView = [[UIView alloc] initWithFrame:self.bounds];
		self.originalFrame = self.innerView.frame;
		self.innerView.autoresizesSubviews = YES;
		[self addSubview:self.innerView];
		
//		self.backgroundColor = [UIColor orangeColor];
//		self.innerView.backgroundColor = [UIColor greenColor];
		
		CGFloat shortSide = MIN(self.frame.size.width, self.frame.size.height) - kImageInset;
		CGFloat inset = (self.frame.size.width - shortSide) / 2;
		CGRect imageFrame = CGRectMake(inset, 5, shortSide, shortSide);
		self.categoryImageView = [[UIImageView alloc] initWithFrame:imageFrame];
		self.categoryImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.categoryImageView.contentMode = UIViewContentModeScaleAspectFit;
		CALayer *imageLayer = self.categoryImageView.layer;
		
		imageLayer.shadowColor = [UIColor darkGrayColor].CGColor;
		imageLayer.shadowOffset = CGSizeMake(3, 3);
		imageLayer.shadowOpacity = .5;
		imageLayer.masksToBounds = NO;
		imageLayer.shouldRasterize = YES;
		[self.innerView addSubview:self.categoryImageView];
		
		self.categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.innerView.bounds.size.height - 40, self.innerView.bounds.size.width, 40)];
		self.categoryLabel.backgroundColor = [UIColor clearColor];
		self.categoryLabel.textColor = [UIColor whiteColor];
		self.categoryLabel.font = [UIFont boldSystemFontOfSize:10];
		self.categoryLabel.textAlignment = NSTextAlignmentCenter;
		self.categoryLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
        self.categoryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.categoryLabel.numberOfLines = 3;
		[self.innerView addSubview:self.categoryLabel];
        
    }
    return self;
}

#pragma mark Setup once category is assigned

-(void)setCategory:(MMSF_Category__c *)aCategory {
	
	if (aCategory == _category) {
		return;
	}
	
	_category = aCategory;
	
	self.categoryImageView.image = [_category attachmentImage];
	self.categoryLabel.text = [_category Name];

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	self.category = nil;
}


@end
