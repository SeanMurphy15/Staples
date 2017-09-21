//
//  DSA_AppLaunchEvent.m
//  DSA
//
//  Created by Mike Close on 5/25/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "DSA_AppLaunchEvent.h"

#import "MMSF_DSA_User_Event__c.h"

static BOOL eventScheduled;

@implementation DSA_AppLaunchEvent

+ (DSA_AppLaunchEvent *)triggerEventAfterDelay:(NSTimeInterval)delay {
    if (eventScheduled) return nil;
    
    DSA_AppLaunchEvent *launchEvent = [[DSA_AppLaunchEvent alloc] init];
    
    [launchEvent performSelector:@selector(triggerEvent) withObject:nil afterDelay:delay];
    
    eventScheduled = YES;
    
    return launchEvent;
}



- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnteredBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)triggerEvent {
    
    [MMSF_DSA_User_Event__c reportEvent:DSAUserEventTypeAppLaunch value:nil];
    
    eventScheduled = NO;
}

- (void)applicationEnteredBackground:(NSNotification *)note {
    [self cancelPendingSelector:@selector(triggerEvent) withObject:nil];
    eventScheduled = NO;
}



@end
