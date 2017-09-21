//
//  MM_PickListViewController.h
//  WorkProducts
//
//  Created by Ben Gottlieb on 12/24/13.
//  Copyright (c) 2013 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMSF_Object;

@interface MM_PickListViewController : UITableViewController

+ (id) controllerForPickingField: (NSString *) field inRecord: (MMSF_Object *) object completion: (idArgumentBlock) completion;

@property (nonatomic, strong) NSString *relatedRecordFieldString;
@property (nonatomic, strong) NSPredicate *relatedRecordPredicate;

- (void) loadPickOptions;

@end
