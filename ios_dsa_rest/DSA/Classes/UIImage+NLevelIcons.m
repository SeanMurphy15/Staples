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

// Make thumbnail from path with a max size
+ (UIImage*)resizeImageToMaxSize:(CGFloat)max path:(NSString*)path
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (!imageSource)
        return nil;
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                         (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                                         (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                                         (id)[NSNumber numberWithFloat:max], (id)kCGImageSourceThumbnailMaxPixelSize,
                                                         nil];
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
    UIImage* scaled = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);
    CFRelease(imageSource);
    
    return scaled;
}

// Get image size without loading the image into memory
+ (CGSize)imageSizeFromPath:(NSString*)path {
	
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (!imageSource)
        return CGSizeMake(0, 0);
	
	CGFloat width = 0.0;
	CGFloat height = 0.0;
	
	CFDictionaryRef imgDict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
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
	
	return CGSizeMake(width, height);
}
@end
