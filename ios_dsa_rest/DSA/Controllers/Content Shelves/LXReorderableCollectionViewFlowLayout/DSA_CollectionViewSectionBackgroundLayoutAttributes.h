//
//  DSA_CollectionViewSectionBackgroundLayoutAttributes.h
//  DSA
//
//  Created by Mike Close on 11/4/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DSA_ContentShelfModel;

@interface DSA_CollectionViewSectionBackgroundLayoutAttributes : UICollectionViewLayoutAttributes
@property (strong, nonatomic) DSA_ContentShelfModel *model;
@end
