//
//  NSArray+JSONOperations.m
//  PhoneGap2SalesforceSDK
//
//  Created by Alexey Bilous on 9/6/12.
//
//
#import "MMSF_Object.h"
#import "SBJson.h"
#import "NSArray+JSONOperations.h"

@implementation NSArray (JSONOperations)

- (NSString *) JSONValueFromArrayOfMMSF_Objects {
    NSMutableArray *arrayOfSnapshots = [NSMutableArray array];
    
    for (MMSF_Object *object in self) {
        NSMutableDictionary * const recordDictionary = [[object snapshot] mutableCopy];
        NSArray * const keys = [recordDictionary allKeys];
        for (NSUInteger idx = 0, count = [keys count]; idx < count; ++idx) {
            id const key = [keys objectAtIndex:idx];
            id const obj = [recordDictionary objectForKey:key];
            
            // Current build of SBJSON library doesn't supports NSSet serialization so let's transform it into NSArray
            if ([obj isKindOfClass: [NSSet class]]) {
                [recordDictionary setObject:[obj allObjects] forKey:key];
            }
        }
        
        NSDictionary * result = [recordDictionary copy];
        [arrayOfSnapshots addObject:result];
    }
    
    return [arrayOfSnapshots JSONRepresentation];
}

@end
