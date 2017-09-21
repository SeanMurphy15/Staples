//
//  DSA_ThumbnailManager.h
//  DSA
//
//  Created by Mike Close on 11/12/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MMSF_ContentVersion;

@interface DSA_ThumbnailManager : NSObject
SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(DSA_ThumbnailManager, sharedManager);

- (void)thumbnailForContentVersion:(MMSF_ContentVersion*)contentVersion
                                   size:(CGSize)size
                        backgroundColor:(UIColor *)backgroundColor
                            borderColor:(UIColor*)borderColor
                                outsets:(UIEdgeInsets)borderOutsets
                        completionBlock:(void(^)(UIImage*))completionBlock;

- (void)thumbnailForContentVersion:(MMSF_ContentVersion*)contentVersion
                                   size:(CGSize)size
                        completionBlock:(void(^)(UIImage*))completionBlock;

@end
