//
//  NSObject+MM_ContextManager_UnitTesting.h
//  ios_dsa
//
//  Created by Guy Umbright on 3/4/13.
//
//

#import <Foundation/Foundation.h>
#import "MM_ContextManager.h"
#import "MM_ContextManager+Model.h"

@interface MM_ContextManager (UnitTesting)

+ (id)sharedManager;
+ (void) setOverrideContextManager:(MM_ContextManager*) manager;

@end
