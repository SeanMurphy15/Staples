//
//  RS_ObjectDetailsEditorViewController.h
//  RESTStarter
//
//  Created by Ben Gottlieb on 5/28/14.
//  Copyright (c) 2014 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RS_ObjectDetailsEditorViewController : UIViewController

+ (id) controllerWithObject: (MMSF_Object *) object toEditFields: (NSArray *) fields;

@property (nonatomic, strong) MMSF_Object *object;
@property (nonatomic, strong) NSArray *fields;
@end
