//
//  DSAAppointmentPlugin.h
//  ios_dsa
//
//  Created by Amisha Goyal on 5/15/13.
//
//

#if BUILD_WITH_CORDOVA

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface DSAAppointmentPlugin : CDVPlugin

- (void) checkedInAppointment:(CDVInvokedUrlCommand*) command;

@end
#endif