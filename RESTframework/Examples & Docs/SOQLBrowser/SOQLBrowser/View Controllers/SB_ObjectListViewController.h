//
//  SB_ObjectListViewController.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/21/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, objectFilter) {
	objectFilter_all,
	objectFilter_synced,
	objectFilter_content
};

@interface SB_ObjectListViewController : UIViewController {

}

@property (nonatomic, weak) IBOutlet UITableView *objectsTableView;
@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSArray *objects;
@property (nonatomic, weak) IBOutlet UIView *filterHolderView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *filterControl;
@property (nonatomic) objectFilter filter;

+ (id) controller;


- (IBAction) changeFilter: (id) sender;

- (void) setupObjectsList;
@end
