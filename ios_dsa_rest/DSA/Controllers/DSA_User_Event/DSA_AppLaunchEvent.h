//
//  DSA_AppLaunchEvent.h
//  DSA
//
//  Created by Mike Close on 5/25/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

@interface DSA_AppLaunchEvent : NSObject
+ (DSA_AppLaunchEvent *)triggerEventAfterDelay:(NSTimeInterval)delay;
@end
