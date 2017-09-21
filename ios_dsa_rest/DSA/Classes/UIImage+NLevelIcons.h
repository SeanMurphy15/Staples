//
//  UIImage+NLevelIcons.h
//  ios_dsa
//
//  Created by Steve Deren on 10/4/13.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (NLevelIcons)
+ (UIImage*)resizeImageToMaxSize:(CGFloat)max path:(NSString*)path;
+ (CGSize)imageSizeFromPath:(NSString*)path;
@end
