//
//  DSA_NLevelCategoryImageView.h
//  ios_dsa
//
//  Created by Chris Cieslak on 7/29/13.
//
//

#import <UIKit/UIKit.h>
#import "MMSF_Category__c.h"

@interface DSA_NLevelCategoryImageView : UIControl

@property (nonatomic, strong) MMSF_Category__c *category;
@property (nonatomic, strong) UIImageView *categoryImageView;
@property (nonatomic, strong) UILabel *label;

+ (id) viewWithCategory: (MMSF_Category__c *) category inBounds: (CGRect) bounds;
+ (CGSize) defaultSize;

+ (void) setDefaultImageHeight: (CGFloat) height;

- (void)loadImageinQueue:(NSOperationQueue*)queue;

@end
