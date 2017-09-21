//
//  UIColor+SA_Additions.h
//
//  Created by Ben Gottlieb on 4/23/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define vendColor(r, g, b) static UIColor *ret; if (ret == nil) ret = [UIColor colorWithRed:(CGFloat)r/255.0 green:(CGFloat)g/255.0 blue:(CGFloat)b/255.0 alpha:1.0]; return ret

#define	GENERATE_UICOLOR(r, g, b)	[UIColor colorWithRed:(CGFloat)r/255.0 green:(CGFloat)g/255.0 blue:(CGFloat)b/255.0 alpha:1.0]

NSString *				NSStringFromCGColor(CGColorRef color);

@interface UIColor (UIColor_SA_Additions)

@property(readonly) const CGFloat * SA_RGBAComponents;
@property(readonly) const CGFloat * SA_HSBAComponents;
@property (nonatomic, readonly) CGFloat alpha;


+ (UIColor *)  colorWithSA_HexString: (NSString *) string;
+ (UIColor *)  colorWithSA_String: (NSString *) string;
- (UIColor *)  initWithSA_HexString: (NSString *) string;
- (NSString *) SA_hexString;
- (NSString *) SA_hexStringWithAlpha;

- (UIColor *) appropriateContrastingTextColor;

@end
