//
//  SA_Alert.h
//  
//
//  Created by Ben Gottlieb on 7/26/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SA_AlertView;

#define		SA_ALERT_CANCEL_BUTTON_INDEX				NSUIntegerMax

@interface SA_AlertView : UIAlertView

@property (nonatomic, copy) booleanArgumentBlock alertCancelButtonHitBlock;
@property (nonatomic, copy) intArgumentBlock alertButtonHitBlock;


+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle;
+ (SA_AlertView *) showAlertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag;
+ (SA_AlertView *) showAlertWithTitle: (NSString *) title message: (NSString *) message, ...;
+ (SA_AlertView *) showAlertWithTitle: (NSString *) title	error: (NSError *) error;
+ (SA_AlertView *) showAlertWithException: (NSException *) e;

+ (SA_AlertView *) alertWithTitle: (NSString *)title message: (NSString *) message tag: (NSUInteger) tag button: (NSString *) buttonTitle;

+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock;
+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock;
@end


@interface NSError (SA_Alert) 
- (NSString *) fullDescription;
@end

