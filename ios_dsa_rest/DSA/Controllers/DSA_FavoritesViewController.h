//
//  DSA_FavoritesViewController
//  KCI
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#define kNotification_ContentLibraryCategorySelected			@"ContentLibraryCategorySelected"
#define kNotification_ContentLibraryCategoryCancelled			@"ContentLibraryCategoryCancelled"
#define kNotification_WillShowTextField							@"WillShowTextField"
@class MMSF_Category__c;

#define kBrowserColumnItemSelectedNotification @"com.modelmetrics.dsaapp.browserColumnItemSelected"

@interface DSA_FavoritesViewController : UIViewController <UIAlertViewDelegate> {
    
	UISearchBar			*searchBar;
	UISegmentedControl	*filterSegments;
	UIScrollView		*categoryScroller;
	UILabel				*subcategoryLabel;
	UITableView			*shelvesTable;
	UIToolbar			*toolbar;
	UIView				*sliderBackground;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *filterSegments;
@property (nonatomic, retain) IBOutlet UIScrollView *categoryScroller;
@property (nonatomic, retain) IBOutlet UILabel *subcategoryLabel;
@property (nonatomic, retain) IBOutlet UITableView *shelvesTable;
@property (nonatomic, retain) MMSF_Category__c *currentCategory, *currentSubCategory;
@property (nonatomic, retain) NSDictionary *documentsByType, *filteredDocumentsByType;
@property (nonatomic, retain) NSArray *shelfNames, *filteredShelfNames;
@property (nonatomic) BOOL backButtonRemoved, showingFavorites, showingSalesPhase, showingContent;
@property (nonatomic, retain) IBOutlet UIView *sliderBackground;
@property (nonatomic, retain) UIImageView *allContentImageView;

+ (id) controller;

- (IBAction) filterChanged: (id) sender;
- (IBAction) showMenu: (id) sender;

- (void) populateCategoryScroller;
- (void) updateSearchFilter: (NSString *) newFilter;
- (void) updateBackButton;

@end
