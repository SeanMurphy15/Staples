//
//  UIResponder+UIResponder_FirstResponderTracking.h
//  DSA
//
//  Created by Mike Close on 7/26/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (UIResponder_FirstResponderTracking)
+(id)currentFirstResponder;
+(void)setFirstResponder:(id)sender;
@end
