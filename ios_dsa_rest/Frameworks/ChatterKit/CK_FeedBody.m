//
//  FeedBody.m
//  chattest
//
//  Created by Guy Umbright on 4/12/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_FeedBody.h"

@implementation CK_FeedBody

- (NSArray*) messageSegments
{
    NSArray* arr = [self.contents objectForKey:@"messageSegments"];
    NSMutableArray* result = nil;
    
    if (arr != nil && arr.count > 0)
    {
        result = [NSMutableArray arrayWithCapacity:arr.count];
        
        for (NSDictionary* dict in arr)
        {
            [result addObject:[CK_ChatterKitObject withDictionary:dict]];
        }
    }
    return result;
}

- (NSString*) text
{
    return [self stringForKey:@"text"];
}

@end
