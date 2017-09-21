//
//  SB_RecordListViewController.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/21/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "MM_Headers.h"
#import "SB_RecordListViewController.h"
#import "SB_AppDelegate.h"
#import "MM_SyncManager.h"

@implementation SB_RecordListViewController
@synthesize recordsTableView, entityName = _entityName;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}




//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	SB_RecordListViewController		*controller = [[SB_RecordListViewController alloc] init];
	
	[controller addAsObserverForName: kNotification_EntityTypeSelected selector: @selector(entitySelected:)];
	[controller addAsObserverForName: kNotification_ObjectsImported selector: @selector(objectsImported:)];
	[controller addAsObserverForName: kNotification_ObjectsDeleted selector: @selector(objectsImported:)];
	[controller addAsObserverForName: kNotification_SyncComplete selector: @selector(syncComplete)];
	
	
	controller.title = @"Records";
	
	return controller;
}

+ (id) wrappedController { 
	SB_RecordListViewController		*controller = [self controller];
	
	UINavigationController			*nav = [[UINavigationController alloc] initWithRootViewController: controller];
	
	nav.navigationBar.barStyle = UIBarStyleBlack;
	nav.navigationBar.titleTextAttributes = $D([UIColor greenColor], UITextAttributeTextColor);
	return nav;
}

+ (id) controllerForEntityName: (NSString *) entityName {
	SB_RecordListViewController		*controller = [self controller];
	
	controller.entityName = entityName;
	
	return controller;
	
}

//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	self.recordsTableView.backgroundColor = [UIColor blackColor];
	self.recordsTableView.separatorColor = [UIColor greenColor];
	
	self.recordsTableView.oddColumnBackgroundColor = [UIColor blackColor];
	self.recordsTableView.evenColumnBackgroundColor = [UIColor darkGrayColor];
	self.recordsTableView.oddColumnTextColor = [UIColor greenColor];
	self.recordsTableView.evenColumnTextColor = [UIColor greenColor];
	
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemRefresh target: self action: @selector(sync:)];
	[super viewDidLoad];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return UIInterfaceOrientationIsPortrait(interfaceOrientation) || RUNNING_ON_IPAD; }

//=============================================================================================================================
#pragma mark Properties
- (void) setEntityName:(NSString *)entityName {
	[self view];				//make sure the table's been instantiated
	_entityName = entityName;
	self.recordsTableView.entityName = entityName;
	self.title = $S(@"%@ (%d)", self.entityName, self.recordsTableView.records.count);
}


//=============================================================================================================================
#pragma mark Actions

- (IBAction) sync: (id) sender {
	if (self.entityName == nil) return;
	
    
	if (![[MM_OrgMetaData sharedMetaData] isObjectSynced: self.entityName]) {
		[[MM_OrgMetaData sharedMetaData] addObjectToSyncList: self.entityName];
	}
	
	[[MM_SyncManager sharedManager] fetchRequiredMetaData: NO withCompletionBlock: ^{
		[[MM_SyncManager sharedManager] synchronize: $A([MM_SFObjectDefinition objectNamed: self.entityName inContext: [MM_ContextManager sharedManager].mainMetaContext]) withCompletionBlock: nil];
	}];
}

//=============================================================================================================================
#pragma mark Notifications
- (void) entitySelected: (NSNotification *) note {
	self.entityName = note.object;
	
	if (self.recordsTableView.records.count == 0) {
		[self sync: nil];
	}
}

- (void) objectsImported: (NSNotification *) note {
	NSString				*name = [note.userInfo objectForKey: @"name"];
	
	if (name == nil) {
		return;
	}
	self.title = $S(@"Imported %@ (%d)", name, [note.object count]);
}

- (void) syncComplete {
	self.title = @"Records";
	[self.recordsTableView reloadRecords];
}




@end
