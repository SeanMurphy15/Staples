    //
//  DSA_BaseTabsViewController.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/21/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_BaseTabsViewController.h"

#import "ZM_SearchViewController.h"
#import "DSA_BrowseViewController.h"
#import "DSA_MediaDisplayViewController.h"
#import "MM_FlexibleVisualBrowser.h"
#import "DSA_TabBar.h"
#import "DSA_FeaturedItemsViewController.h"
#import "MMSF_User.h"
#import "DSA_FavoritesViewController.h"
#import "DSA_ContentShelvesController.h"
#import "DocumentTracker.h"

const CGFloat kTabBarHeight = 50;
const CGFloat kTabWidth = 84;

@implementation DSA_BaseTabsViewController

#pragma mark - Overrides for UITabBarController

- (void) setViewControllers: (NSArray *) viewControllers {
	_viewControllers = viewControllers;
	
	[self.selectedViewController removeFromParentViewController];
	[self.selectedViewController.view removeFromSuperview];
	_selectedViewController = nil;
	self.selectedIndex = MIN(_selectedIndex, viewControllers.count);
	self.tabBar.items = [viewControllers valueForKey: @"tabBarItem"];
}

- (void) setSelectedIndex: (NSUInteger) selectedIndex {
	if (selectedIndex >= self.viewControllers.count) return;
	_selectedIndex = selectedIndex;
	self.selectedViewController = self.viewControllers[selectedIndex];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) setSelectedViewController: (UIViewController *) selectedViewController {
	if (selectedViewController == _selectedViewController) return;
	
	[self.selectedViewController removeFromParentViewController];
	[self.selectedViewController.view removeFromSuperview];
	
	_selectedViewController = selectedViewController;
	
	selectedViewController.view.frame = self.view.bounds;
	[self addChildViewController: selectedViewController];
	[self.view insertSubview: selectedViewController.view atIndex: 0];
}

- (void)enableTabBar:(BOOL)enable {
    self.tabBar.userInteractionEnabled = enable;
    self.tabBar.hidden = !enable;
}

- (UIViewController*) childViewControllerForStatusBarHidden
{
    return self.selectedViewController;
}

- (id) init {
	if ((self = [super init])) 
    {
        NSMutableArray* viewControllers = [NSMutableArray array];
        
        [viewControllers addObject:[MM_FlexibleVisualBrowser navController]];
        [viewControllers addObject:[DSA_BrowseViewController controller]];
        
#if INCLUDE_ABOUT_TAB        
        [viewControllers addObject:[DSA_MediaDisplayViewController navControllerWithTitle: @"About This App contentItemTitle: @"About This App" andTabBarItem: [[UITabBarItem alloc] initWithTitle: @"About This App" image: [UIImage imageNamed: @"about_tab.png"] tag: 0]]];
#endif
        
        DSA_MediaDisplayViewController* mdvc = [DSA_MediaDisplayViewController controller];
        mdvc.sendDocumentTrackerNotifications = YES;
        mdvc.inHistoryMode = YES;
        mdvc.tabBarItem = [[UITabBarItem alloc] initWithTitle: @"History"
                                                       image: [UIImage imageNamed: @"history.png"] 
                                                         tag: 0];
        mdvc.tabBarItem.accessibilityLabel = @"History Tab";
		[viewControllers addObject:mdvc];
		
#if SHOPPING_CART_SUPPORT
		[viewControllers addObject: [IP_ShoppingCartViewController controller]];
#endif
        
        DSA_ContentShelvesController *shelvesVC = [DSA_ContentShelvesController controller];
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:shelvesVC];
        nc.tabBarItem = [[UITabBarItem alloc] initWithTitle: @"Playlists" image: [UIImage imageNamed: @"star.png"] tag: 0];
        nc.tabBarItem.accessibilityLabel = @"Playlists";
		[viewControllers addObject:nc];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"DSA_FeaturedItems" bundle:nil];
        DSA_FeaturedItemsViewController *featuredItemsVC = [storyboard instantiateViewControllerWithIdentifier:@"DSA_FeaturedItemsViewController"];
        nc = [[UINavigationController alloc] initWithRootViewController:featuredItemsVC];
        [viewControllers addObject:nc];
		
		self.viewControllers = viewControllers;
		self.delegate = self;
                                    
	}
	
	return self;
}

- (void) showChatter: (id) sender {
	NSURL					*url = [NSURL URLWithString: @"chatter://"];
	
	if (![[UIApplication sharedApplication] canOpenURL: url]) {
		[SA_AlertView showAlertWithTitle: @"ChatterBox Not Installed" message: @"Please install the ChatterBox app to access Chatter"];
	} else
		[[UIApplication sharedApplication] openURL: url];
}

#pragma mark - View Controller Lifecycle

- (void) viewDidLoad {
    [super viewDidLoad];

	CGFloat height = kTabBarHeight;
	self.tabBar = [[DSA_TabBar alloc] initWithFrame: CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height)];
	self.tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	self.tabBar.tabBarController = self;
	[self.view addSubview: self.tabBar];

#if DISPLAY_MM_LOGO
	UIImageView				*imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"SalesforceU.png"]];
	
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.bounds = CGRectMake(0, 0, imageView.image.size.width, MIN(imageView.image.size.height, self.view.bounds.size.height - 10));
	imageView.center = CGPointMake(imageView.bounds.size.width / 2 + 10, self.view.bounds.size.height - 25);
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
	
	[self.view addSubview: imageView];
#endif
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	if (![MMSF_User currentUser].isLoggedIn) return NO;
	
	return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController 
{
	if ([MM_LoginViewController isLoggingOut] || ![MM_LoginViewController isLoggedIn]) {
		tabBarController.selectedIndex = 0;
		return;
	}
    if ([tabBarController.viewControllers indexOfObject:viewController] != ([tabBarController.viewControllers count] -1))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStopViewingNotification object:nil];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - DSA_MediaDisplayViewControllerDelegate

- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
