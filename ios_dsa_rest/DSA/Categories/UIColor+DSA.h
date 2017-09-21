//
//  UIColor+DSA.h
//  DSA
//
//  Created by Mike McKinley on 3/17/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (DSA)

/**
 * Creates a UIColor from a hexadecimal string.
 *
 * @param hexString Hexadecimal string defining the color; May be prefixed with "#" or "0x".
 * @param alpha Float value for alpha (0.0 - 1.0)
 */

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/**
 * Creates a Primary Blue color as defined by Salesforce Style Guidelines
 * #2A94D6
 */

+ (UIColor *)sfdcPrimaryBlue;

/**
 * Creates a blue color for Table View Section Header backgrounds
 * #21aae1
 */

+ (UIColor *)defaultTableViewSectionHeaderColor;

/**
 * Creates a dark blue text color
 *
 */

+ (UIColor *)darkBlueTextColor;


@end
