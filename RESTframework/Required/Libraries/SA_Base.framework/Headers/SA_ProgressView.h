//
//  SA_ProgressView.h
//  RESTFramework Harness
//
//  Created by Ben Gottlieb on 5/30/14.
//  Copyright (c) 2014 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SA_ProgressView_type) {
	SA_ProgressView_linear,
	SA_ProgressView_round
};

@interface SA_ProgressView : UIView
@property (nonatomic) CGFloat progress;
@property (nonatomic) SA_ProgressView_type type;
@property (nonatomic, strong) UIColor *fillColor, *borderColor;
@end
