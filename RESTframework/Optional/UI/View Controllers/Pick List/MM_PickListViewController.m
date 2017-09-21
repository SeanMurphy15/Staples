//
//  MM_PickListViewController.m
//  WorkProducts
//
//  Created by Ben Gottlieb on 12/24/13.
//  Copyright (c) 2013 Salesforce. All rights reserved.
//

#import "MM_PickListViewController.h"
#import "MMSF_Object.h"
#import "MM_SFObjectDefinition.h"

@interface MM_PickListViewController ()
@property (nonatomic, strong) MMSF_Object *object;
@property (nonatomic, strong) MM_SFObjectDefinition *definition;
@property (nonatomic, strong) NSString *field;
@property (nonatomic, strong) NSArray *pickOptions, *pickStrings;
@property (nonatomic) NSUInteger currentSelectedIndex;
@property (nonatomic) BOOL isRelationship;
@property (nonatomic, copy) idArgumentBlock completionBlock;
@end

@implementation MM_PickListViewController

+ (id) controllerForPickingField: (NSString *) field inRecord: (MMSF_Object *) object completion: (idArgumentBlock) completion {
	MM_PickListViewController			*controller = [[self alloc] init];
	
	controller.relatedRecordFieldString = @"Name";
	controller.completionBlock = completion;
	controller.field = field;
	controller.object = object;
	
	return controller;
}

//================================================================================================================
#pragma mark Properties
- (void) setObject: (MMSF_Object *) object {
	_object = object;
	self.definition = object.definition;
	
	NSEntityDescription				*desc = self.object.entity;
	
	self.isRelationship = (desc.relationshipsByName[self.field] != nil);
	
	[self loadPickOptions];
}

- (void) loadPickOptions {
	if (self.isRelationship) {
		NSRelationshipDescription				*relationship = self.object.entity.relationshipsByName[self.field];
		NSString								*name = relationship.inverseRelationship.entity.name;
		
		self.pickOptions = [self.object.moc allObjectsOfType: name matchingPredicate: self.relatedRecordPredicate sortedBy: [NSSortDescriptor SA_arrayWithDescWithKey:self.relatedRecordFieldString ascending: YES]];
		
		self.pickStrings = [self.pickOptions valueForKey: self.relatedRecordFieldString];
	} else {
		self.pickOptions = [self.definition picklistOptionsForField: self.field basedOffRecord: self.object];
		self.pickStrings = [self.pickOptions valueForKey: @"label"];
	}
}

- (CGSize) preferredContentSize { return CGSizeMake(320, self.pickStrings.count * 44); }

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	//   NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath: indexPath];
	NSString							*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier];
	cell.accessoryType = (indexPath.row == self.currentSelectedIndex) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.textLabel.text = self.pickStrings[indexPath.row];
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	//return [[self.fetchedResultsController sections] count];
	return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	//	id <NSFetchedResultsSectionInfo>		sectionInfo = [[self.fetchedResultsController sections] objectAtIndex: section];
	//	return [sectionInfo numberOfObjects];
	return self.pickStrings.count;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	if (self.isRelationship) {
		self.object[self.field] = self.pickOptions[indexPath.row];
	} else {
		self.object[self.field] = self.pickOptions[indexPath.row][@"value"];
	}
	
	if (self.completionBlock) self.completionBlock(self.pickOptions[indexPath.row]);
	[self.SA_PopoverController dismissSA_PopoverAnimated: YES];
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
