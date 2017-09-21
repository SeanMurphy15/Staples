//
//  SA_ProgressDisplay.h
//  RESTFramework Harness
//
//  Created by Ben Gottlieb on 5/26/14.
//  Copyright (c) 2014 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SA_ProgressView;

typedef NS_ENUM(NSUInteger, SA_ProgressDisplay_style) {
	SA_ProgressDisplay_style_unchanged,						//defaults to SA_ProgressDisplay_style_activityIndicator if nothing else is already set

	SA_ProgressDisplay_style_labelsOnly,
	SA_ProgressDisplay_style_activityIndicator,
	SA_ProgressDisplay_style_linearProgress,
	SA_ProgressDisplay_style_linearProgressAndActivityIndicator,
	SA_ProgressDisplay_style_roundProgress,
};

typedef NS_ENUM(NSUInteger, SA_ProgressDisplay_labelPlacement) {
	SA_ProgressDisplay_labelPlacement_topAndBottom,
	SA_ProgressDisplay_labelPlacement_top,
	SA_ProgressDisplay_labelPlacement_bottom,
};

@interface SA_ProgressDisplay : NSObject

CLASS_PROPERTY(UIFont *, titleFont, TitleFont);
CLASS_PROPERTY(UIFont *, detailFont, DetailFont);
CLASS_PROPERTY(UIFont *, buttonFont, ButtonFont);
CLASS_PROPERTY(UIColor *, backgroundColor, BackgroundColor);
CLASS_PROPERTY(UIColor *, titleColor, TitleColor);
CLASS_PROPERTY(UIColor *, detailColor, DetailColor);
CLASS_PROPERTY(UIColor *, buttonBackgroundColor, ButtonBackgroundColor);
CLASS_PROPERTY(UIColor *, buttonTitleColor, ButtonTitleColor);
CLASS_PROPERTY(CGFloat, viewWidth, ViewWidth);
CLASS_PROPERTY(CGFloat, viewMargin, ViewMargin);
CLASS_PROPERTY(CGFloat, titleDetailSpacing, TitleDetailSpacing);
CLASS_PROPERTY(CGFloat, detailButtonSpacing, DetailButtonSpacing);
CLASS_PROPERTY(CGFloat, componentSpacing, ComponentSpacing);
CLASS_PROPERTY(CGFloat, buttonHeight, ButtonHeight);

+ (instancetype) progressDisplay;
+ (instancetype) showProgressStyle: (SA_ProgressDisplay_style) style withTitle: (NSString *) title detail: (NSString *) detail;

@property (nonatomic, strong) NSString						*title, *detail, *buttonTitle;
@property (nonatomic) CGFloat								percentageComplete;
@property (nonatomic, copy) simpleBlock						buttonBlock;
@property (nonatomic) SA_ProgressDisplay_style				style;
@property (nonatomic) SA_ProgressDisplay_labelPlacement		labelPlacement;
@property (nonatomic) CGFloat								roundProgressDiameter, linearProgressHeight;

@property (nonatomic, readonly) UILabel						*titleLabel, *detailLabel;
@property (nonatomic, readonly) UIActivityIndicatorView		*activityIndicatorView;
@property (nonatomic, readonly) SA_ProgressView				*progressView;
@property (nonatomic, readonly) UIButton					*button;

- (instancetype) addButtonWithTitle: (NSString *) title andBlock: (simpleBlock) block;
- (void) show: (BOOL) animated;
- (void) hide: (BOOL) animated;

@end

