//
//  CLLocationManager+DSA.m
//  DSA
//
//  Created by Mike McKinley on 4/23/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "CLLocationManager+DSA.h"

@implementation CLLocationManager (DSA)

+ (BOOL) locationServicesAllowed {
    BOOL enabledForDevice = [CLLocationManager locationServicesEnabled];
    BOOL authorizedForApp = ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied);
    
    return enabledForDevice && authorizedForApp;
}

@end
