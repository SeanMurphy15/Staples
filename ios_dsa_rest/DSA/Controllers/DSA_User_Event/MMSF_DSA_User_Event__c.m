//
//  MMSF_DSA_User_Event__c.m
//  DSA
//
//  Created by Mike Close on 5/25/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "MMSF_DSA_User_Event__c.h"

@implementation MMSF_DSA_User_Event__c

+ (NSString *)entityName {
    return @"DSA_User_Event__c";
}

+ (MMSF_DSA_User_Event__c *)reportEvent:(DSAUserEventType)eventType value:(id)eventValue {
    
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    
    MMSF_DSA_User_Event__c *userEvent = [moc insertNewEntityWithName:[self entityName]];
    
    [userEvent beginEditing];
    
    if (![self serializeEventType:eventType intoUserEvent:userEvent]) {
        MMLog(@"%@", @"Unable to convert event type into a known string value.");
        return nil;
    }
    
    if (![self serializeEventValue:eventValue intoUserEvent:userEvent]) {
        MMLog(@"%@", @"Unable to serialize event value into payload.");
        return nil;
    }
    
    [userEvent finishEditingSavingChanges:YES andPushingToServer:YES];
    
    return userEvent;
}

+ (BOOL)serializeEventType:(DSAUserEventType)eventType intoUserEvent:(MMSF_DSA_User_Event__c *)userEvent {
    NSString *eventTypeStr = nil;
    
    switch (eventType) {
        case DSAUserEventTypeAppLaunch:
            eventTypeStr = @"App Launch";
            break;
            
        default:
            break;
    }
    
    if (eventTypeStr == nil) return NO;
    
    userEvent[kDSAUserEventKey_EventType] = eventTypeStr;
    
    return YES;
}

+ (BOOL)serializeEventValue:(id)eventValue intoUserEvent:(MMSF_DSA_User_Event__c *)userEvent {
    if (eventValue) {
        NSString *eventValueKey = nil;
        
        if ([eventValue isKindOfClass:[NSString class]]) {
            eventValueKey = kDSAUserEventKey_TextEventValue;
        } else if ([eventValue isKindOfClass:[NSNumber class]]) {
            eventValueKey = kDSAUserEventKey_NumericEventValue;
        } else {
            return NO;
        }
        
        userEvent[eventValueKey] = eventValue;
    }
    
    return YES;
}

+ (void)submitEvent:(NSMutableDictionary *)payload {
    MMLog(@"Sending event: %@", payload);
}

@end

NSString *const kDSAUserEventKey_NumericEventValue = @"StaplesDSA__Numeric_Event_Value__c";
NSString *const kDSAUserEventKey_TextEventValue = @"StaplesDSA__Text_Event_Value__c";
NSString *const kDSAUserEventKey_EventType = @"StaplesDSA__Event_Type__c";