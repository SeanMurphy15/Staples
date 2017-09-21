//
//  SB_RecordListViewController.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/21/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MM_Headers.h"
#import "MM_BasicRecordsTable.h"

@interface SB_RecordListViewController : UIViewController {

}

@property (nonatomic, weak) IBOutlet MM_BasicRecordsTable *recordsTableView;
@property (nonatomic, retain) NSString *entityName;

+ (id) controller;
+ (id) wrappedController;
+ (id) controllerForEntityName: (NSString *) entityName;


@end
