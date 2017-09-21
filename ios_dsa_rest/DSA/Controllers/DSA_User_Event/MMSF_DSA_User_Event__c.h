//
//  MMSF_DSA_User_Event__c.h
//  DSA
//
//  Created by Mike Close on 5/25/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "MMSF_Object.h"

typedef enum {
    DSAUserEventTypeAppLaunch
} DSAUserEventType;

@interface MMSF_DSA_User_Event__c : MMSF_Object

+ (MMSF_DSA_User_Event__c *)reportEvent:(DSAUserEventType)eventType value:(id)eventValue;

@end


extern NSString *const kDSAUserEventKey_NumericEventValue;
extern NSString *const kDSAUserEventKey_TextEventValue;
extern NSString *const kDSAUserEventKey_EventType;