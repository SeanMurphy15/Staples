//
// DSAContactPlugin.h
//
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface DSAContactPlugin : CDVPlugin {
    
}

// Instance Method  

- (void) checkedInContact:(CDVInvokedUrlCommand*) command;
- (void) searchContact:(CDVInvokedUrlCommand*) command;

@end

#endif