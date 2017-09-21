//
//  UIColor+DSA.m
//  DSA
//
//  Created by Mike McKinley on 3/17/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "UIColor+DSA.h"

@implementation UIColor (DSA)

+ (UIColor*)sfdcPrimaryBlue {
    static NSString * const SFDC_PrimaryBlueColor = @"#2A94D6";
    UIColor *primaryBlue = [UIColor colorWithHexString:SFDC_PrimaryBlueColor];
    
    return primaryBlue;
}

+ (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    UIColor *outColor = nil;
    
    if (hexString && [hexString isKindOfClass:[NSString class]] && hexString.length >= 6) {
        // strip # if present
        NSString *scanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
        
        unsigned rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:scanString];
        // scanHexInt will ignore a "0x" prefix
        BOOL success = [scanner scanHexInt:&rgbValue];
        if (success) {
            CGFloat red = ((rgbValue & 0xFF0000) >> 16)/255.0;
            CGFloat green = ((rgbValue & 0xFF00) >> 8)/255.0;
            CGFloat blue = (rgbValue & 0xFF)/255.0;
            
            outColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        }
    }
    
    return outColor;
}

+ (UIColor *)defaultTableViewSectionHeaderColor {
    static NSString * const HK_SectionHeaderColor = @"#21aae1";
    UIColor *color = [UIColor colorWithHexString:HK_SectionHeaderColor alpha:0.6];
    
    return color;
}

+ (UIColor *)darkBlueTextColor {
    static NSString * const HK_DarkBlueTextColor = @"#05678e";
    UIColor *color = [UIColor colorWithHexString:HK_DarkBlueTextColor alpha:1.0];
    
    return color;
}

@end
