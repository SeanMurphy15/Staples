//
// DSASyncControlPlugin.h
//
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface DSASyncControlPlugin : CDVPlugin {
}

// Instance Method
@property (nonatomic, readonly) NSArray *sortedSubcategories;

- (void) deltaSync:(CDVInvokedUrlCommand*) command;
- (void) fullSync:(CDVInvokedUrlCommand*) command;

@end

#endif