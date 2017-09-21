//
//  UIResponder+UIResponder_FirstResponderTracking.m
//  DSA
//
//  Created by Mike Close on 7/26/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "UIResponder+UIResponder_FirstResponderTracking.h"

static __weak id currentFirstResponder;

@implementation UIResponder (UIResponder_FirstResponderTracking)

+(id)currentFirstResponder {
    return currentFirstResponder;
}

+(void)setFirstResponder:(id)sender {
    currentFirstResponder = sender;
}

@end
