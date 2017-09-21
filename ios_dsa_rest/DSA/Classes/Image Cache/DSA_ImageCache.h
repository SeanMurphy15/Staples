//
//  DSA_ImageCache.h
//  DSA
//
//  Created by Mike McKinley on 4/27/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSA_ImageCache : NSObject

@property (nonatomic,strong) NSCache* cache;

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(DSA_ImageCache, sharedCache)

- (UIImage *)cachedImageForId:(NSString*)id;
- (void)cacheImage:(UIImage*)image forId:(NSString*)id;

@end
