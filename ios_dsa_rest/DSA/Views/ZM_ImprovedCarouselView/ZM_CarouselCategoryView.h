//
//  ZM_CarouselCategoryView.h
//  ModelMetrics
//
//  Created by Chris Cieslak on 2/4/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_Category__c.h"

@interface ZM_CarouselCategoryView : UIView {
	MMSF_Category__c *_category;
}

@property (nonatomic, readwrite, strong) MMSF_Category__c *category;

@property (nonatomic, readwrite, assign) CGRect originalFrame;

@property (nonatomic, readwrite, strong) UIView *innerView;
@property (nonatomic, readwrite, strong) UIImageView *categoryImageView;
@property (nonatomic, readwrite, strong) UILabel *categoryLabel;

@end
