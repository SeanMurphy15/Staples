// Cordova2SharedLibPlugin.h
//
//
// Copyright (c) ModelMetrics 2012
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface Cordova2SharedLibPlugin : CDVPlugin {
    
}

// Instance Method  

//- (void) print:(CDVInvokedUrlCommand*)command;
- (void) createRecord:(CDVInvokedUrlCommand *) command;
- (void) getOAuthSessionID:(CDVInvokedUrlCommand *) command;
- (void) getHTML5BundleFilePath:(CDVInvokedUrlCommand *) command;
- (void) getRecordsUsingQuery:(CDVInvokedUrlCommand *) command;
- (void) syncButtonPressed:(CDVInvokedUrlCommand *) command;
- (void) logoutButtonPressed:(CDVInvokedUrlCommand *) command;

@end

#endif