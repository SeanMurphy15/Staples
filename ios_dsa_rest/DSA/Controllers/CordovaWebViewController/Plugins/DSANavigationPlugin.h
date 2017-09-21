//
// DSANavigationPlugin.h
//
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface DSANavigationPlugin : CDVPlugin {
    NSArray						*_sortedSubCategories;
}

// Instance Method  
@property (nonatomic, readonly) NSArray *sortedSubcategories;
- (void) openURL:(CDVInvokedUrlCommand*) command;
- (void) openCategory:(CDVInvokedUrlCommand*) command;

@end

#endif