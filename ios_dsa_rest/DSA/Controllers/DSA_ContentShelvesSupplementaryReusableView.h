//
//  DSA_ContentShelvesHeaderReusableView.h
//  DSA
//
//  Created by Mike Close on 7/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSA_ContentShelvesModel.h"

@interface DSA_ContentShelvesSupplementaryReusableView : UICollectionReusableView <UIActionSheetDelegate>
@property (strong, nonatomic) NSString                  *backgroundGradientDirection;
@property (nonatomic, strong) DSA_ContentShelfModel     *shelfModel;
@property (nonatomic, strong) DSA_ContentShelfConfig    *shelfConfig;
@property (nonatomic, strong) NSMutableArray            *layoutConstraints;

- (void)setBackgroundColors:(NSArray *)colors andLocations:(NSArray *)locations;
- (void)setBorderThickness:(NSArray *)borderThickness color:(UIColor *)borderColor;
@end
