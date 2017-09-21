//
//  SB_ObjectListViewController.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/21/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "SB_ObjectListViewController.h"
#import "MM_Headers.h"
#import "SB_AppDelegate.h"
#import "SB_RecordListViewController.h"
#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"

@implementation SB_ObjectListViewController
@synthesize objectsTableView, objects, context, filter, filterHolderView, filterControl;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}



//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	SB_ObjectListViewController		*controller = [[SB_ObjectListViewController alloc] init];
	
	[controller addAsObserverForName: kNotification_ObjectDefinitionsImported selector: @selector(setupObjectsList)];
	[controller addAsObserverForName: kNotification_LoginComplete selector: @selector(loginComplete)];
	[controller addAsObserverForName: kNotification_ModelUpdateBegan selector: @selector(modelUpdateBegan)];
	[controller addAsObserverForName: kNotification_SyncComplete selector: @selector(modelUpdateComplete)];
	
	controller.title = @"Objects";
	
	UINavigationController			*nav = [[UINavigationController alloc] initWithRootViewController: controller];
	
	nav.navigationBar.barStyle = UIBarStyleBlack;
	nav.navigationBar.titleTextAttributes = $D([UIColor greenColor], UITextAttributeTextColor);
	return nav;
}


//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	self.objectsTableView.backgroundColor = [UIColor blackColor];
	self.objectsTableView.separatorColor = [UIColor greenColor];
	self.filterControl.selectedSegmentIndex = self.filter;
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem itemWithTitle: @"Log Out" target: self action: @selector(logOut:)];
	self.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithTitle: @"All" target: self action: @selector(getAll:)];
	[super viewDidLoad];
}

//- (void) viewWillAppear: (BOOL) animated {
//	[super viewDidAppear: animated];
//}

- (void) viewDidAppear: (BOOL) animated {
	if (RUNNING_ON_IPAD) {
		[g_appDelegate presentLoginScreenFromBarButtonItem: self.navigationItem.leftBarButtonItem];
	} else {
		//	[g_appDelegate presentLoginScreenFromBarButtonItem: nil];
	}

	[self setupObjectsList];
	[super viewDidAppear: animated];
}

//- (void) viewWillDisappear: (BOOL) animated {
//	[super viewWillDisappear: animated];
//}

//- (void) viewDidDisappear: (BOOL) animated {
//	[super viewDidDisappear: animated];
//}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return UIInterfaceOrientationIsPortrait(interfaceOrientation) || RUNNING_ON_IPAD; }

//=============================================================================================================================
#pragma mark Properties


//=============================================================================================================================
#pragma mark Actions

- (void) logOut: (id) sender {
	[MM_LoginViewController logout];
	[g_appDelegate presentLoginScreenFromBarButtonItem: sender];
}

- (void) getAll: (id) sender {
	[[MM_OrgMetaData sharedMetaData] setAllObjectsToSync: [self.objects valueForKey: @"name"]];
	[[MM_SyncManager sharedManager] fetchRequiredMetaData: NO withCompletionBlock: nil];
//	[[MM_SyncManager sharedManager] synchronize: nil withCompletionBlock: nil];
}

- (IBAction) changeFilter: (id) sender {
	self.filter = self.filterControl.selectedSegmentIndex;
	[self setupObjectsList];
	[self.objectsTableView reloadData];
}

//=============================================================================================================================
#pragma mark Notifications
- (void) loginComplete {
	if (![[MM_OrgMetaData sharedMetaData] isMetadataAvailableForObjects: nil]) {
		[[MM_SyncManager sharedManager] downloadObjectDefinitionsWithCompletionBlock: ^{
			
		}];
	} else {
		[[MM_SyncManager sharedManager] fetchRequiredMetaData: NO withCompletionBlock: nil];
	}
	[[MM_SFObjectDefinition objectNamed: @"Customer_Request__c" inContext: nil] describeLayout];
//	[[MM_SFObjectDefinition objectNamed: @"Customer_Request__c" inContext: nil] describeLayoutWithCompletionBlock: ^(id result) { LOG(@"%@", result); }];
}

- (void) modelUpdateBegan {
	self.objectsTableView.alpha = 0.7;
}

- (void) modelUpdateComplete {
	self.objectsTableView.alpha = 1.0;
	[self.objectsTableView reloadData];
}

//=============================================================================================================================
#pragma mark Setup
- (void) setupObjectsList {
	self.context = [[MM_ContextManager sharedManager] metaContextForWriting];
	NSArray				*allObjects = [self.context allObjectsOfType: [MM_SFObjectDefinition entityName] matchingPredicate: nil sortedBy: [NSSortDescriptor arrayWithDescriptorWithKey: @"name" ascending:YES]];
	NSMutableArray		*filtered;
	
	switch (self.filter) {
		case objectFilter_all: self.objects = allObjects; break;
		case objectFilter_synced:
		case objectFilter_content:
			filtered = [NSMutableArray arrayWithCapacity: allObjects.count];
			for (MM_SFObjectDefinition *def in allObjects) {
				if ([[MM_OrgMetaData sharedMetaData] isObjectSynced: def.name] && (self.filter == objectFilter_synced || [[MM_ContextManager sharedManager].mainContentContext numberOfObjectsOfType: def.name matchingPredicate: nil])) {
					[filtered addObject: def];
				}
			}
			self.objects = filtered;
			break;
	}
	
	[self.objectsTableView reloadData];
}

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	//   NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath: indexPath];
	NSString							*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	
	if (cell == nil) { 
		cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier] autorelease];
	
		cell.textLabel.textColor = [UIColor greenColor];
		cell.textLabel.highlightedTextColor = [UIColor blackColor];
		cell.textLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		cell.selectedBackgroundView = [[UIView alloc] initWithFrame: cell.backgroundView.frame];
		cell.selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		cell.selectedBackgroundView.backgroundColor = [UIColor greenColor];
	}
	
	NSString						*name = [[self.objects objectAtIndex: indexPath.row] name];
	cell.textLabel.text = name;
	
	if ([[MM_OrgMetaData sharedMetaData] isObjectSynced: name]) {
		cell.accessoryView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"checkmark.png"]];
		
		NSUInteger			count = [[MM_ContextManager sharedManager].mainContentContext numberOfObjectsOfType: name matchingPredicate: nil];
		if (count) cell.textLabel.text = $S(@"%@ (%d)", name, (UInt16) count);
	} else {
		cell.accessoryView = nil;
	}
	
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	//return [[self.fetchedResultsController sections] count];
	return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	//	id <NSFetchedResultsSectionInfo>		sectionInfo = [[self.fetchedResultsController sections] objectAtIndex: section];
	//	return [sectionInfo numberOfObjects];
	return self.objects.count;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	NSString				*entityName = [[self.objects objectAtIndex: indexPath.row] name];
	
	if (![[MM_OrgMetaData sharedMetaData] isObjectSynced: entityName] && [MM_SyncManager sharedManager].isModelUpdateInProgress) {
		[SA_AlertView showAlertWithTitle: @"Model Update in Progress" message: @"Please wait until the current object has been fetched before attempting to add another to the model."];
		return;				//don't start another model update while one's going on
	}
	
	if (RUNNING_ON_IPAD) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_EntityTypeSelected object: entityName];
	} else {
		[self.navigationController pushViewController: [SB_RecordListViewController controllerForEntityName: entityName] animated: YES];
	}
}

/*
 - (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
 return 44;
 }
 
 - (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section {
 return nil;
 }
 
 - (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) sectionIndex {
 return nil;
 }
 
 - (UIView *) tableView: (UITableView *) tableView viewForFooterInSection: (NSInteger) sectionIndex {
 return nil;
 }
 
 - (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section {
 return 0;
 }
 
 - (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section {
 return 0;
 }
 
 - (BOOL) tableView: (UITableView *) tableView canEditRowAtIndexPath: (NSIndexPath *) indexPath {
 return YES;
 }
 
 - (void) tableView: (UITableView *) tableView willBeginEditingRowAtIndexPath: (NSIndexPath *) indexPath {
 }
 
 - (void) tableView: (UITableView *) tableView didEndEditingRowAtIndexPath: (NSIndexPath *) indexPath {
 }
 */


@end
