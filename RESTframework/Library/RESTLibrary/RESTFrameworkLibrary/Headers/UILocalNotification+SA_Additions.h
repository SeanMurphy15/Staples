//
//  UILocalNotification+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 10/27/13.
//
//

#import <UIKit/UIKit.h>

@interface UILocalNotification (SA_Additions)

+ (void) presentNotificationText: (NSString *) text withAction: (NSString *) action sound: (NSString *) soundName atDate: (NSDate *) date andUserInfo: (NSDictionary *) userInfo;

@end
