//
//  IP_ShoppingCartViewController.m
//  CareFusion
//
//  Created by Ben Gottlieb on 3/29/12.
//  Copyright 2012 Stand Alone, Inc. All rights reserved.
//

#import "IP_ShoppingCartViewController.h"
#import "SF_ContentItem (ShoppingCart).h"
#import "SF_Store.h"
#import "DSA_AppDelegate.h"

@implementation IP_ShoppingCartViewController
@synthesize attachedDocumentsHeader, linkedDocumentsHeader, recentHeader;
@synthesize attachedDocumentsLabel, linkedDocumentsLabel, attachedSizelabel;
@synthesize cartTableView, cartLinks, cartAttachments, recentItems, topToolbar;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[cartTableView release];
	self.cartLinks = nil;
	self.cartAttachments = nil;
	self.recentItems = nil;
	self.attachedDocumentsHeader = nil;
	self.linkedDocumentsHeader = nil;
	self.recentHeader = nil;
    [super dealloc];
}



//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	IP_ShoppingCartViewController		*controller = [[[IP_ShoppingCartViewController alloc] init] autorelease];
	
	controller.tabBarItem = [[[UITabBarItem alloc] initWithTitle: @"Cart" image: [UIImage imageNamed: @"cart.png"] tag: 0] autorelease];
	
	return controller;
}


//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	[super viewDidLoad];	
}

- (void) viewWillAppear: (BOOL) animated {
	[super viewDidAppear: animated];
	[self reloadCartDisplay: YES];
	[self setupToolbar];
}

//- (void) viewDidAppear: (BOOL) animated {
//	[super viewDidAppear: animated];
//}

//- (void) viewWillDisappear: (BOOL) animated {
//	[super viewWillDisappear: animated];
//}

//- (void) viewDidDisappear: (BOOL) animated {
//	[super viewDidDisappear: animated];
//}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return YES; }

//=============================================================================================================================
#pragma mark Properties


//=============================================================================================================================
#pragma mark Actions
- (void) reloadCartDisplay: (BOOL) reloadTable {
	self.cartAttachments = [NSMutableArray array];
	self.cartLinks = [NSMutableArray array];
	
	NSArray					*cartItems = [[SF_Store store].context allObjectsOfType: [SF_ContentItem entityName] matchingPredicate: $P(@"currentlyInCart == YES")];
	CGFloat					attachedSize = 0.0;
	
	for (SF_ContentItem *item in cartItems) {
		[self.cartAttachments addObject: item];
		attachedSize += item.fileSize;
	}
	
	self.attachedSizelabel.text = $S(@"Current attachements total: %.1f MB", attachedSize / (1024 * 1024));
	
	if (reloadTable) [self.cartTableView reloadData];
}

- (void) setupToolbar {
	NSMutableArray								*items = [NSMutableArray array];
	__block IP_ShoppingCartViewController		*controller = self;
	
	[items addObject: [UIBarButtonItem itemWithTitle: @"Home" block: ^(id arg) { g_appDelegate.baseViewController.selectedIndex = 0; }]];
	[items addObject: [UIBarButtonItem flexibleSpacer]];
	 
	 if (self.cartTableView.editing) {
		 [items addObject: [UIBarButtonItem itemWithTitle: @"Clear Cart" block: ^(id arg) { 
			 static UIActionSheet				*sheet = nil;
			 
			 if (sheet) {
				 [sheet dismissWithClickedButtonIndex: sheet.cancelButtonIndex animated: YES];
				 sheet = nil;
				 return;
			 }
			 
			 sheet = [[UIActionSheet alloc] initWithTitle: nil delegate: nil cancelButtonTitle: @"Cancel" destructiveButtonTitle: @"Remove All From Cart" otherButtonTitles: @"Cancel", nil];
			 
			 [sheet showFromBarButtonItem: arg withButtonSelectedBlock: ^(int selected) {
				 if (selected == sheet.destructiveButtonIndex) {
					 NSArray					*cartItems = [[SF_Store store].context allObjectsOfType: [SF_ContentItem entityName] matchingPredicate: $P(@"currentlyInCart == YES")];
					 
					 for (SF_ContentItem *item in cartItems) {
						 item.currentlyInCart = NO;
					 }
					 
					 [[SF_Store store].context save];
					 [controller reloadCartDisplay: YES];
					 [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ShoppingCartContentsChanged object: nil];
					 [controller.cartTableView setEditing: NO animated: YES];
					 [controller setupToolbar];
				 }
				 sheet = nil;
			 }];
		 }]];
		 
		 [items addObject: [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemDone block: ^(id arg) {
			 [controller.cartTableView setEditing: NO animated: YES];
			 [controller setupToolbar];
		 }]];
	 } else if (self.cartAttachments.count || self.cartLinks.count) {
		 [items addObject: [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemEdit block: ^(id arg) {
			 [controller.cartTableView setEditing: YES animated: YES];
			 [controller setupToolbar];
		 }]];
		 [items addObject: [UIBarButtonItem itemWithTitle: @"Email" block: ^(id arg) {

		 }]];
	 }
	
	self.topToolbar.items = items;
}
//=============================================================================================================================
#pragma mark Notifications

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSString								*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	SF_ContentItem							*item = nil;
	UIButton								*cartButton = nil;
	
	switch (indexPath.section) {
		case 0: item = [self.cartAttachments objectAtIndex: indexPath.row]; break;
		case 1: item = [self.cartLinks objectAtIndex: indexPath.row]; break;
		case 2: item = [self.recentItems objectAtIndex: indexPath.row]; break;
		default: break;
	}
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier] autorelease];
		cell.backgroundColor = [UIColor clearColor];
		cell.contentView.backgroundColor = [UIColor clearColor];
		
		UIImage					*image = [[UIImage imageNamed: @"content_item_table_cell_background.png"] stretchableImageWithLeftCapWidth: 36 topCapHeight: 31];
		UIImageView				*imageView = [[[UIImageView alloc] initWithFrame: cell.bounds] autorelease];
		
		imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		imageView.contentMode = UIViewContentModeScaleToFill;
		imageView.image = image;
		cell.backgroundView = imageView;
		
		image = [[UIImage imageNamed: @"content_item_table_cell_background_highlighted.png"] stretchableImageWithLeftCapWidth: 36 topCapHeight: 31];
		imageView = [[[UIImageView alloc] initWithFrame: cell.bounds] autorelease];
		
		imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		imageView.contentMode = UIViewContentModeScaleToFill;
		imageView.image = image;
		cell.selectedBackgroundView = imageView;
		
	//	cell.accessoryView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"disclosure_white.png"]] autorelease];
		
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.textColor = [UIColor whiteColor];
		
		cartButton = [UIButton buttonWithType: UIButtonTypeCustom];
		cartButton.tag = 1054;
		cartButton.bounds = CGRectMake(0, 0, 40, 40);
		cartButton.showsTouchWhenHighlighted = YES;
		cartButton.center = CGPointMake(cell.bounds.size.width - 70, cell.bounds.size.height / 2);
		cartButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[cell addSubview: cartButton];
	} else {
		cartButton = (id) [cell viewWithTag: 1054];
	}
	cell.textLabel.text = item.title;
	cell.imageView.image = [item.tableCellImage scaledImageOfSize: CGSizeMake(25, 25)];
	
	if (indexPath.section == 2) {
		cartButton.hidden = NO;
		[cartButton removeTarget: nil action: nil forControlEvents: UIControlEventTouchUpInside];
		[cartButton setImage: [UIImage imageNamed: item.currentlyInCartValue ? @"AddedToCart.png" : @"AddToCart.png"] forState: UIControlStateNormal];
		[cartButton addTarget: item action: @selector(toggleCartStatus:) forControlEvents: UIControlEventTouchUpInside];
	} else {
		cartButton.hidden = YES;
	}
	
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	//return [[self.fetchedResultsController sections] count];
	return 3;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	if (section == 0) return self.cartAttachments.count;
	if (section == 1) return self.cartLinks.count;
	if (section == 2) return self.recentItems.count;
	return 0;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) sectionIndex {
	if (sectionIndex == 0) return self.attachedDocumentsHeader;
	if (sectionIndex == 1) return self.linkedDocumentsHeader;
	if (sectionIndex == 2) return self.recentHeader;
	return nil;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section {
	if (section == 0) return self.attachedDocumentsHeader.bounds.size.height;
	if (section == 1) return self.linkedDocumentsHeader.bounds.size.height;
	if (section == 2) return self.recentHeader.bounds.size.height;
	return 0;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section < 2 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}
- (NSString *) tableView: (UITableView *) tableView titleForDeleteConfirmationButtonForRowAtIndexPath: (NSIndexPath *) indexPath {
	return @"Remove From Cart";
}

- (void) tableView: (UITableView *) tableView commitEditingStyle: (UITableViewCellEditingStyle) editingStyle forRowAtIndexPath: (NSIndexPath *) indexPath {
	SF_ContentItem			*item = nil;
	
	if (indexPath.section == 0) {
		item = [self.cartAttachments objectAtIndex: indexPath.row];
	} else if (indexPath.section == 1) {
		item = [self.cartLinks objectAtIndex: indexPath.row];
	}
	
	item.currentlyInCart = NO;
	[item save];
	[tableView beginUpdates];
	[tableView deleteRowsAtIndexPaths: $A(indexPath) withRowAnimation: UITableViewRowAnimationTop];
	
	[self reloadCartDisplay: NO];
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ShoppingCartContentsChanged object: nil];
	[tableView endUpdates];
}

/*
 - (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
 return 44;
 }
 
 - (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section {
 return nil;
 }
 
 - (UIView *) tableView: (UITableView *) tableView viewForFooterInSection: (NSInteger) sectionIndex {
 return nil;
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
