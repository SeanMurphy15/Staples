//
//  ZM_CreateFavoriteShelfController.m
//  Zimmer
//
//  Created by Ben Gottlieb on 5/12/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "DSA_CreateFavoriteShelfController.h"
#import "MMSF_ContentVersion.h"
#import "DSA_ContentShelvesModel.h"

@interface DSA_CreateFavoriteShelfController ()
@property (nonatomic, assign) BOOL renameMode;
@property (nonatomic, strong) NSString* originalShelfName;
@end

@implementation DSA_CreateFavoriteShelfController
@synthesize nameField;
@synthesize createButton;
@synthesize itemToAdd;

static UIPopoverController			*s_popoverController = nil;

- (void) awakeFromNib
{
    self.renameMode = NO;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Factory

+ (id) controller {
	DSA_CreateFavoriteShelfController		*controller = [[DSA_CreateFavoriteShelfController alloc] init];
	
	return controller;
}

+ (void) showFromButton: (UIView *) button withItemToAdd: (MMSF_ContentVersion *) item {
	DSA_CreateFavoriteShelfController		*controller = [self controller];
	
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: controller];
	s_popoverController.delegate = controller;
	controller.itemToAdd = item;
	s_popoverController.popoverContentSize = controller.view.bounds.size;
	
	[s_popoverController presentPopoverFromRect: [button bounds] inView: button permittedArrowDirections: UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated: YES];
}

+ (void) showFromBarButtonItem: (UIBarButtonItem *) buttonItem withItemToAdd: (MMSF_ContentVersion *) item {
	DSA_CreateFavoriteShelfController		*controller = [self controller];
	
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: controller];
	s_popoverController.delegate = controller;
	controller.itemToAdd = item;
	s_popoverController.popoverContentSize = controller.view.bounds.size;
	
	[s_popoverController presentPopoverFromBarButtonItem: buttonItem permittedArrowDirections: UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated: YES];
}

+ (void) showFromRect:(CGRect) rect inView:(UIView*) view forRename:(NSString*) currentName
{
	DSA_CreateFavoriteShelfController		*controller = [self controller];
	
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: controller];
	s_popoverController.delegate = controller;
	//controller.itemToAdd = item;
	s_popoverController.popoverContentSize = controller.view.bounds.size;
	[controller.createButton setTitle:@"Rename Shelf" forState:UIControlStateNormal];
    controller.nameField.text = currentName;
    controller.renameMode = YES;
    controller.originalShelfName = currentName;
    
	[s_popoverController presentPopoverFromRect: rect inView: view permittedArrowDirections: UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated: YES];
}

+ (BOOL) delayForScrollAdjustmentWithView: (UIView *) view {
	CGRect				frameInWindow = [view convertRect: view.bounds toView: view.superview];
	float				height = view.window.bounds.size.height;
	
	if (frameInWindow.origin.y > height / 2) {
//		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_WillShowTextField object: $F(320)];
		return YES;
	}
	return NO;
}

#pragma mark - View LifeCycle

- (void) viewWillAppear: (BOOL) animated {
	[super viewWillAppear: animated];
    
	[self.nameField becomeFirstResponder];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return YES; }

#pragma mark - Actions

- (IBAction) create: (id) sender {
    NSString *trimmedShelfName = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (self.renameMode)
    {
        if (trimmedShelfName.length)
        {
            [[DSA_ContentShelvesModel sharedModel] renameShelf:self.originalShelfName to:trimmedShelfName];
            [s_popoverController dismissPopoverAnimated: YES];
        }
    }
    else
    {
        DSA_ContentShelfModel *shelf = [[DSA_ContentShelvesModel sharedModel] createShelfNamed:trimmedShelfName updateLayout:YES animated:NO];
        if (shelf && self.itemToAdd)
        {
            [[DSA_ContentShelvesModel sharedModel] addContentItemId:self.itemToAdd.Id toShelf:trimmedShelfName updateLayout:YES animated:NO];
        }
        [s_popoverController dismissPopoverAnimated: YES];
    }
}

#pragma mark - delegate

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) controller {
	s_popoverController = nil;
}

- (BOOL) textFieldShouldReturn: (UITextField *) field {
	[self create: nil];
	return NO;
}


@end
