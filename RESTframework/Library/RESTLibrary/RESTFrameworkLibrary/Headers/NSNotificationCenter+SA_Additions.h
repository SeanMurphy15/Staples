//
//  NSNotificationCenter+SA_Additions.h
//
//  Created by Ben Gottlieb on 5/29/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^notificationArgumentBlock)(NSNotification *note);


@interface NSNotificationCenter (NSNotificationCenter_SA_Additions)

+ (void) postNotificationNamed: (NSString *) name;
+ (void) postNotificationNamed: (NSString *) name object: (id) object;

- (void) postNotificationOnMainThreadName: (NSString *) name object: (id) object;
- (void) postDeferredNotificationOnMainThreadName: (NSString *) name object: (id) object;
- (void) postNotificationOnMainThreadName: (NSString *) name object: (id) object info: (NSDictionary *) info;
- (void) postDeferredNotificationOnMainThreadName: (NSString *) name object: (id) object info: (NSDictionary *) info;
- (void) postDeferredNotification: (NSNotification *) note;	

- (id) addFireAndForgetBlockFor: (NSString *) name object: (id) object block: (notificationArgumentBlock) block;
- (void) removeFireAndForgetNotification: (id) notificationInfo;
@end
