//
//  DSA_ImageCache.m
//  DSA
//
//  Created by Mike McKinley on 4/27/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ImageCache.h"

@implementation DSA_ImageCache

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(DSA_ImageCache, sharedCache)

- (instancetype)init {
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.countLimit = 100;
        _cache.name = @"DSA_ImageCache";
    }
    
    return  self;
}

- (UIImage *)cachedImageForId:(NSString*)id {
    UIImage *cachedImage = [self.cache objectForKey:id];
    
    return cachedImage;
}

- (void)cacheImage:(UIImage*)image forId:(NSString*)id {
    [self.cache setObject:image forKey:id];
}


@end
