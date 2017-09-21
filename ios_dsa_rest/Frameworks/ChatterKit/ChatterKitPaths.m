//
//  ChatterKitPaths.m
//  ChatterKitDemo
//
//  Created by Guy Umbright on 11/15/12.
//  Copyright (c) 2012 Model Metrics. All rights reserved.
//

#import "ChatterKitPaths.h"

@implementation ChatterKit (Paths)

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
+ (NSString*) pathForRecord:(NSString*) recordId
{
    static NSString* recordFormat = @"/chatter/feeds/record/%@/feed-items";
    
    return [NSString stringWithFormat:recordFormat,recordId];
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
+ (NSString*) pathForFeedItemComments:(NSString*) feeditemId
{
    static NSString* commentFormat = @"/chatter/feed-items/%@/comments";
    return [NSString stringWithFormat:commentFormat,feeditemId];
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
+ (NSString*) pathForMyFeed
{
    static NSString* myFeedPath = @"/chatter/feeds/news/me/feed-items";
    
    return myFeedPath;
}

@end
