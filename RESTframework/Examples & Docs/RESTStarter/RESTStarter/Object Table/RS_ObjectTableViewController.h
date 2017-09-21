//
//  RS_ObjectTableViewController.h
//  RESTStarter
//
//  Created by Ben Gottlieb on 5/27/14.
//  Copyright (c) 2014 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RS_ObjectTableViewController : UITableViewController

@property (nonatomic, strong) NSString *objectName, *displayField;

+ (instancetype) controllerWithObject: (NSString *) objectName displayField: (NSString *) field;

@end
