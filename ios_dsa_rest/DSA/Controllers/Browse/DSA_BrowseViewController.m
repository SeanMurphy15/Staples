//
//  ZM_BrowseViewController.m
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_BrowseViewController.h"
#import "DSA_BrowseColumnView.h"
#import "DSA_AppDelegate.h"
#import "DSA_MediaDisplayViewController.h"
#if IPCONNECT_BUILD
#import "CFU_PDFReaderViewController.h"
#endif
#import "MMSF_User.h"
#import "MMSF_Category__c.h"
#import "MMSF_ContentVersion.h"
#import "MM_Notifications.h"

#define			BROWSER_COLUMN_WIDTH				341				//self.view.bounds.size.width / 3

@interface DSA_BrowseViewController()

@property (nonatomic, readwrite, strong) NSMutableArray *browserColumnViews;
@property (nonatomic, readwrite) float browserColumnWidth;
@property (nonatomic, readwrite, strong) NSPredicate *filterPredicate;
@property (nonatomic, readwrite, strong) NSString *subCategoryKey;
@property (nonatomic, readwrite, strong) UIColor *tableBackgroundColor;
@property (nonatomic, readwrite) BOOL showAlertOnEntry;

- (void)internalModeSwitchEngaged:(NSNotification *)aNotif;
- (void) didLogOut:(NSNotification*)note;
- (void) setupScrollView;

@end

@implementation DSA_BrowseViewController

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (id) controller {
	UITabBarItem *tabBarItem = [[[UITabBarItem alloc] initWithTitle: @"Menu Browser" image: [UIImage imageNamed: @"browse_tab.png"] tag: 0] autorelease];
	DSA_BrowseViewController *controller = [self controllerWithPredicate: nil andTabBarItem: tabBarItem tableColor: [UIColor whiteColor]];
	
	return controller;
}

+ (id) controllerWithPredicate: (NSPredicate *) predicate andTabBarItem: (UITabBarItem *) item tableColor: (UIColor *) tableColor {
	DSA_BrowseViewController			*controller = [[[self alloc] init] autorelease];
	
	controller.filterPredicate = predicate ? predicate : [NSPredicate predicateWithValue: YES];
	controller.subCategoryKey = [controller.filterPredicate description];
	controller.tableBackgroundColor = tableColor;
	controller.tabBarItem = item ?: [[[UITabBarItem alloc] initWithTitle: @"Browse" image: [UIImage imageNamed: @"browse_tab.png"] tag: 0] autorelease];
	
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(mobileConfigSelected:) name: kNotification_MobileAppConfigurtionChanged object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller selector: @selector(categorySelected:) name: kNotification_CategorySelected object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller
                                             selector: @selector(itemSelected:)
                                                 name: kBrowserColumnItemSelectedNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(internalModeSwitchEngaged:)
                                                 name:kDSAInternalModeNotificationKey
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(reset) name:kNotification_SyncComplete object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: controller
                                             selector: @selector(didLogOut:)
                                                 name: kNotification_DidLogOut
                                               object: nil];

    return controller;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation {return YES;}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration {
	[super willAnimateRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
	self.browserColumnWidth = BROWSER_COLUMN_WIDTH;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupScrollView];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.view.accessibilityLabel = @"Menu Browser Controller View";
    self.view.accessibilityIdentifier = @"Menu Browser Controller View";
    self.view.isAccessibilityElement = YES;
}

- (void) viewWillAppear: (BOOL)animated {
	[super viewWillAppear: animated];
    
    MMSF_MobileAppConfig__c *mac = [g_appDelegate selectedMobileAppConfig];
    if (!RUNNING_ON_80)
    {
        self.navigationBar.tintColor = [mac titleBarColor];
    }
    else
    {
        self.navigationBar.barTintColor = [UIColor lightGrayColor]; //[mac titleBarColor];
    }
	self.browserColumnWidth = BROWSER_COLUMN_WIDTH;
    
    self.spacerBarView.backgroundColor = [UIColor lightGrayColor];
	
}

- (void) viewDidAppear: (BOOL) animated {
	[super viewDidAppear: animated];
    
    [self setupScrollView];
    
    MMSF_User *user = [MMSF_User currentUser];
    if([user topLevelCategoriesForCurrentConfig].count==0){
        [self reset];
    }
}

- (void) reset {
    for (DSA_BrowseColumnView* column in self.browserColumnViews) {
        [column removeFromSuperview];
    }
	self.browserColumnViews = nil;
	[[MMSF_User currentUser] clearSelectedCategories];
    
	[self setupScrollView];
}

#pragma mark - Notifications

- (void) mobileConfigSelected: (NSNotification *) note {
	[self reset];
}

- (void) categorySelected: (NSNotification *) note {
	if (self.view.window == nil) return;
    
	MMSF_Category__c *selected = note.object;
	
	if (selected.Parent_Category__c == nil)
		[[MMSF_User currentUser] selectSubCategory: selected forKey: self.subCategoryKey];
	else
		[selected.Parent_Category__c selectSubCategory: selected forKey: self.subCategoryKey];
	[self setupScrollView];
	
	float newOffset = self.browserView.contentSize.width - self.browserView.bounds.size.width;
	[self.browserView setContentOffset: CGPointMake(newOffset, 0) animated: YES];
}

- (void) didLogOut:(NSNotification*)note {
	for (DSA_BrowseColumnView *view in self.browserColumnViews) { [view removeFromSuperview]; }
	self.browserColumnViews = nil;
}

#pragma mark - Setup Scrollview
- (void) setupScrollView
{
	MMSF_User								*user = [MMSF_User currentUser];
	CGRect									bounds = self.view.bounds;
	MMSF_Category__c						*nextCategory;
	NSInteger								childCount = 1;
    
	if (self.browserColumnViews == nil)
    {
		self.browserColumnViews = [NSMutableArray arrayWithObject: [DSA_BrowseColumnView rootColumnViewWithUser: user]];
    }
	else
    {
		NSMutableArray				*savedViews = [NSMutableArray array];
		BOOL						pathTruncated = NO;
		
		nextCategory = [[MMSF_User currentUser] selectedSubCategoryForKey: self.subCategoryKey];
        
		for (DSA_BrowseColumnView *view in self.browserColumnViews)
        {
			if ((view.user || view.category == nextCategory) && !pathTruncated)
            {
				[savedViews addObject: view];
				if (view.category) nextCategory = [view.category selectedSubCategoryForKey: self.subCategoryKey];
			}
            else
            {
				pathTruncated = YES;
				[view removeFromSuperview];
			}
		}
		
		self.browserColumnViews = savedViews;
	}
	
	nextCategory = [[MMSF_User currentUser] selectedSubCategoryForKey: self.subCategoryKey];
	while (nextCategory)
    {
		if (childCount >= self.browserColumnViews.count)
        {
            [self.browserColumnViews addObject: [DSA_BrowseColumnView columnViewWithCategory: nextCategory]];
        }
        
		nextCategory = [nextCategory selectedSubCategoryForKey: self.subCategoryKey];
		childCount++;
	}
	
	self.browserView.contentSize = CGSizeMake(MAX(bounds.size.width, self.browserColumnViews.count * self.browserColumnWidth), self.browserView.bounds.size.height);
	
	while (self.browserView.subviews.count)
    {
        [[self.browserView.subviews objectAtIndex: 0] removeFromSuperview];
    }
	
    CGFloat height = self.browserView.frame.size.height;
	for (NSInteger i = 0; i < self.browserColumnViews.count; i++) {
		DSA_BrowseColumnView			*view = [self.browserColumnViews objectAtIndex: i];

        CGFloat topOffset = 0.0;
        if (!RUNNING_ON_80)
        {
            switch (self.interfaceOrientation)
            {
                case UIDeviceOrientationLandscapeLeft:
                case UIDeviceOrientationLandscapeRight:
                {
                    topOffset = [UIApplication sharedApplication].statusBarFrame.size.width;
                }
                    break;
                    
                default:
                {
                    topOffset = [UIApplication sharedApplication].statusBarFrame.size.height;
                }
                    break;
            }
        }
        else
        {
            topOffset = [UIApplication sharedApplication].statusBarFrame.size.height;
        }

        view.bounds = CGRectMake(0, 0, self.browserColumnWidth, bounds.size.height - topOffset);
        CGRect rect = view.bounds;

        rect.origin.y = topOffset;
        rect.origin.x = (self.browserColumnWidth) * i;
        rect.size.height = height;
        view.frame = rect;
		view.filterPredicate = self.filterPredicate;
		view.tableBackgroundColor = self.tableBackgroundColor;
		view.subCategoryKey = self.subCategoryKey;
        view.tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
		[self.browserView addSubview: view];
		[view setNeedsLayout];
	}
}

- (void) viewDidLayoutSubviews
{
    CGFloat h = self.topLayoutGuide.length;
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void) itemSelected: (NSNotification *) note {
    MMSF_ContentVersion* item = note.object;
    
#if IPCONNECT_BUILD
    if ([[item.type lowercaseString] isEqual: @"pdf"]) {
        CFU_PDFReaderViewController		*controller = [CFU_PDFReaderViewController controllerWithItem: item];
        [self presentModalViewController: controller animated: YES];
        return;
    }
#endif
	
    UIViewController* vc = [DSA_MediaDisplayViewController controllerForItem: item withDelegate: self];
    [self presentViewController:vc animated:YES completion:nil];
}


///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)internalModeSwitchEngaged:(NSNotification *)aNotif {
    
    [self.browserColumnViews enumerateObjectsUsingBlock:^(DSA_BrowseColumnView *view, NSUInteger idx, BOOL *stop){
        [view clearCaches];
    }];
    
    [self reset];
}

@end
