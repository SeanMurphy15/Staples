//
//  ZM_BrowseColumnView.m
//
//  Created by Ben Gottlieb on 9/2/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_BrowseColumnView.h"

#import "DSA_AppDelegate.h"

#import "DSA_BrowseViewController.h"
#import "MMSF_User.h"
#import "MMSF_MobileAppConfig__c.h"
#import "MM_ContextManager.h"

@implementation DSA_BrowseColumnView

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

+ (id) rootColumnViewWithUser: (MMSF_User *) user {
	DSA_BrowseColumnView			*view = [[[DSA_BrowseColumnView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)] autorelease];
	
    view.user = user;
	return view;
}

+ (id) columnViewWithCategory: (MMSF_Category__c *) category {
	DSA_BrowseColumnView			*view = [[[DSA_BrowseColumnView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)] autorelease];
	
	view.category = category;
	return view;
}

- (void) clearCaches {
	[self setNeedsLayout];
}

- (NSArray*) sortCategoriesInArray:(NSArray*)inArr{
    NSPredicate *catPredicate = [NSPredicate predicateWithFormat:
                                 @"self isKindOfClass: %@",
                                 [MMSF_Category__c class]];
    
    NSPredicate *contPredicate = [NSPredicate predicateWithFormat:
                                  @"self isKindOfClass: %@",
                                  [MMSF_ContentVersion class]];
    NSArray* catArr = [inArr filteredArrayUsingPredicate:catPredicate];
    NSArray* contArr = [inArr filteredArrayUsingPredicate:contPredicate];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey: @"Name" ascending: YES];
    catArr = [catArr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    
#if CATEGORIES_ORDERED_ON
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: MNSS(@"Order__c") ascending:YES];
    
    NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Todays_Special__c") ascending:NO];
    catArr = [[catArr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] 
              sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor2]];
#endif
    
    if ([contArr count] == 0)
        return catArr;
    if ([catArr count] == 0) 
        return contArr;
    
    catArr = [catArr arrayByAddingObjectsFromArray:contArr];
    
    return catArr;
}

- (void) layoutSubviews {
    [super layoutSubviews];

    NSArray* temp;
    
	if (self.user) {
        temp = [self sortCategoriesInArray:[self.user topLevelCategoriesForCurrentConfig]];
    } else{
        temp = [self sortCategoriesInArray:[self.category contentsAndSubcategoriesMatchingPredicate: self.filterPredicate]];
    }
    
    self.visibleCategoriesAndItems = temp;
    self.backgroundColor = [UIColor blackColor];
	if (self.navigationBar == nil)  {
		self.navigationBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, self.bounds.size.width - 1, 44)];
		[self.navigationBar pushNavigationItem: [[[UINavigationItem alloc] initWithTitle: self.category ? self.category.Name : @"Categories"] autorelease]  animated: NO];
        
        MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
        self.navigationBar.barTintColor = [UIColor lightGrayColor]; //[mac titleBarColor];
        
        UILabel* titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0,0,100,44)] autorelease];
        titleLabel.text = self.navigationBar.topItem.title;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [mac titleTextColor] ?: [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
        
        NSDictionary *attributes = @{NSFontAttributeName:titleLabel.font};
        CGSize titleSize = [titleLabel.text sizeWithAttributes:attributes];
        titleLabel.frame = CGRectMake(0, 0, titleSize.width, titleSize.height);
        self.navigationBar.topItem.titleView = titleLabel;
        
		self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview: self.navigationBar];
	}
	
	if (self.tableView == nil && self.hasContent) {
		self.tableView = [[[UITableView alloc] initWithFrame: CGRectMake(0, 44, self.bounds.size.width - 1, self.bounds.size.height - 44)] autorelease];
		self.tableView.dataSource = self;
		self.tableView.delegate = self;
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.tableView.backgroundColor = self.tableBackgroundColor;
    
        /**
         * Nice iOS7 feature <sarcasm>
         */
        self.tableView.separatorInset = UIEdgeInsetsZero;
    
		[self addSubview: self.tableView];
	}
    
    self.tableView.hidden = !self.hasContent;
    self.tableView.accessibilityLabel = self.category.Name ? [NSString stringWithFormat:@"%@ Table", self.category.Name] : @"root category";
    self.tableView.accessibilityIdentifier = self.category.Name ? [NSString stringWithFormat:@"%@ Table", self.category.Name] : @"root category";
    self.tableView.isAccessibilityElement = YES;
    
    if (self.noContentLabel == nil && !self.hasContent) {
        self.noContentLabel = [[[UILabel alloc] initWithFrame: CGRectMake(0, 100, self.bounds.size.width - 1, 200)] autorelease];
		self.noContentLabel.font = [UIFont boldSystemFontOfSize: 32];
		self.noContentLabel.textColor = [UIColor grayColor];
		self.noContentLabel.backgroundColor = [UIColor clearColor];
		self.noContentLabel.text = @"No Content Found";
		self.noContentLabel.textAlignment = NSTextAlignmentCenter;
		self.noContentLabel.numberOfLines = 2;
		self.noContentLabel.lineBreakMode = NSLineBreakByWordWrapping;
		self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview: self.noContentLabel];
	}
	self.noContentLabel.hidden = self.hasContent;
	
    [self.tableView reloadData];
	[self performSelector: @selector(selectCurrent) withObject: nil afterDelay: 0.0];
}

- (void) selectCurrent {
	NSUInteger					index = self.selectedRow;
	
	if (index != NSNotFound)
        [self.tableView selectRowAtIndexPath: [NSIndexPath indexPathForRow: index inSection: 0] animated: NO scrollPosition: UITableViewScrollPositionMiddle];
}

#pragma mark - Properties

- (NSUInteger) selectedRow {
	if (self.user && [self.user selectedSubCategoryForKey: self.subCategoryKey])
        return [self.visibleCategoriesAndItems indexOfObject: [self.user selectedSubCategoryForKey: self.subCategoryKey]];
	if (self.category && [self.category selectedSubCategoryForKey: self.subCategoryKey])
        return [self.visibleCategoriesAndItems indexOfObject: [self.category selectedSubCategoryForKey: self.subCategoryKey]];
    
	return NSNotFound;
}

- (BOOL) hasContent {
	return self.visibleCategoriesAndItems.count || self.visibleCategoriesAndItems.count || [self.category allDocumentsMatchingPredicate: self.filterPredicate includingSubCategories: NO].count;
}

#pragma mark - Table DataSource/Delegate

- (UITableViewCell *) tableView: (UITableView *) inTableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSString *cellIdentifier = @"cell";
	UITableViewCell	*cell = [self.tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier] autorelease];
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.adjustsFontSizeToFitWidth = YES;
		cell.textLabel.font = [UIFont boldSystemFontOfSize: 15];
    }
	
	if (self.user) {
		cell.textLabel.text = [[self.visibleCategoriesAndItems objectAtIndex: indexPath.row] Name];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.imageView.image = nil;
	} else {
		id	rowItem = [self.visibleCategoriesAndItems objectAtIndex: indexPath.row];
		
		if ([rowItem isKindOfClass: [MMSF_Category__c class]]) {
			cell.textLabel.text = [rowItem Name];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [rowItem attachmentImage];
            
            static CGFloat imageDim = 40;
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageDim, imageDim), NO, UIScreen.mainScreen.scale);
            CGRect imageRect = CGRectMake(0, 0, imageDim, imageDim);
            [cell.imageView.image drawInRect:imageRect];
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
		} else {
			cell.textLabel.text = [rowItem valueForKey:@"title"];
			cell.accessoryType = UITableViewCellAccessoryNone;
            
            CGSize thumbSize = CGSizeMake(40.f, 40.f);
            [rowItem generateThumbnailSize:thumbSize completionBlock:^(UIImage *image) {
                cell.imageView.image = image;
            }];
            if (cell.imageView.image == nil) cell.imageView.image = [rowItem tableCellImage];
		}
	}
	
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	return self.visibleCategoriesAndItems.count;
}

- (void) tableView: (UITableView *) inTableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	id				rowItem = [self.visibleCategoriesAndItems objectAtIndex: indexPath.row];
	
	if ([rowItem isKindOfClass: [MMSF_Category__c class]]) {
		[rowItem selectSubCategory: nil forKey: self.subCategoryKey];
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_CategorySelected object: rowItem];
	} else {
        [inTableView deselectRowAtIndexPath: indexPath animated: YES];
		[[NSNotificationCenter defaultCenter] postNotificationName: kBrowserColumnItemSelectedNotification object: rowItem];
	}
}

@end
