//
// DSASynchronizedDataPlugin.h
//
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface DSASynchronizedDataPlugin : CDVPlugin {
}

@property (nonatomic, readonly) NSArray *sortedSubcategories;

- (void) get:(CDVInvokedUrlCommand*) command;
- (void) search:(CDVInvokedUrlCommand*) command;
- (void) upsert:(CDVInvokedUrlCommand*) command;

@end

#endif

