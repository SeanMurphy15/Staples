//
//  NSObject+MM_ContextManager_UnitTesting.m
//  ios_dsa
//
//  Created by Guy Umbright on 3/4/13.
//
//

#import "MM_ContextManager+UnitTesting.h"

static MM_ContextManager* s_currentManager;

@implementation MM_ContextManager (UnitTests)

+ (id)sharedManager {
    return s_currentManager;
}

+ (void) setOverrideContextManager:(MM_ContextManager*) manager
{
    s_currentManager = manager;
}
@end
