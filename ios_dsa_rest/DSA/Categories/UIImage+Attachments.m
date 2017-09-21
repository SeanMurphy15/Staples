//
//  UIImage+Attachments.m
//  DSA
//
//  Created by Mike McKinley on 4/11/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "UIImage+Attachments.h"
#import "MMSF_Attachment.h"
#import "DSA_ImageCache.h"

@implementation UIImage (Attachments)

+ (UIImage*)imageWithAttachmentId:(NSString*)salesforceId {
  
    UIImage *outImage  = nil;
    CGFloat imageScale = [UIScreen mainScreen].scale;
  
    if (salesforceId) {
        // is the image cached?
        outImage = [[DSA_ImageCache sharedCache] cachedImageForId:salesforceId];
        if (!outImage) {
            // load the image from the Attachment
            MMSF_Attachment* attachment = [MMSF_Attachment attachmentWithSalesforceId:salesforceId] ;
            if (attachment) {

                NSData *imageData       = [NSData dataWithContentsOfFile:[attachment filepath]];
                UIImage *attachmentImage = [UIImage imageWithData:imageData scale:imageScale];
                
                // decompress
                UIGraphicsBeginImageContext(attachmentImage.size);
                [attachmentImage drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
                UIImage *decompressedImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                // cache
                if (decompressedImage) {
                    [[DSA_ImageCache sharedCache] cacheImage:decompressedImage forId:salesforceId];
                }
                
                outImage = decompressedImage;
            }
        }
    }
    
    return outImage;
}

@end
