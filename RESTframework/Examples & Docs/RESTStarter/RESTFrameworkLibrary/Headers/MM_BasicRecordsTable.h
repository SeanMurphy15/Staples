//
//  MM_BasicRecordsTable.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/30/11.
//  Copyright (c) 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MM_Headers.h"

@interface MM_BasicRecordsTable : UITableView <UITableViewDelegate, UITableViewDataSource>


@property (nonatomic, strong) NSArray *records;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSString *entityName, *sortField;
@property (nonatomic, strong) MM_SFObjectDefinition *objectDefinition;

@property (nonatomic, strong) UIColor *evenColumnBackgroundColor, *oddColumnBackgroundColor, *evenColumnTextColor, *oddColumnTextColor;
@property (nonatomic, strong) UIFont *headerFont, *contentFont;

- (void) reloadRecords;

@end
