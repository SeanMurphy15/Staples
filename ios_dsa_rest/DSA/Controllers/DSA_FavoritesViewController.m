//
//  DSA_FavoritesViewController.m
//  Zimmer
//
//  Created by Ben Gottlieb on 4/28/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "DSA_FavoritesViewController.h"
#import "MMSF_Category__c.h"
#import "DSA_LibraryShelfView.h"
#import "DSA_LibraryShelfItemView.h"
#import "MMSF_ContentVersion.h"
#import "DSA_LibraryShelfHeaderView.h"
#import "DSA_FavoriteShelf.h"
#import "DSA_CreateFavoriteShelfController.h"
#import "MMSF_MobileAppConfig__c.h"
#import "MM_ContextManager.h"
#import "MMSF_User.h"
#import "DSA_AppDelegate.h"
#import "DSA_BaseTabsViewController.h"

#define kHiddenCategoryName						@"Zip Files (Hidden)"

#define kUnselectedCategoryButtonColor			[UIColor grayColor]

@implementation DSA_FavoritesViewController
@synthesize sliderBackground;
@synthesize toolbar;
@synthesize searchBar;
@synthesize filterSegments;
@synthesize categoryScroller;
@synthesize subcategoryLabel;
@synthesize shelvesTable;
@synthesize currentCategory, currentSubCategory;
@synthesize documentsByType, shelfNames, filteredDocumentsByType, filteredShelfNames, backButtonRemoved;
@synthesize showingContent, showingFavorites, showingSalesPhase, allContentImageView;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}



//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	DSA_FavoritesViewController		*controller = [[[DSA_FavoritesViewController alloc] init] autorelease];
	
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(subcategorySelected:) name: kNotification_ContentLibraryCategorySelected object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(subcategoryCancelled:) name: kNotification_ContentLibraryCategoryCancelled object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(favoritesChanged:) name: kNotification_FavoriteShelfCreated object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(favoritesChanged:) name: kNotification_FavoriteShelfDeleted object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(favoritesChanged:) name: kNotification_FavoriteShelfRenamed object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(favoritesChanged:) name: kNotification_FavoriteItemDeleted object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(favoritesChanged:) name: kNotification_FavoriteItemCreated object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(keyboardWillShow:) name: kNotification_WillShowTextField object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(showAllItems) name: UIApplicationWillEnterForegroundNotification object: nil];
    
	controller.tabBarItem = [[[UITabBarItem alloc] initWithTitle: @"Favorites" image: [UIImage imageNamed: @"star.png"] tag: 1] autorelease];
	UINavigationController				*nav = [[[UINavigationController alloc] initWithRootViewController: controller] autorelease];
	
	nav.navigationBarHidden = YES;
	return nav;
}


//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	[super viewDidLoad];
    self.title = @"Favorites";
    self.showingFavorites = YES;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
	[self populateCategoryScroller];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
        self.toolbar.tintColor = [mac buttonTextColor];
        self.toolbar.barTintColor = [mac titleBarColor];
    }
    
	self.currentSubCategory = nil;
//	self.view.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"carbon-fiber-background.png"]];
//	self.sliderBackground.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed: @"filter-region-background.png"]];
    //	[self.toolbar addMenuButtonWithTarget: self action: @selector(showMenu:)];
    
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        CGFloat statusBarHeight = (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ?
                                   [[UIApplication sharedApplication] statusBarFrame].size.width :
                                   [[UIApplication sharedApplication] statusBarFrame].size.height);
        
        for (UIView *subview in self.view.subviews) {
            
            CGRect   frame  = subview.frame;
            CGFloat  height = frame.origin.y + frame.size.height;
            
            frame.origin.y += statusBarHeight;
            
            if (height == self.view.frame.size.height)
                frame.size.height -= statusBarHeight;
            
            [subview setFrame: frame];
        }
        
        UIView *statusBarBackgroundView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, statusBarHeight)];
        [statusBarBackgroundView setBackgroundColor: [[UIColor blackColor] colorWithAlphaComponent: 0.67]];
        [statusBarBackgroundView setAutoresizingMask: (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
        [self.view insertSubview: statusBarBackgroundView atIndex: 0];
        
        
        /*  Create empty footer view for table to keep bottom table content from being stuck behind
            the tab bar.
         */
        
        UIView *footerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.shelvesTable.bounds.size.width, kTabWidth)];
        [footerView setBackgroundColor: [UIColor clearColor]];
        [self.shelvesTable setTableFooterView: footerView];
    }
}

- (void) viewWillAppear: (BOOL) animated {
	
	[self updateBackButton];
	[super viewWillAppear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return YES; }

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

//=============================================================================================================================
#pragma mark Properties

- (void) setCurrentSubCategory: (MMSF_Category__c *) newSubCategory {
	if ([newSubCategory isKindOfClass: [NSString class]]) newSubCategory = (id) [[MM_ContextManager sharedManager].contentContextForReading anyObjectOfType: [MMSF_Category__c entityName] matchingPredicate: $P(@"name == %@", newSubCategory)];
	if (newSubCategory.sortedSubcategories.count == 0) {
        //	if (newSubCategory.isEmpty) {
		newSubCategory = nil;
	}
    
	if (self.showingFavorites)
		self.subcategoryLabel.text = @"";
	else
		self.subcategoryLabel.text = self.currentSubCategory.Name;
	
	CGRect					bounds = self.view.bounds;
    
	self.filteredDocumentsByType = nil;
	self.filteredShelfNames = nil;
	[self.allContentImageView removeFromSuperview];
    
	if (self.showingFavorites) {
        CGFloat offset = self.toolbar.frame.origin.y + self.toolbar.frame.size.height;
		self.shelvesTable.frame = CGRectMake(0, offset, bounds.size.width, bounds.size.height - offset);
		self.subcategoryLabel.hidden = YES;
		self.sliderBackground.hidden = YES;
		self.categoryScroller.hidden = YES;
		
		if (self.showingFavorites) {
			self.shelfNames = [DSA_FavoriteShelf allShelfNames];
			self.documentsByType = [NSMutableDictionary dictionary];
            
			for (NSString *shelfName in self.shelfNames) {
				NSArray				*contents = [DSA_FavoriteShelf itemsForShelfName: shelfName];
				
				if (contents.count) [self.documentsByType setValue: contents forKey: shelfName];
			}
		} else {
			self.documentsByType = [NSMutableDictionary dictionary];
			[(NSMutableDictionary *) self.documentsByType removeObjectForKey: kHiddenCategoryName];
			self.shelfNames = [self.documentsByType allKeys];
			
		}
	} else {
		self.shelvesTable.frame = CGRectMake(0, 110, bounds.size.width, bounds.size.height - 110);
		if (self.showingSalesPhase && self.currentSubCategory) {
			self.documentsByType = [self documentsFilteredBySalesPhase:self.currentSubCategory.sortedContents];
            
			self.shelfNames = [[self.documentsByType allKeys] sortedArrayUsingComparator: ^(id obj1, id obj2) {
				static NSArray						*fixedCategories = nil;
				if (fixedCategories == nil) fixedCategories = $A(@"Selling Points", @"Clinical Relevance", @"Shaping the Conversation", @"Overcoming Objections", @"None");
				
				NSInteger							obj1Pos = [fixedCategories indexOfObject: obj1], obj2Pos = [fixedCategories indexOfObject: obj2];
				
				if (obj1Pos == NSNotFound && obj2Pos == NSNotFound) return [obj1 compare: obj2];
				if (obj1Pos == NSNotFound) return (NSComparisonResult) NSOrderedDescending;
				if (obj2Pos == NSNotFound) return (NSComparisonResult) NSOrderedAscending;
				
				return (NSComparisonResult) (obj1Pos - obj2Pos);
			}];
		} else if (self.currentSubCategory/* || ENABLE_LIBRARY_ALL_VIEW*/) {
			self.documentsByType = nil; //[MMSF_ContentVersion documentsFilteredByType:self.currentSubCategory.sortedContents];
			self.shelfNames = [[self.documentsByType allKeys] sortedArrayUsingComparator: ^(id obj1, id obj2) {
				static NSArray						*fixedCategories = nil;
				if (fixedCategories == nil) fixedCategories = $A(@"Brochures", @"Surgical Technique");
				
				NSInteger							obj1Pos = [fixedCategories indexOfObject: obj1], obj2Pos = [fixedCategories indexOfObject: obj2];
				
				if (obj1Pos == NSNotFound && obj2Pos == NSNotFound) return [obj1 compare: obj2];
				if (obj1Pos == NSNotFound) return (NSComparisonResult) NSOrderedDescending;
				if (obj2Pos == NSNotFound) return (NSComparisonResult) NSOrderedAscending;
				
				return (NSComparisonResult) (obj1Pos - obj2Pos);
			}];
			
			if ([self.shelfNames containsObject: kHiddenCategoryName]) self.shelfNames = [self.shelfNames arrayByRemovingObject: kHiddenCategoryName];
			
		} else {
			self.documentsByType = nil;
			self.shelfNames = nil;
			if (self.allContentImageView == nil) {
				self.allContentImageView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"library_all.png"]] autorelease];
				self.allContentImageView.contentMode = UIViewContentModeTop;
			}
			
			CGRect				frame = self.view.bounds;
			frame.origin.y += 60;
			self.allContentImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			self.allContentImageView.frame = frame;
			self.allContentImageView.clipsToBounds = YES;
			[self.view sendSubviewToBack: self.shelvesTable];
			[self.view insertSubview: self.allContentImageView aboveSubview: self.shelvesTable];
		}
        
		self.subcategoryLabel.hidden = NO;
		self.sliderBackground.hidden = NO;
		self.categoryScroller.hidden = NO;
	}
	
	if (self.searchBar.text.length) {
		[self updateSearchFilter: self.searchBar.text];
	} else
		[self.shelvesTable reloadData];
	
	[self updateBackButton];
}

- (NSDictionary *) documentsFilteredBySalesPhase: (NSArray *) docs {
	NSMutableDictionary				*types = [NSMutableDictionary dictionary];
	
	return types;
}

- (void) setShowingFavorites: (BOOL) newShowingFavorites {
	showingFavorites = newShowingFavorites;
	if (showingFavorites) {
		showingContent = NO;
		showingSalesPhase = NO;
	}
	self.currentSubCategory = self.currentSubCategory;
}

- (void) setShowingContent: (BOOL) newShowingContent {
	showingContent = newShowingContent;
	if (showingContent) {
		showingFavorites = NO;
		showingSalesPhase = NO;
	}
	self.currentSubCategory = self.currentSubCategory;
}

- (void) setShowingSalesPhase: (BOOL) newShowingSalesPhase {
	showingSalesPhase = newShowingSalesPhase;
	if (showingSalesPhase) {
		showingFavorites = NO;
		showingContent = NO;
	}
	self.currentSubCategory = self.currentSubCategory;
}

- (void) updateBackButton {
}

- (void) showAllItems {
	self.currentSubCategory = nil;
}

- (void) subcategoryTouchedInSegmentView: (NSNotification *) note {
	//[[self modalViewController] dismissModalViewControllerAnimated: YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    
	self.showingContent = YES;
	self.filterSegments.selectedSegmentIndex = 0;
	[self view];
	self.currentSubCategory = note.object;
	if ([self.tabBarController.viewControllers containsObject: self])
		self.tabBarController.selectedViewController = self;
	else if (self.navigationController && [self.tabBarController.viewControllers containsObject: self.navigationController])
		self.tabBarController.selectedViewController = self.navigationController;
}

//=============================================================================================================================
#pragma mark Actions
- (IBAction) filterChanged: (id) sender {
	switch (self.filterSegments.selectedSegmentIndex) {
		case 0: self.showingContent = YES; break;
		case 1: self.showingFavorites = YES; break;
		case 2: self.showingSalesPhase = YES; break;
	}
}

- (void) categoryButtonTouched: (UIButton *) sender {
	int					index = [self.categoryScroller.subviews indexOfObject: sender];
	
	if (index == NSNotFound) return;
	
	for (UIButton *button in self.categoryScroller.subviews) {
		button.highlighted = NO;
	}
	
	[NSObject performBlock: ^{sender.highlighted = YES;} afterDelay: 0];
}

- (IBAction)showMenu:(id)sender {
    
}

//=============================================================================================================================
#pragma mark Notifications
- (void) subcategorySelected: (NSNotification *) note {
	self.currentSubCategory = note.object;
}

- (void) subcategoryCancelled: (NSNotification *) note {
	[self populateCategoryScroller];
}

- (void) protectionChanged {
	self.currentSubCategory = self.currentSubCategory;
}

- (void) databaseUpdated {
	if (!self.isViewLoaded) return;
	self.currentSubCategory = self.currentSubCategory;
	[self populateCategoryScroller];
}

- (void) favoritesChanged: (NSNotification *) note {
	self.currentSubCategory = self.currentSubCategory;
}

- (void) keyboardWillShow: (NSNotification *) note {
	CGPoint				offset = self.shelvesTable.contentOffset;
	
	offset.y += [note.object floatValue];
	[self.shelvesTable setContentOffset: offset animated: YES];
}

//=============================================================================================================================
#pragma mark Utilities
- (void) populateCategoryScroller {
	float				left = 0;
	
	[self.categoryScroller removeAllSubviews];
	self.categoryScroller.contentSize = CGSizeMake(left, 44);
}

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSString								*cellIdentifier = [DSA_LibraryShelfView identifier];
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	NSArray									*items = nil;
	NSDictionary							*docs = self.filteredDocumentsByType ?: self.documentsByType;
	NSArray									*shelves = self.filteredShelfNames ?: self.shelfNames;
	
	items = [docs objectForKey: [shelves objectAtIndex: indexPath.section]];
	
	if (cell) {
		[cell setContentItems: items];
	} else {
		cell = [DSA_LibraryShelfView tableCellWithContentItems: items inViewController: self];
	}
	
	if (self.showingFavorites)
		[cell setShelfName: [shelves objectAtIndex: indexPath.section]];
	else
		[cell setShelfName: nil];
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	NSArray									*shelves = self.filteredShelfNames ?: self.shelfNames;
	return shelves.count + (self.showingFavorites ? 1 : 0);
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	NSArray									*shelves = self.filteredShelfNames ?: self.shelfNames;
    
	if (section >= shelves.count) return 0;
	return 1;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
	return [DSA_LibraryShelfItemView size].height;
}

- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) sectionIndex {
	DSA_LibraryShelfHeaderView			*view = [[[DSA_LibraryShelfHeaderView alloc] initWithFrame: CGRectMake(0, 0, 200, 30)] autorelease];
	NSArray								*shelves = self.filteredShelfNames ?: self.shelfNames;
	
	if (sectionIndex >= shelves.count) {
		view.isCreateNewShelfHeader = YES;
	} else {
		view.title = [shelves objectAtIndex: sectionIndex];
		view.isFavoriteShelfHeader = self.showingFavorites;
	}
    
	return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	NSArray								*shelves = self.filteredShelfNames ?: self.shelfNames;
    
	if (section == (shelves.count - 1) && !self.showingFavorites) {
		DSA_LibraryShelfHeaderView			*view = [[[DSA_LibraryShelfHeaderView alloc] initWithFrame: CGRectMake(0, 0, 200, 30)] autorelease];
		
		view.userInteractionEnabled = NO;
		return view;
	}
	return nil;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section {
	return 30;
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section {
	NSArray								*shelves = self.filteredShelfNames ?: self.shelfNames;
    
	return (section == (shelves.count - 1) && !self.showingFavorites) ? 30 : 0;
}


//=============================================================================================================================
#pragma mark Search Bar Delegate
- (void) searchBar: (UISearchBar *) searchBar textDidChange: (NSString *) searchText {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(updateSearchFilter:) object: nil];
	[self performSelector: @selector(updateSearchFilter:) withObject: searchText afterDelay: 0.5];
}

- (void) updateSearchFilter: (NSString *) newFilter {
	
	if (newFilter.length) {
		NSMutableDictionary				*docs = [NSMutableDictionary dictionary];
		NSMutableArray					*names = [NSMutableArray array];
		
		for (NSString *key in self.documentsByType) {
            NSMutableArray *contents = [[self.documentsByType objectForKey:key] mutableCopy];
            [contents filterUsingPredicate:[NSPredicate predicateWithFormat:newFilter]];
            
            if (contents.count) {
				[docs setObject:contents forKey:key];
				[names addObject:key];
			}
            
//			NSArray				*contents = [self.documentsByType objectForKey: key];
//			NSArray		*matchedContents;// = [NSMutableArray array];
//            NSIndexSet* matchedIndexes;
//            
//            matchedIndexes = [contents indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//                MMSF_ContentVersion* item = obj;
//                item = (id) [[[DSARestClient sharedInstance] context] objectWithID: item.objectID];
//                return [item matchesSortString: newFilter];
//            }];
//            matchedContents = [contents objectsAtIndexes:matchedIndexes];
//            
//			if (matchedContents.count) {
//				[docs setObject: matchedContents forKey:key];
//				[names addObject: key];
//			}
		}
		
		self.filteredShelfNames = names;
		self.filteredDocumentsByType = docs;
	} else {
		self.filteredShelfNames = nil;
		self.filteredDocumentsByType = nil;
	}
	[self.shelvesTable reloadData];
    
}

@end
