// DSAContentPlugin.h
//
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface DSAContentPlugin : CDVPlugin {
    
}

// Instance Method  

- (void) getCategoryContent:(CDVInvokedUrlCommand*) command;
- (void) getCategoryContentArray:(CDVInvokedUrlCommand*) command;
- (void) displayContent:(CDVInvokedUrlCommand*) command;
- (void) displayContentFromSFID:(CDVInvokedUrlCommand *) command;
- (void) getContentPathFromSFID:(CDVInvokedUrlCommand *) command;

@end

#endif