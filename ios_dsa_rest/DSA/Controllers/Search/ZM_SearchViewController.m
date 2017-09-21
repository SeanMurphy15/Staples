    //
//  ZM_SearchViewController.m
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "ZM_SearchViewController.h"
#import "ZM_SearchResultsController.h"
#import "MM_Headers.h"

@implementation ZM_SearchViewController

+ (id) controller {
	ZM_SearchViewController			*controller = [[[self alloc] init] autorelease];
	UINavigationController			*navController = [[[UINavigationController alloc] initWithRootViewController: controller] autorelease];
	
	controller.tabBarItem = [[[UITabBarItem alloc] initWithTitle: @"Search" image: [UIImage imageNamed: @"search_tab.png"] tag: 0] autorelease];
	
	return navController;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation {return YES;}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration {
	[super willAnimateRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
	[self updateForOrientation: toInterfaceOrientation];
}

- (void) viewWillAppear: (BOOL) animated {
	[super viewWillAppear: animated];
	self.searchScopeControl.selectedSegmentIndex = 1;
	[self updateForOrientation: self.interfaceOrientation];
	[self.navigationController setNavigationBarHidden: YES];
	self.navigationController.navigationBar.tintColor = kTintColor;
	self.toolbar.tintColor = kTintColor;
	self.searchBar.tintColor = kTintColor;
}

- (void) viewDidAppear: (BOOL) animated {
	[super viewDidAppear: animated];
	//[self.searchBar becomeFirstResponder];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
	[self updateForOrientation: self.interfaceOrientation];
}


- (void) updateForOrientation: (UIInterfaceOrientation) newOrientation {
	if (newOrientation == UIDeviceOrientationUnknown) newOrientation = self.interfaceOrientation;
	
	CGRect					bounds = UIInterfaceOrientationIsPortrait(newOrientation) ? CGRectMake(0, 0, 768, 1004) : CGRectMake(0, 0, 1024, 748);
	float					searchWidth = bounds.size.width * 0.4;
	
	self.view.frame = bounds;
	self.searchBar.normalizedFrame = CGRectMake(bounds.size.width - searchWidth, 0, searchWidth, 44);
	self.navigationBar.normalizedFrame = CGRectMake(0, 0, bounds.size.width - searchWidth, 44);
}

//=============================================================================================================================
#pragma mark Search Delegate
- (void) searchBarSearchButtonClicked: (UISearchBar *) inSearchBar {
	NSString				*searchString = inSearchBar.text;
	NSArray					*results = nil;
	Class					resultsClass = [ZM_SearchResultsController class];
	//NSPredicate				*predicate = nil;
	
	/*if (self.searchScopeControl.selectedSegmentIndex == 0)
		results = [[SF_User currentUser] allEntitiesOfTyoe: [SF_Opportunity entityName] matchingPredicate: [SF_Opportunity searchPredicateForString: searchString]];
	else {
		predicate = [NSPredicate predicateWithFormat: @"(title CONTAINS[c] %@ OR tags CONTAINS[c] %@) && ((documentType == nil) OR (documentType != 'Competitive Information'))", searchString, searchString];
	//	predicate = [NSPredicate predicateWithFormat: @"(title CONTAINS[c] %@ OR tags CONTAINS[c] %@) && (documentType != 'Competitive Information')", searchString, searchString];
		results = [[SF_User currentUser] allDocumentsMatchingPredicate: predicate];
	}
	*/
	if (results.count) {
		[self.navigationController pushViewController: [resultsClass controllerWithSearchString: searchString andResults: results] animated: YES];
	} else {
		[SA_AlertView showAlertWithTitle: @"Sorry, your search turned up no results." message: nil];
	}
}
@end
