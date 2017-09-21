//
//  DSA_ContentShelvesViewController.h
//  DSA
//
//  Created by Mike Close on 7/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LXReorderableCollectionViewFlowLayout.h"
#import "DSA_ContentShelvesModel.h"
#import "DSA_MediaDisplayViewController.h"

@interface DSA_ContentShelvesController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, LXReorderableCollectionViewDataSource, DSAContentShelvesModelDelegate, UIAlertViewDelegate, DSA_MediaDisplayViewControllerDelegate>


@property (strong, nonatomic) DSA_ContentShelvesConfig *config;

+ (instancetype)controller;

/*
 *
 * Designated initializer - use this
 *
 */
- (id)initWithConfigPath:(NSString *)path;

- (void)reloadData;
- (void)insertSections:(NSIndexSet *)sections;
- (BOOL)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (BOOL)deleteItemsAtIndexPaths:(NSArray *)indexPaths;

@end