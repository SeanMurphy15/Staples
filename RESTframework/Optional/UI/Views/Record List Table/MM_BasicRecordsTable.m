//
//  MM_BasicRecordsTable.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/30/11.
//  Copyright (c) 2011 Stand Alone, Inc. All rights reserved.
//

#import "MM_BasicRecordsTable.h"
#import "MM_ScrollableColumnsView.h"

@interface MM_BasicRecordsTable ()
- (void) setup;

@end

@implementation MM_BasicRecordsTable
@synthesize records, context, entityName = _entityName, sortField, objectDefinition;
@synthesize evenColumnBackgroundColor, oddColumnBackgroundColor, evenColumnTextColor, oddColumnTextColor, contentFont, headerFont;

- (id) initWithCoder: (NSCoder *) aDecoder {
	if ((self = [super initWithCoder: aDecoder])) {
		[self setup];
	}
	return self;
}

- (void) dealloc {
	[self removeAsObserver];
}

//=============================================================================================================================
#pragma mark Properties
- (void) setEntityName:(NSString *)entityName {
	_entityName = entityName;
	self.sortField = @"Id";
	self.objectDefinition = [MM_SFObjectDefinition objectNamed: self.entityName inContext: [MM_ContextManager sharedManager].mainMetaContext];
	[self reloadRecords];
}

//=============================================================================================================================
#pragma mark Actions

- (void) reloadRecords {
	if (self.entityName && [[MM_ContextManager sharedManager] objectExistsInContentModel: self.entityName]) {
		self.objectDefinition = [MM_SFObjectDefinition objectNamed: self.entityName inContext: [MM_ContextManager sharedManager].mainMetaContext];
		self.context = [[MM_ContextManager sharedManager] contentContextForWriting];
		self.records = [context allObjectsOfType: self.entityName matchingPredicate: nil sortedBy: [NSSortDescriptor arrayWithDescriptorWithKey: self.sortField ascending: YES]];
    
        
	} else {
		self.records = nil;
	}
	
	[self reloadData];
}

- (void) setup {
	self.delegate = self;
	self.dataSource = self;

	self.evenColumnTextColor = [UIColor blackColor];
	self.oddColumnTextColor = [UIColor blackColor];
	self.evenColumnBackgroundColor = [UIColor whiteColor];
	self.oddColumnBackgroundColor = [UIColor lightGrayColor];

	[self addAsObserverForName: kNotification_ObjectsImported selector: @selector(objectsImported:)];
}

//=============================================================================================================================
#pragma mark Notifications
- (void) objectsImported: (NSNotification *) note {
	NSString				*name = [note.userInfo objectForKey: @"name"];
	
	if ([name isEqual: self.entityName]) [self reloadRecords];
}

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	//   NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath: indexPath];
	NSString								*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	MM_ScrollableColumnsView				*view;
	MMSF_Object								*record = [self.records objectAtIndex: indexPath.row];
	
	if (cell == nil) { 
		cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier] autorelease];
		
		CGRect				bounds = cell.contentView.bounds;
		
		view = [MM_ScrollableColumnsView viewWithFrame: bounds displayingObject: record ofType: self.objectDefinition];
		
		view.tag = 501;
		view.evenColumnTextColor = self.evenColumnTextColor;
		view.oddColumnTextColor = self.oddColumnTextColor;
		view.evenColumnBackgroundColor = self.evenColumnBackgroundColor;
		view.oddColumnBackgroundColor = self.oddColumnBackgroundColor;
		view.backgroundColor = self.backgroundColor;
		[cell.contentView addSubview: view];
	} else {
		view = (id) [cell.contentView viewWithTag: 501];
		
		view.objectDefinition = self.objectDefinition;
        
		view.object = record;	
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
	return self.records.count;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section {
	return 32;
}

- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) sectionIndex {
	MM_ScrollableColumnsView		*view = [MM_ScrollableColumnsView headerViewWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 32) displayingObjectType: self.objectDefinition];
	
	view.evenColumnTextColor = self.evenColumnTextColor;
	view.oddColumnTextColor = self.oddColumnTextColor;
	view.evenColumnBackgroundColor = self.evenColumnBackgroundColor;
	view.oddColumnBackgroundColor = self.oddColumnBackgroundColor;
	view.backgroundColor = self.backgroundColor;
	return view;
}


@end
