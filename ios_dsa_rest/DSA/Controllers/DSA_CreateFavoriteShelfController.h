//
//  ZM_CreateFavoriteShelfController.h
//  Zimmer
//
//  Created by Ben Gottlieb on 5/12/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_ContentVersion.h"

//@class  SF_ContentItem;

@interface DSA_CreateFavoriteShelfController : UIViewController <UIPopoverControllerDelegate> {

	UITextField *nameField;
	UIButton *createButton;
}

@property (nonatomic, retain) IBOutlet UITextField *nameField;
@property (nonatomic, retain) IBOutlet UIButton *createButton;
@property (nonatomic, retain) MMSF_ContentVersion *itemToAdd;

+ (BOOL) delayForScrollAdjustmentWithView: (UIView *) view;

+ (id) controller;
+ (void) showFromButton: (UIView *) button withItemToAdd: (MMSF_ContentVersion *) item;
+ (void) showFromRect:(CGRect) rect inView:(UIView*) view forRename:(NSString*) currentName;
+ (void) showFromBarButtonItem: (UIBarButtonItem *) buttonItem withItemToAdd: (MMSF_ContentVersion *) item;
- (IBAction) create: (id) sender;

@end
