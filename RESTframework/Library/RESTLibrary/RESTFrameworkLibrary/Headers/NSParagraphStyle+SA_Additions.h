//
//  NSParagraphStyle+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 5/29/14.
//
//

#import <UIKit/UIKit.h>

@interface NSParagraphStyle (SA_Additions)

+ (NSMutableParagraphStyle *) rightAlignedStyle;
+ (NSMutableParagraphStyle *) centeredStyle;
+ (NSMutableParagraphStyle *) styleWithLineHeightMultiplier: (CGFloat) multiple;


@end
