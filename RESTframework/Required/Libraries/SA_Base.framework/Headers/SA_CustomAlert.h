//
//  SA_CustomAlert.h
//  Words Play
//
//  Created by Ben Gottlieb on 5/23/14.
//  Copyright (c) 2014 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^alertButtonHitBlock)(NSInteger buttonIndex);


@interface SA_CustomAlert : NSObject

CLASS_PROPERTY(BOOL, useStandardAlerts, UseStandardAlerts);

CLASS_PROPERTY(UIFont *, titleFont, TitleFont);
CLASS_PROPERTY(UIFont *, messageFont, MessageFont);
CLASS_PROPERTY(UIFont *, buttonFont, ButtonFont);
CLASS_PROPERTY(CGFloat, viewWidth, ViewWidth);
CLASS_PROPERTY(CGFloat, viewMargin, ViewMargin);
CLASS_PROPERTY(CGFloat, titleMessageSpacing, TitleMessageSpacing);
CLASS_PROPERTY(CGFloat, messageButtonSpacing, MessageButtonSpacing);
CLASS_PROPERTY(CGFloat, buttonSpacing, ButtonSpacing);
CLASS_PROPERTY(CGFloat, buttonHeight, ButtonHeight);
CLASS_PROPERTY(NSTimeInterval, showAlertDuration, ShowAlertDuration);
CLASS_PROPERTY(NSTimeInterval, hideAlertDuration, HideAlertDuration);
CLASS_PROPERTY(UIColor *, backgroundColor, BackgroundColor);
CLASS_PROPERTY(UIColor *, messageColor, MessageColor);
CLASS_PROPERTY(UIColor *, buttonBackgroundColor, ButtonBackgroundColor);
CLASS_PROPERTY(UIColor *, titleColor, TitleColor);
CLASS_PROPERTY(UIColor *, defaultButtonTitleColor, DefaultButtonTitleColor);
CLASS_PROPERTY(UIColor *, buttonSeparatorColor, ButtonSeparatorColor);
CLASS_PROPERTY(UIColor *, buttonTitleColor, ButtonTitleColor);


@property (nonatomic, strong) NSString *title, *message;
@property (nonatomic, strong) NSArray *buttonTitles;
@property (nonatomic, copy) alertButtonHitBlock buttonHitBlock;
@property (nonatomic, strong) UIView *alertBaseView;
@property (nonatomic, strong) UILabel *titleLabel, *messageLabel;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic) NSUInteger defaultButtonIndex;
@property (nonatomic, strong) NSMutableArray *customViews;


@property (nonatomic, readonly) CGSize titleSize, messageSize, visibleMessageSize;
@property (nonatomic, readonly) CGFloat buttonTop;


+ (instancetype) showAlertWithTitle: (NSString *) title message: (NSString *) message;
+ (instancetype) showAlertWithTitle: (NSString *) title error: (NSError *) error;
+ (instancetype) showAlertWithTitle: (NSString *) title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (alertButtonHitBlock) buttonHitBlock;

- (void) show: (BOOL) animated;
- (void) dismiss: (BOOL) animated;

- (void) addCustomView: (UIView *) view;

@end

@interface SA_GradientBlockerView : UIView
@end
