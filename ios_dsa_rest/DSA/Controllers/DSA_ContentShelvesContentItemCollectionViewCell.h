//
//  DSA_ContentShelvesCollectionViewCell.h
//  DSA
//
//  Created by Mike Close on 7/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_ContentVersion.h"
#import "DSA_ContentShelvesModel.h"
#import "DSA_ContentShelvesConfig.h"

@interface DSA_ContentShelvesContentItemCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) NSString                  *itemId;
@property (nonatomic, strong) DSA_ContentShelfModel     *shelfModel;
@property (nonatomic, strong) DSA_ContentShelfConfig    *shelfConfig;
@end
