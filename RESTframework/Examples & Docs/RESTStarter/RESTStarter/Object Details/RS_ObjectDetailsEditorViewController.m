//
//  RS_ObjectDetailsEditorViewController.m
//  RESTStarter
//
//  Created by Ben Gottlieb on 5/28/14.
//  Copyright (c) 2014 Model Metrics. All rights reserved.
//

#import "RS_ObjectDetailsEditorViewController.h"
#import "MM_RecordFieldsTable.h"

@interface RS_ObjectDetailsEditorViewController ()
@property (nonatomic, strong) MM_RecordFieldsTable *tableView;
@end

@implementation RS_ObjectDetailsEditorViewController
+ (id) controllerWithObject: (MMSF_Object *) object toEditFields: (NSArray *) fields {
	RS_ObjectDetailsEditorViewController		*controller = [self new];
	
	controller.object = object;
	controller.fields = fields;
	controller.title = object[@"Name"];
	controller.navigationItem.leftBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemDone target: controller action: @selector(dismiss:)];
	controller.navigationItem.rightBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemEdit target: controller action: @selector(edit:)];
	
	UINavigationController						*nav = [[UINavigationController alloc] initWithRootViewController: controller];
	
	nav.modalPresentationStyle = UIModalPresentationFormSheet;
	
	return nav;
}

- (UIRectEdge) edgesForExtendedLayout {return UIRectEdgeNone; }

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.tableView = [[MM_RecordFieldsTable alloc] initWithFrame: self.view.bounds];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview: self.tableView];
	
	MM_SFObjectDefinition   *def = self.object.definition;
	
	self.tableView.labelValueAlignment = MM_RecordLabelValueAlignment_left;
	self.tableView.object = self.object;
	self.tableView.edgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
	
	[self.tableView startNewSectionWithString: @""];
	
	for (NSString *fieldName in self.fields) {
		[self.tableView addRowWithLabel: [def labelForField: fieldName] forKeyPath: fieldName editable: YES];
	}
	
	if (self.object.isInserted) [self edit: nil];
}

- (void) dismiss: (id) sender {
	[self dismissViewControllerAnimated: YES completion: nil];
}

- (void) edit: (id) sender {
	[self.object beginEditing];
	[self.tableView beginEditing];
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancelEditing:)];
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemSave target: self action: @selector(endEditing:)];
}

- (void) endEditing: (id) sender {
	[self.tableView endEditingSavingChanged: YES];
	[self.object finishEditingSavingChanges: YES andPushingToServer: YES];
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemDone target: self action: @selector(dismiss:)];
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemEdit target: self action: @selector(edit:)];
	
	[NSNotificationCenter postNotificationNamed: kNotification_AccountEdited object: self.object];
}

- (void) cancelEditing: (id) sender {
	[self.tableView endEditingSavingChanged: NO];
	[self.object finishEditingSavingChanges: NO];
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemDone target: self action: @selector(dismiss:)];
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemEdit target: self action: @selector(edit:)];
}

@end
