//
//  UIImage+NLevelIcons.m
//  ios_dsa
//
//  Created by Steve Deren on 10/4/13.
//
//

#import "UIImage+NLevelIcons.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (NLevelIcons)

+ (UIImage *)resizeImageToMaxSize:(CGFloat)max path:(NSString *)path {
  
  NSURL *filePath = [NSURL fileURLWithPath:path];
  
  CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)filePath, NULL);
  
  if (!imageSource) {
    return nil;
  }
  
  NSNumber *maxWidth    = @(max);
  NSDictionary *options = @{
                            (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                            (__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform: @YES,
                            (__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize : maxWidth,
                            (__bridge NSString *)kCGImageSourceCreateThumbnailFromImageIfAbsent : @YES
                            };
  
  CFDictionaryRef cfOptions = (__bridge CFDictionaryRef)options;
  CGImageRef imgRef         = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, cfOptions);
  CGFloat imageScale        = [UIScreen mainScreen].scale;
  
  UIImage *scaled = [UIImage imageWithCGImage:imgRef
                                        scale:imageScale
                                  orientation:UIImageOrientationUp];
  
  CGImageRelease(imgRef);
  CFRelease(imageSource);
  
  return scaled;
}

// Get image size without loading the image into memory
+ (CGSize)imageSizeFromPath:(NSString*)path {
	
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
  
  if (!imageSource) {
    return CGSizeMake(0, 0);
  }
	
	CGFloat width  = 0.0;
	CGFloat height = 0.0;
	
	CFDictionaryRef imgDict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);

	if (imgDict != NULL) {
		
		CFNumberRef wid  = CFDictionaryGetValue(imgDict, kCGImagePropertyPixelWidth);
		
		if (wid != NULL) {
			CFNumberGetValue(wid, kCFNumberFloatType, &width);
		}
		
		CFNumberRef ht = CFDictionaryGetValue(imgDict, kCGImagePropertyPixelHeight);
		
		if (ht != NULL) {
			CFNumberGetValue(ht, kCFNumberFloatType, &height);
		}
		
		CFRelease(imgDict);
	}
	
    CGSize resize = {width, height};
  
	return resize;
}

@end
