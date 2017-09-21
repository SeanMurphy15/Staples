// DSAOAuthPlugin.h
//
//
// Copyright (c) ModelMetrics 2012
// Created by Amisha Goyal.
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface DSAOAuthPlugin : CDVPlugin {
    
}

// Instance Method  

- (void) getOAuthSessionID:(CDVInvokedUrlCommand *) command;
- (void) getRefreshToken:(CDVInvokedUrlCommand *) command ;
- (void) getOAuthClientID:(CDVInvokedUrlCommand *) command;
- (void) getUserAgent:(CDVInvokedUrlCommand *) command;
- (void) getInstanceUrl:(CDVInvokedUrlCommand *) command ;
- (void) getLoginUrl:(CDVInvokedUrlCommand *) command ;
- (void) getOAuthParametersAndAppointmentDetails:(CDVInvokedUrlCommand *) command;

@end

#endif