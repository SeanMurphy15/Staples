//
//  Actor.m
//  chattest
//
//  Created by Guy Umbright on 4/12/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_Actor.h"

@implementation CK_ChatterKitObject (CK_Actor)

- (NSInteger) actorType
{
    NSInteger result = CK_ActorType_Unknown;
    
    NSString* actorType = [self stringForKey:CK_ActorKey_Type];
    
    if ([actorType isEqualToString:@"User"])
    {
        
    }
    else if ([actorType isEqualToString:@"RecordSummary"])
    {
        
    }
    else if ([actorType isEqualToString:@"CollaberationGroup"])
    {
        
    }
    else if ([actorType isEqualToString:@"UnauthorizedUser"])
    {
        
    }
    
    return result;
}

@end 
@implementation CK_Actor

@end
