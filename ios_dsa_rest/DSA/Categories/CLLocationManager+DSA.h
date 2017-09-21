//
//  CLLocationManager+DSA.h
//  DSA
//
//  Created by Mike McKinley on 4/23/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

/**
 *  Is Location Services enabled for the device and
 *  is this app authorized to use it?
 *
 */

@interface CLLocationManager (DSA)

+ (BOOL) locationServicesAllowed;

@end
