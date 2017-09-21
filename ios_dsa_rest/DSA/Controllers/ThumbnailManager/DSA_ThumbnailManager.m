//
//  DSA_ThumbnailManager.m
//  DSA
//
//  Created by Mike Close on 11/12/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ThumbnailManager.h"
#import "MMSF_ContentVersion.h"
#import "MGFilePreviewGenerator.h"

@implementation DSA_ThumbnailManager

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(DSA_ThumbnailManager, sharedManager);

static NSCache                *s_thumbCache = nil;
static MGFilePreviewGenerator *previewGenerator;

- (instancetype)init
{
    self = [super init];
    if (self) {
        previewGenerator = [[MGFilePreviewGenerator alloc] init];
    }
    return self;
}


- (void)thumbnailForContentVersion:(MMSF_ContentVersion*)contentVersion size:(CGSize)size backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets completionBlock:(void(^)(UIImage*))completionBlock
{
    NSString *key = [self cacheKeyForContentVersion:contentVersion size:size backgroundColor:backgroundColor borderColor:borderColor outsets:borderOutsets];
    
    __weak typeof(self) weakSelf = self;
    __block UIImage *thumb = [self cachedThumbForKey:key];
    
    if (thumb)
    {
        if (completionBlock)
        {
            completionBlock(thumb);
        }
        
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
            thumb = [previewGenerator thumbnailForContentVersion:contentVersion size:size backgroundColor:backgroundColor borderColor:borderColor outsets:borderOutsets];
            [weakSelf cacheThumb:thumb forKey:key];
            
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                if (completionBlock) {
                    completionBlock(thumb);
                }
            });
            
        });
    }
}

- (void)thumbnailForContentVersion:(MMSF_ContentVersion*)contentVersion
                              size:(CGSize)size
                   completionBlock:(void(^)(UIImage*))completionBlock
{
    if (s_thumbCache == nil) {
        s_thumbCache = [[NSCache alloc] init];
        [s_thumbCache setCountLimit: 100];
    }
    
    NSString *key = [self cacheKeyForContentVersion:contentVersion size:size backgroundColor:[UIColor blackColor]];
    
    __weak typeof(self) weakSelf = self;
    __block UIImage *thumb = [s_thumbCache objectForKey:key];
    
    if (thumb)
    {
        if (completionBlock) {
            completionBlock(thumb);
        }
        
    } else {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
            
            thumb = [previewGenerator generatePreviewForContentVersion:contentVersion size:size backgroundColor:[UIColor blackColor]];
            [weakSelf cacheThumb:thumb forKey:key];
            
            dispatch_sync(dispatch_get_main_queue(), ^(void) {
                if (completionBlock) {
                    completionBlock(thumb);
                }
            });
        });
    }
}

- (void)cacheThumb:(UIImage*)thumb forKey:(NSString*)key
{
    [s_thumbCache setObject:thumb forKey:key];
    MMLog(@"Created and cached thumbnail: %@",key);
}

- (UIImage *)cachedThumbForKey:(NSString*)key
{
    if (s_thumbCache == nil) {
        s_thumbCache = [[NSCache alloc] init];
        [s_thumbCache setCountLimit: 100];
    }
    return [s_thumbCache objectForKey:key];
}

- (NSString *)cacheKeyForContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor
{
    float r, g, b, a;
    [backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    return $S(@"%@_%g_%g_%0.2f_%0.2f_%0.2f_%1.2f",contentVersion.Id,size.width,size.height,r,g,b,a);
}

- (NSString *)cacheKeyForContentVersion:(MMSF_ContentVersion *)contentVersion size:(CGSize)size backgroundColor:(UIColor*)backgroundColor borderColor:(UIColor *)borderColor outsets:(UIEdgeInsets)borderOutsets
{
    float r, g, b, a, bgr, bgg, bgb, bga;
    [borderColor getRed:&r green:&g blue:&b alpha:&a];
    [backgroundColor getRed:&bgr green:&bgg blue:&bgb alpha:&bga];
    return $S(@"%@_%g_%g_%0.2f_%0.2f_%0.2f_%1.2f_%0.2f_%0.2f_%0.2f_%1.2f_%g_%g_%g_%g",contentVersion.Id,size.width,size.height,r,g,b,a,bgr,bgg,bgb,bga,borderOutsets.top,borderOutsets.right,borderOutsets.bottom,borderOutsets.left);
}

@end
