//
//  ChatterKitPaths.h
//  ChatterKitDemo
//
//  Created by Guy Umbright on 11/15/12.
//  Copyright (c) 2012 Model Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatterKit.h"

@interface ChatterKit (Paths)

+ (NSString*) pathForRecord:(NSString*) recordId;
+ (NSString*) pathForFeedItemComments:(NSString*) feeditemId;
+ (NSString*) pathForMyFeed;

@end
