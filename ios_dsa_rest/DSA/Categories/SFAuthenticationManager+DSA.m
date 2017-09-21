//
//  SFAuthenticationManager+DSA.m
//  DSA
//
//  Created by Steve Deren on 12/18/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "SFAuthenticationManager+DSA.h"
#import <objc/runtime.h>

@implementation SFAuthenticationManager (DSA)

// Note: This should be removed as soon as the SDK provides a mechanism for customizing the error that gets displayed in identityCoordinator:didFailWithError: (see SFAuthenticationManager.m)

+ (void)load {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        SEL originalSelector = @selector(identityCoordinator:didFailWithError:);
        SEL swizzledSelector = @selector(swizzled_identityCoordinator:didFailWithError:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class,originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)swizzled_identityCoordinator:(SFIdentityCoordinator *)coordinator didFailWithError:(NSError *)error {
    
    MMLog(@"prevented salesforce error alert (error: %@)",coordinator, error);
}
@end
