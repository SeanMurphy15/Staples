//
//  MM_FlexibleVisualBrowser.m
//  ModelMetrics
//
//  Created by Guy Umbright 5/18/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "MM_FlexibleVisualBrowser.h"
#import "ZM_ImprovedCarouselView.h"
#import "DSA_AppDelegate.h"
#import "MM_ContextManager.h"

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

#import "MMSF_MobileAppConfig__c.h"
#import "MMSF_CategoryMobileConfig__c.h"

#import "debugtools.h"

#import "CheckinContactSelectorViewController.h"
#import "CheckoutReviewViewController.h"

#import "DSA_SettingsMenuViewController.h"
#import "MM_Notifications.h"
#import "DSA_Defines.h"
#import "DSA_NLevelNavigationController.h"
#import "DSA_NLevelNavigationPane.h"
#import "DSA_CategoryContentsViewController.h"
#import "DSA_PulseView.h"
#import "LeadSearchViewController.h"
#import "DSA_SearchField.h"
#import "UIView+DSA_Additions.h"
#import "ZM_SearchResultsController.h"
#import "MMSF_Lead.h"
#import "MeetingDetailsViewController.h"
//#import "UIAlertView+SFBlocks.h"
#import "DSA_CellularDataDefender.h"
#import "DSA_RemoteObjectStatusClient.h"
#import "CheckInCheckOutConstants.h"
#import "EmailSubjectController.h"

#define kSkeletonWidth 420
#define kSkeletonHeight 840

#define kButtonSlideAmount 400
#define kButtonFudgeAmount 10

#define kNumberOfCategories 6

#define kButtonTagBase 2000
#define kButtonPartialAlpha  0.4
#define kPulseViewActiveAlpha 0.35
#define kSettingsButtonActiveAlpha 0.35
#define kSearchFieldActiveAlpha 0.35

#define kTransparentTopToolbar  1

@interface MM_FlexibleVisualBrowser() <EmailSubjectControllerDelegate>

@property (nonatomic, assign, getter = isNLevelShown) BOOL nLevelShown;
@property (nonatomic, strong) UIPopoverController *currentPopoverController;
@property (nonatomic, strong) NSArray *itemsToEmail;

- (void)internalModeSwitchEngaged:(NSNotification *)aNotif;
- (void)newContentAvailable:(NSNotification *)aNotif;
- (void)syncCompleted:(NSNotification *)aNotif;

@end

@implementation MM_FlexibleVisualBrowser

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) awakeFromNib {
    initialAnimationDone = NO;
}

- (id)init {
    self = [super init];
    if (self) {
        _nLevelShown = NO;
//        _isContentAvailableForDownload = NO;
    }
    
    return self;
}

#pragma mark - Factory

+ (instancetype) controller {
	MM_FlexibleVisualBrowser		*controller = [[self alloc] init];
	
	controller.tabBarItem = [[UITabBarItem alloc] initWithTitle: @"Visual Browser" image: [UIImage imageNamed: @"visual_browser_tab.png"] tag: 1];
	
	[[NSNotificationCenter defaultCenter] addObserver: controller
                                             selector: @selector(checkinEntitySelected:)
                                                 name: kCheckInContactSelected
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller
                                             selector: @selector(checkinEntitySelected:)
                                                 name: kCheckInContactDeferred
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller
                                             selector: @selector(checkinEntitySelected:)
                                                 name: kCheckInLeadSelected
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller
                                             selector: @selector(checkinEntitySelected:)
                                                 name: kCheckInLeadDeferred
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(checkoutDone:) 
                                                 name: kCheckoutDone 
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(checkoutCanceled:) 
                                                 name: kCheckoutCanceled 
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(displayMobileConfigSelector:) 
                                                 name: kNotification_DisplayMobileConfigSelector 
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(settingsShown:) 
                                                 name: SETTINGS_POPOVER_PRESENTED 
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(settingsDismissed:) 
                                                 name: SETTINGS_POPOVER_DISMISSED 
                                               object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(checkinoutShown:) 
                                                 name: CHECKIN_POPOVER_PRESENTED 
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(checkinoutDismissed:) 
                                                 name: CHECKIN_POPOVER_DISMISSED 
                                               object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(checkinoutShown:) 
                                                 name: CHECKOUT_POPOVER_PRESENTED 
                                               object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: controller 
                                             selector: @selector(checkinoutDismissed:) 
                                                 name: CHECKOUT_POPOVER_DISMISSED 
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller 
                                             selector:@selector(reloadConfiguration:) 
                                                 name:kNotification_ReloadConfiguration 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller 
                                             selector:@selector(syncProgressDidDismiss:)
                                                 name:kNotification_SyncProgressDidDismiss
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller 
                                             selector:@selector(downloadCompleted:) 
                                                 name:kNotification_DownloadCompleted
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(userDidLogOut) 
                                                 name:kNotification_DidLogOut 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(userChanged:) name:kNotification_UserChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller selector:@selector(userChanged:) name:kNotification_WillLogOut object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(internalModeSwitchEngaged:)
                                                 name:kDSAInternalModeNotificationKey
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(showCategoryFromNotification:)
                                                 name:kNotification_VisualBrowserCategorySelected
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(newContentAvailable:)
                                                 name:kDSANewContentAvailableNotificationKey
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(syncCompleted:)
                                                 name:kNotification_SyncComplete
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(contactSelectedForCheckout:)
                                                 name:kNotification_ContactCheckedIn
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:controller
                                             selector:@selector(leadSelectedForCheckout:)
                                                 name:kNotification_LeadCheckedIn
                                               object:nil];

	return controller;
}

- (void)contactSelectedForCheckout:(NSNotification *)notification {
    [self updateCheckOutButtonsWithContactSelected:YES andLeadSelected:NO];
}

- (void)leadSelectedForCheckout:(NSNotification *)notification {
    [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:YES];
}

- (void) trackingStarted: (NSNotification *) note {
	self.jumpToSF1Button.hidden = false;
}

- (void) trackingEnded: (NSNotification *) note {
	self.jumpToSF1Button.hidden = true;
}

+ (UINavigationController*)navController {
    UIViewController			*controller = [self controller];
    UINavigationController		*navController = [[[UINavigationController alloc] initWithRootViewController: controller] autorelease];
    
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.navigationBar.translucent = YES;
    navController.navigationBarHidden = YES;
    navController.tabBarItem = controller.tabBarItem;
        
    return navController;
}

#pragma mark -

- (BOOL)shouldShowSettingsMenu {
    BOOL shouldShowSettings = YES;
    
    if ([MM_LoginViewController isLoggingIn] ||
        [[MM_SyncManager sharedManager] isSyncInProgress] ||
        [[DSARestClient sharedInstance] isShowingSyncProgress]) {
        shouldShowSettings = NO;
    };
	
    return shouldShowSettings;
}

- (IBAction) showSettingsMenu: (id) sender {
    if ([self shouldShowSettingsMenu]) {
        if (self.settingsButton)
            [DSA_SettingsMenuViewController popOverFromButton: self.settingsButton];
    }
}

- (void) showContentsForCategory: (MMSF_Category__c *) category {
	if (category == self.currentCategoryController.category) return;
	
    MMSF_MobileAppConfig__c				*mac = [g_appDelegate selectedMobileAppConfig];
    MMSF_CategoryMobileConfig__c		*config = [mac configForCategory: category];
	
	if (config != self.currentCategoryConfig) {
		self.currentCategoryConfig = config;
		[self presentCategoryDisplay: YES];
	}
	if (self.currentCategoryController) {
		[self.currentCategoryController removeFroMParentAnimated: YES];
	}
	
	[self setCategoryBackgroundImage: [self.currentCategoryConfig categoryBackgroundImageForOrientation: self.interfaceOrientation] andTintColor: self.currentCategoryConfig.categoryBackgroundTintColor animated: YES];
	
	self.currentCategoryController = [DSA_CategoryContentsViewController showBrowserForCategory: category 
	withConfig: config 
	inParent: self 
	withLandcapeInsets: UIEdgeInsetsMake(100, 245, 100, 190) 
	andPortraitInsets: UIEdgeInsetsMake(200, 240, 200, 140) ];
}

- (void) setCategoryBackgroundImage: (UIImage *) categoryBackgroundImage andTintColor: (UIColor *) tintColor animated: (BOOL) animated {
    // snapshot the current background image and insert it into the view hierarchy
    UIView *snapShot = [[self categoryBackgroundContainerView] snapshotViewAfterScreenUpdates:NO];
    [[self view] insertSubview:snapShot aboveSubview:[self categoryBackgroundContainerView]];
    
    // set the state of things underneath the snapshot
	if (categoryBackgroundImage) {
		if (animated) {
			self.categoryBackgroundImageView.alpha = 1.0;
			[UIView animateWithDuration: 0.2 animations: ^{
				self.categoryBackgroundImageView.alpha = 1.0;
				self.categoryBackgroundImageView.image = categoryBackgroundImage;
			}];
		} else {
			self.categoryBackgroundImageView.alpha = 1.0;
			self.categoryBackgroundImageView.image = categoryBackgroundImage;
		}
	} else if (_categoryBackgroundImageView) {
		UIView				*view = self.categoryBackgroundImageView;
		
		self.categoryBackgroundImageView = nil;
		[UIView animateWithDuration: 0.2 animations: ^{
			view.alpha = 0.0;
		} completion:^(BOOL finished) {
			[view removeFromSuperview];
		}];
	}
	
	if (tintColor) {
		self.categoryBackgroundTintView.backgroundColor = tintColor;
		if (animated) {
			self.categoryBackgroundTintView.alpha = 0.0;
			[UIView animateWithDuration: 0.2 animations: ^{
				self.categoryBackgroundTintView.alpha = 1.0;
			}];
		}
	} else if (_categoryBackgroundTintView) {
		UIView				*view = self.categoryBackgroundTintView;
		
		self.categoryBackgroundTintView = nil;
		[UIView animateWithDuration: 0.2 animations: ^{
			view.alpha = 0.0;
		} completion:^(BOOL finished) {
			[view removeFromSuperview];
		}];
	}
    
    if (animated) {
        [UIView animateWithDuration: 0.2 animations: ^{
            // animate the snapshot away, revealing the new background
            snapShot.alpha = 0.0;
        } completion:^(BOOL finished) {
            // blitz the snapshot
            [snapShot removeFromSuperview];
        }];
    } else {
        snapShot.alpha = 0.0;
        [snapShot removeFromSuperview];
    }
}

- (BOOL)isNLevelShown {
    return _nLevelShown;
}

- (void) adjustToolbarButtons
{
    if (self.currentCategoryConfig == nil)
    {
        //show 'em all
        CGFloat alpha = ([DSA_RemoteObjectStatusClient hasBeenNotifed] ? kPulseViewActiveAlpha : 0);
        self.pulseView.alpha = alpha;
        
        DocumentTrackingType type = g_appDelegate.currentTrackingType;

        if (type == DocumentTracking_SelectedContact) {
            [self updateCheckOutButtonsWithContactSelected:YES andLeadSelected:NO];
        } else if (type == DocumentTracking_SelectedLead) {
            [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:YES];
        } else {
            alpha = type == DocumentTracking_DeferredContact ? 1 : kButtonPartialAlpha;
            self.checkInOuButton.alpha = alpha;

            alpha = type == DocumentTracking_DeferredLead ? 1 : kButtonPartialAlpha;
            self.leadsButton.alpha = alpha;
        }

        self.settingsButton.alpha = kSettingsButtonActiveAlpha;
        self.searchField.alpha = kSearchFieldActiveAlpha;
        
        self.jumpToSF1Button.hidden = ![self shouldShowSalesforce1Button];
    }
    else
    {
        self.pulseView.alpha = 0;
        self.leadsButton.alpha = 0;
        self.checkInOuButton.alpha = 0;
        self.settingsButton.alpha = 0;
        self.searchField.alpha = 0;
        self.jumpToSF1Button.hidden = true;
    }
}

- (void) adjustToolbarButtonVisibility
{
    
}

#pragma mark - LifeCycle

- (void) applyConfiguration:(BOOL)apply {
    MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
	[MMSF_User resetCachedtopLevelCatgories];
	
    if (mac != nil) {
        self.instructionLabel.text = mac.IntroText__c;
        self.instructionLabel.textColor = [mac infoTextColor] ?: [UIColor blackColor];
        
        if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] userInterfaceOrientation])) {
            self.background.frame = self.view.bounds;
            self.background.image = [mac portraitBackgroundImage];
        }
        else {
            self.background.frame = self.view.bounds;
            self.background.image = [mac landscapeBackgroundImage];
        }

    	[self setupButtons];
    }
    else {
        self.background.image = nil;       
        
        for (UIButton* button in self.buttons) {
            [button removeFromSuperview];
        }
        
        self.buttons = nil;
        self.instructionLabel.text = nil;
        
        if (UIDeviceOrientationIsPortrait([self interfaceOrientation])) {
            self.background.image = [UIImage imageNamed:@"hoakula1stsyncportp.png"];
        }
        else {
            self.background.image = [UIImage imageNamed:@"hoakula1stsynclandp.png"];
        }
    }

    [self adjustForOrientation:UIDeviceOrientationIsPortrait([self interfaceOrientation])];
}


//////////////////////////////////////
//
//////////////////////////////////////
- (void) presentMobileConfigSelector:(BOOL) cancelable {
    MobileConfigSelectionViewController* vc = [[MobileConfigSelectionViewController alloc] init];
    
    vc.mobileConfigSelectorDelegate = self;
    vc.allowCancel = cancelable;
    [self presentViewController:vc animated:YES completion:nil];
}

//////////////////////////////////////
//
//////////////////////////////////////
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self applyConfiguration: YES];
    if (self.currentPopoverController)
    {
        self.currentPopoverController = nil;
    }
}


/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) presentCategoryDisplay:(BOOL) animated
{
    [self setNeedsStatusBarAppearanceUpdate];
}


/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) showCategory:(MMSF_CategoryMobileConfig__c*) categoryConfig animated:(BOOL) animated
{
	[DSA_NLevelNavigationController animateNavigationIntoViewController: self withInitiallySelectedCategory: categoryConfig.CategoryId__c];
	[self dismissButtons];
    [self setNeedsStatusBarAppearanceUpdate];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) showCategory:(MMSF_CategoryMobileConfig__c*) categoryConfig
{
    [self showCategory:categoryConfig animated:YES];
}

- (void) showCategoryFromNotification:(NSNotification *) aNotification
{
    NSArray *categoryConfigsArray = (NSArray *) [aNotification object];
    NSEnumerator *reverseEnumerator = [categoryConfigsArray reverseObjectEnumerator];

    NSArray *childVCs = self.childViewControllers;
    for (UIViewController *childVC in childVCs) {
        if ([childVC isKindOfClass:[DSA_NLevelNavigationController class]] && [childVC respondsToSelector:@selector(dismissAnimated:)]) {
            [childVC performSelector:@selector(dismissAnimated:) withObject:nil];
            break;
        }
    }
    
    [self setCurrentCategory: categoryConfigsArray.lastObject animated: NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        DSA_NLevelNavigationController *nLevelController = nil;
        NSArray *childVCs = self.childViewControllers;
        for (UIViewController *childVC in childVCs) {
            if ([childVC isKindOfClass:[DSA_NLevelNavigationController class]] && [childVC respondsToSelector:@selector(dismissAnimated:)]) {
                nLevelController = (DSA_NLevelNavigationController *)childVC;
                break;
            }
        }

        for (MMSF_CategoryMobileConfig__c *catConfig in reverseEnumerator)
        {
            if (catConfig == categoryConfigsArray.lastObject) {
                continue;
            }
            NSArray *visiblePanes = nLevelController.visiblePanes;
            DSA_NLevelNavigationPane *nLevelPane = visiblePanes.lastObject;
            if (![nLevelPane expandCategory: catConfig.CategoryId__c animated: NO]) [nLevelPane willReveal];
        }
    });

    [self dismissButtons];
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
- (void) hideCategory
{
	self.currentCategoryName = nil;
    self.currentSubCategory = nil;
}

#pragma mark - Properties

- (UIImageView *) categoryBackgroundImageView {
	if (_categoryBackgroundImageView == nil) {
		_categoryBackgroundImageView = [[UIImageView alloc] initWithFrame: self.background.frame];
		_categoryBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
		_categoryBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_categoryBackgroundImageView.accessibilityLabel = @"Category Background";
        [self.view insertSubview: _categoryBackgroundImageView aboveSubview: self.background];
	}
	return _categoryBackgroundImageView;
}

- (UIView *) categoryBackgroundTintView {
	if (_categoryBackgroundTintView == nil) {
		_categoryBackgroundTintView = [[UIView alloc] initWithFrame: self.background.frame];
		_categoryBackgroundTintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_categoryBackgroundTintView.opaque = NO;
		_categoryBackgroundImageView.accessibilityLabel = @"Category Tint";
        [self.view insertSubview: _categoryBackgroundTintView aboveSubview: self.categoryBackgroundImageView ?: self.background];
	}
	return _categoryBackgroundTintView;
}


- (void) setCurrentCategory: (MMSF_CategoryMobileConfig__c*) categoryConfig animated: (BOOL) animated {
	self.currentCategoryConfig = categoryConfig;
	
	if (categoryConfig) {
		[self showCategory: categoryConfig animated: animated];
	}
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) configureInterface
{
    [self applyConfiguration: YES];
    
}

- (void)prepareToolbar {
    CGFloat statusBarHeight = 0.0;
    
    if (!RUNNING_ON_80)
    {
        switch (self.interfaceOrientation)
        {
            case UIDeviceOrientationLandscapeLeft:
            case UIDeviceOrientationLandscapeRight:
            {
                statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
            }
                break;
                
            default:
            {
                statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
            }
                break;
        }
    }
    else
    {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
//    CGRect barFrame = self.topToolbar.frame;
//    barFrame.origin = CGPointMake(0, statusBarHeight);
//    [self.topToolbar setFrame:barFrame];

#if kTransparentTopToolbar
    // transparent toolbar
    [self.topToolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    self.topToolbar.backgroundColor = [UIColor clearColor];
    self.topToolbar.clipsToBounds = YES;
#endif
    
    // add pulse image view to toolbar
    NSUInteger pulseItemIndex = 1;
    UIBarButtonItem *pulseViewItem = self.topToolbar.items[pulseItemIndex];
    if (pulseViewItem) {
        pulseViewItem.customView = self.pulseView;
    }
}

//////////////////////////////////////
//
//////////////////////////////////////
- (void)viewDidLoad  {
	[super viewDidLoad];
    
    [self configureInterface];

	self.searchField.alpha = 0.35;
 
    [self prepareToolbar];
    
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    self.background.alpha = 0.0;
    self.buttonContainer.alpha = 0.0;

    [self setCategoryBackgroundContainerView:[[UIView alloc] initWithFrame:[[self view] bounds]]];
    [self.view insertSubview:[self categoryBackgroundContainerView] aboveSubview:[self background]];
    
    self.view.accessibilityLabel = @"Visual Browser Controller View";
    self.view.accessibilityIdentifier = @"Visual Browser Controller View";
    self.view.isAccessibilityElement = YES;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(abortCheckout:)];
    [longPress setMinimumPressDuration: 2];
    [self.leadsButton addGestureRecognizer: longPress];
    
    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(abortCheckout:)];
    [longPress setMinimumPressDuration: 2];
    [self.checkInOuButton addGestureRecognizer: longPress];

	self.jumpToSF1Button.hidden = g_appDelegate.currentTrackingEntity == nil;
}

//////////////////////////////////////
//
//////////////////////////////////////
- (void) viewWillAppear: (BOOL) animated {
	[super viewWillAppear: animated];
    
	self.navigationController.navigationBarHidden = YES;
    //self.navigationController.toolbarHidden = NO;
    [self adjustToolbarButtons];
}

//////////////////////////////////////
//
//////////////////////////////////////
- (void) viewDidAppear: (BOOL) animated {
	[super viewDidAppear: animated];
    
    [self adjustForOrientation:[self interfaceOrientation]];
    [self prepareToolbar];

    self.instructionLabel.alpha = 1.0;
    self.background.alpha = 1.0;
    self.buttonContainer.alpha = 1.0;

	if (![MM_SyncManager sharedManager].hasSyncedOnce || (![MM_LoginViewController isLoggedIn] && ![MM_LoginViewController isLoggingIn])) {
		[self performSelector: @selector(showSettingsMenu:) withObject: self.settingsButton afterDelay: 0.1];
	}
}

//////////////////////////////////////
//
//////////////////////////////////////
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation 
{ 
    return YES; 
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    UIBarPosition barPosition = UIBarPositionAny;
    if (bar == self.topToolbar) {
        barPosition = UIBarPositionTopAttached;
    }
    
    return barPosition;
}

- (UIRectEdge) edgesForExtendedLayout {
    return UIRectEdgeAll;
}

#pragma mark - Setup

// current DSA Configurator expects status bar, etc. forcing buttons lower than requested
- (CGPoint)adjustButtonOrigin:(CGPoint)inOrigin {
    CGRect buttonViewFrame = self.buttonContainer.frame;
    CGFloat adjust = buttonViewFrame.origin.y;
    
    CGPoint outOrigin = CGPointMake(inOrigin.x, inOrigin.y - adjust);
    return outOrigin;
}

- (IBAction) dismissCurrentPopoverController: (id) sender {
    
    if (_currentPopoverController && [_currentPopoverController isPopoverVisible])
        [_currentPopoverController dismissPopoverAnimated: YES];
    
    [self setCurrentPopoverController: nil];
}

-(void) setupButtons {
    MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
	
    self.checkInOuButton.hidden = ![mac.Check_In_Enabled__c boolValue];
    self.leadsButton.hidden = ![mac.Check_In_Enabled__c boolValue];
	
    if (self.buttons != nil) {
        for (UIButton* button in self.buttons) {
            [button removeFromSuperview];
        }
        
        self.buttons = nil;
    }
    
    self.buttons =  [NSMutableArray array];
    
    /**
     * The visual browser should only show top level category buttons
     */
    
    NSString *format = [NSString stringWithFormat:@"%@.%@ = %@", MNSS(@"CategoryId__c"), MNSS(@"Is_Top_Level__c"), @YES];
    
    NSArray *sortedCategoryConfigs  = [mac sortedCategoryConfigurations];
    NSPredicate *parentCatPredicate = [NSPredicate predicateWithFormat:format];
    NSArray *parentCategoryConfigs  = [sortedCategoryConfigs filteredArrayUsingPredicate:parentCatPredicate];

    for (MMSF_CategoryMobileConfig__c* catConfig in parentCategoryConfigs)
    {
        if ([catConfig[MNSS(@"IsDraft__c")] boolValue]) continue;
		
        MMSF_Category__c *category = [catConfig valueForKey:MNSS(@"CategoryId__c")];
        
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        if ([catConfig.Button_Text_Align__c isEqualToString:@"Left"])
        {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        }
        else if ([catConfig.Button_Text_Align__c isEqualToString:@"Center"])
        {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        }
        else if ([catConfig.Button_Text_Align__c isEqualToString:@"Right"])
        {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
        }

        // set button size, positioned in adjustForOrientation
        UIImage* img = [mac buttonDefaultImage];
        
        CGRect frame;
        frame.origin = CGPointZero;
        frame.size = img.size;
        button.frame = frame;
        
		[button addTarget:self action:@selector(categoryButtonTouched:)
         forControlEvents:UIControlEventTouchUpInside];
        
		button.tag = [[mac sortedCategoryConfigurations] indexOfObject: catConfig]+kButtonTagBase;
        
		[button setBackgroundImage: img forState: UIControlStateNormal];
		[button setBackgroundImage: [mac buttonHighlightImage] forState: UIControlStateHighlighted]; 
                
        [button setTitle:category.Name forState:UIControlStateNormal];
        [button setTitleColor:[mac buttonTextColor] forState:UIControlStateNormal];
        [button setTitle:category.Name forState:UIControlStateHighlighted];
        [button setTitleColor:[mac buttonTextHighlightColor] forState:UIControlStateHighlighted];
        
		button.accessibilityLabel = $S(@"Category: %@", category.Name);
        button.titleLabel.text = category.Name;
		button.alpha = self.nLevelShown ? 0.0 : 1.0;
        
		[self.buttons addObject:button];
		
		[self.buttonContainer addSubview:button];
    }
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
- (void) beginIntroAnimations {
	CGFloat delay = 2.0;
	IF_SIM (delay = 0.0);
	
	//First bring in the platform and text
	[UIView animateWithDuration:.75 delay:delay options:0 animations:^{
		self.instructionLabel.alpha = 1.0;
		self.background.alpha = 1.0;
        self.buttonContainer.alpha = 1.0;
        //!!!gmuself.navigationBar.alpha = 1,0;
	} completion:^(BOOL finished) {}];

	initialAnimationDone = YES;
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
-(void)dismissButtons {
	[self.searchField resignFirstResponder];
	[UIView animateWithDuration:.25 animations:^{
		for (UIButton *button in self.buttons) {
			button.alpha = 0.0;
		}
		self.instructionLabel.alpha = 0.0;
        [self adjustToolbarButtons];
	}];
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
-(void)showButtonsWithDelay:(CGFloat)delay {
    
    self.nLevelShown = NO;

	[UIView animateWithDuration:.25 delay:delay options:0 animations:^{
		for (UIButton *button in self.buttons) {
			button.alpha = 1.0;
		}
		self.instructionLabel.alpha = 1.0;
        [self adjustToolbarButtons];
        
	} completion:^(BOOL finished) {
		
	}];

}

#pragma mark - Actions
 /*
 */
- (void) abortCheckout: (UILongPressGestureRecognizer *) gesture {

    [g_appDelegate stopDocumentTrackingForEntity: nil];
    [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:NO];

    self.jumpToSF1Button.hidden = true;
    
    [MeetingDetailsViewController resetMeetingNotes];
}


- (void) categoryButtonTouched: (UIButton *) sender {
    if([MMSF_User currentUser] == nil)
        return;
    
	NSInteger			pressedButtonIndex = sender.tag-kButtonTagBase;
    
    MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
    
    MMSF_CategoryMobileConfig__c* catConfig = [[mac sortedCategoryConfigurations] objectAtIndex:pressedButtonIndex];
    
    self.nLevelShown = YES;
	self.searchField.searchField.text = @"";
	[self.searchField.searchField resignFirstResponder];
    
    [self setCurrentCategory: catConfig animated: YES];
    
}

- (IBAction) leadsButtonPressed: (id) sender {
    
	if ([MM_LoginViewController isLoggingIn] || ![MM_SyncManager sharedManager].hasSyncedOnce)
        return;
    
#ifndef CHECKIN_DISABLED
    
    if (g_appDelegate.currentTrackingType == DocumentTracking_DeferredLead) {
        
        [self checkOutForLead];
    }
    else if (g_appDelegate.currentTrackingType == DocumentTracking_SelectedLead) {
        
        if ([g_appDelegate.currentTrackingEntity isKindOfClass: [MMSF_Lead class]])
            [self checkOutForLead];
        else if ([g_appDelegate.currentTrackingEntity isKindOfClass: [MMSF_Contact class]])
            [self showLeads];
        
    }
    else {
        
        [self showLeads];
    }
#endif
}


/**
 *
 */
- (void) showLeads {
#if 0
    LeadSearchViewController    *leadSearchViewController   = [[LeadSearchViewController alloc] init];
    UINavigationController      *navigationController       = [[UINavigationController alloc] initWithRootViewController: leadSearchViewController];
    UIPopoverController         *popoverController          = [[UIPopoverController alloc] initWithContentViewController: navigationController];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                  target: self
                                                                                  action: @selector(dismissCurrentPopoverController:)];
    [leadSearchViewController.navigationItem setLeftBarButtonItem: cancelButton];
    
    
    [popoverController presentPopoverFromRect: self.leadsButton.bounds
                                       inView: self.leadsButton
                     permittedArrowDirections: UIPopoverArrowDirectionAny
                                     animated: YES];
    
#endif
    [self setCurrentPopoverController: [LeadSearchViewController popOverFromButton:self.leadsButton]];
}

#if 0
//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (IBAction) checkIn: (id) sender
{
    if ([MM_LoginViewController isLoggingIn] || ![MM_SyncManager sharedManager].hasSyncedOnce) return;
    
//#ifndef CHECKIN_DISABLED
    switch (g_appDelegate.currentTrackingType) {
        case DocumentTracking_DeferredContact:
        case DocumentTracking_SelectedContact:
            [self checkOut: sender];
            break;
            
            //		case DocumentTracking_DeferredContact:
            //			if ([g_appDelegate.documentTracker trackedDocumentCount] == 0) {
            //				[g_appDelegate stopDocumentTrackingForContact: nil];
            //				[self.checkInOuButton setImage: [UIImage imageNamed: @"ico_check-in"] forState: UIControlStateNormal];
            //				break;
            //			}
            
        default:
            [self setCurrentPopoverController:[CheckinContactSelectorViewController popOverFromButton: sender]];
            break;
    }
//#endif
}
#endif
/**
 *
 */
- (void) checkOutForLead {
    
#ifndef CHECKIN_DISABLED
	if ([MM_LoginViewController isLoggingIn])
        return;
    
//    if ([g_appDelegate.documentTracker trackedDocumentCount] > 0) {
//        
        [self showCheckOutFromButton: self.leadsButton];
//    }
//    else {
//        
//		[g_appDelegate stopDocumentTrackingForEntity: nil];
//        [self.leadsButton setImage: [UIImage imageNamed: @"icon-lead-checkin"] forState: UIControlStateNormal];
//        [self.leadsButton setAlpha: kButtonPartialAlpha];
//    }
#endif
}

/**
 *
 */
- (void) showCheckOutFromButton: (UIButton *) button {
    
    MeetingDetailsViewController    *meetingDetailsViewController   = [[MeetingDetailsViewController alloc] init];
    UINavigationController          *navigationController           = [[UINavigationController alloc] initWithRootViewController: meetingDetailsViewController];
    UIPopoverController             *popoverController              = [[UIPopoverController alloc] initWithContentViewController: navigationController];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                  target: self
                                                                                  action: @selector(dismissCurrentPopoverController:)];
    [meetingDetailsViewController.navigationItem setLeftBarButtonItem: cancelButton];
    
    [popoverController setPopoverContentSize: CGSizeMake(600, 550)];
    [popoverController presentPopoverFromRect: button.bounds
                                       inView: button
                     permittedArrowDirections: UIPopoverArrowDirectionAny
                                     animated: YES];
    
    [self setCurrentPopoverController: popoverController];
    self.currentPopoverController.delegate = self;
}

- (IBAction)pulseViewTapped:(UITapGestureRecognizer*)recognizer {
    if ([[UIDevice currentDevice] connectionType] != connection_none) {
        [[DSARestClient sharedInstance] deltaSync];
        [self.pulseView startAnimation];
    } else {
        [SA_AlertView showAlertWithTitle:@"Please try again when the device has Connectivity." message:nil];
    }
}

#pragma mark - Layout methods

- (void) positionButtonsForOrientation:(UIInterfaceOrientation)interfaceOrientation {
    MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
    CGRect frame;
    
    if (self.buttons.count != [mac sortedCategoryConfigurations].count) {
        [self setupButtons];
    }
    
    for (UIButton* button in self.buttons) {
        frame = button.frame;
        CGPoint origin = frame.origin;
        
        MMSF_CategoryMobileConfig__c* categoryConfig = [[mac sortedCategoryConfigurations] objectAtIndex:button.tag-kButtonTagBase];
        if (UIDeviceOrientationIsPortrait(interfaceOrientation)) {
            origin = [categoryConfig portraitButtonPosition];
        } else {
            origin = [categoryConfig landscapeButtonPosition];
        }
        frame.origin = [self adjustButtonOrigin:origin];
        button.frame = frame;
    }
}


- (void) layoutPulseView {
    
    CGRect frame = self.pulseView.frame;
    frame.origin.x = CGRectGetMinX(self.jumpToSF1Button.frame) - frame.size.width - 12.0;     //  12.0 = horizontal gap
    [self.pulseView setFrame: frame];
    
    CGPoint center = self.pulseView.center;
    center.y = self.jumpToSF1Button.center.y;
    [self.pulseView setCenter: center];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) adjustForOrientation:(UIInterfaceOrientation)interfaceOrientation {
    self.background.frame = self.view.bounds;
    [self layoutPulseView];
    
	MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
	if (mac != nil) {
		if (UIDeviceOrientationIsPortrait(interfaceOrientation)) {
			self.background.image = [mac portraitBackgroundImage];
		} else {
			self.background.image = [mac landscapeBackgroundImage];
		}
		
		[self positionButtonsForOrientation:interfaceOrientation];
	} else {
		if (UIDeviceOrientationIsPortrait(interfaceOrientation)) {
			self.background.image = [UIImage imageNamed:@"Default-Portrait~ipad.png"];
		} else {
			self.background.image = [UIImage imageNamed:@"Default-Landscape~ipad.png"];
		}
	}
	
	[self setCategoryBackgroundImage: [self.currentCategoryConfig categoryBackgroundImageForOrientation: self.interfaceOrientation] andTintColor: [UIColor clearColor]/*self.currentCategoryConfig.categoryBackgroundTintColor*/ animated: NO];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration 
{
    [self adjustForOrientation:interfaceOrientation];
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)syncProgressDidDismiss:(NSNotification*)note {
    if ([MM_SyncManager sharedManager].syncCancelled == NO) {
        // post an alert for now
        NSString *messageString = [NSString stringWithFormat:@"Synchronization completed successfully."];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Synchronization Completed" message:messageString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }

	//FIXME we should probably figure out a way to share contexts here
    MMSF_MobileAppConfig__c* mac = [g_appDelegate selectedMobileAppConfig];
	BOOL					wasExistingMAC = (mac != nil);

    MMSF_MobileAppConfig__c *activeConfig = [MMSF_MobileAppConfig__c activeMobileConfigInContext: mac.moc];
    
    if(activeConfig == nil || [mac.Active__c intValue] == 0)
    {
        mac = nil; 
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserDefaultKey_selectedMobileAppConfig];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    //need to handle case where selected config is no longer available after a sync
    if (mac != nil)
    {
        [self configureInterface];
    }
    else
    {
		MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
        if ([MMSF_MobileAppConfig__c activeConfigurationCountInContext: moc] > 1)
        {
            [self presentMobileConfigSelector:NO];
        }
        else
        {
            //set it
			if (wasExistingMAC) {
				[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Your Current Application is No Longer Available", nil)
										 message: NSLocalizedString(@"The Default application has been selected automatically.", nil)];
			}
			
            MMSF_MobileAppConfig__c* config = (MMSF_MobileAppConfig__c*)[MMSF_MobileAppConfig__c activeMobileConfigInContext: mac.moc];
            
            NSString* objId = [config valueForKey:@"Id"];
            
            [[NSUserDefaults standardUserDefaults] setObject:objId forKey:kUserDefaultKey_selectedMobileAppConfig];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_MobileAppConfigurtionChanged object:self];

            // Let other threads finish saving
            [self performSelector:@selector(configureInterface) withObject:nil afterDelay:1.0];
        }
    }
}


/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) contextChanged: (NSNotification *) note {
	if (self.isViewLoaded && !self.view.window) {
		self.currentSubCategory = nil;
		self.currentCategoryConfig = nil;
		[self applyConfiguration: NO];
		[self setupButtons];
		[self.view removeFromSuperview];
		self.view = nil;
	}
}


//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (IBAction) jumpToSalesforce1: (id) sender
{
	NSString				*objectID = g_appDelegate.currentTrackingEntity[@"Id"];
	NSString				*raw = $S(@"salesforce1://sObject/%@/view", objectID);
	NSURL					*url = [NSURL URLWithString: raw];
	
	if (url != nil) [[UIApplication sharedApplication] openURL: url];
}

- (BOOL) shouldShowSalesforce1Button {
	if (g_appDelegate.currentTrackingEntity == nil) { return false; }
    
    //JRB Disabling sf1 detection and default to true
	//if ([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: @"salesforce1://"]]) return true;
	IF_SIM(return true)
	return true;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (IBAction) checkIn: (id) sender
{
	if ([MM_LoginViewController isLoggingIn] || ![MM_SyncManager sharedManager].hasSyncedOnce) return;
	
#ifndef CHECKIN_DISABLED
	switch (g_appDelegate.currentTrackingType) {
		case DocumentTracking_DeferredContact:
		case DocumentTracking_SelectedContact:
			[self checkOut: sender];
			break;
	
//		case DocumentTracking_DeferredContact:
//			if ([g_appDelegate.documentTracker trackedDocumentCount] == 0) {
//				[g_appDelegate stopDocumentTrackingForContact: nil];
//				[self.checkInOuButton setImage: [UIImage imageNamed: @"ico_check-in"] forState: UIControlStateNormal];
//				break;
//			}
			
		default:
			[CheckinContactSelectorViewController popOverFromButton: sender];
			break;
	}
	self.jumpToSF1Button.hidden = ![self shouldShowSalesforce1Button];
#endif
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (IBAction) checkOut: (id) sender 
{
#ifndef CHECKIN_DISABLED
	if ([MM_LoginViewController isLoggingIn]) return;
//    if ([g_appDelegate.documentTracker trackedDocumentCount] > 0) {
//        [CheckoutReviewViewController popOverFromButton: sender];
//    } else {
//		[g_appDelegate stopDocumentTrackingForEntity: nil];
//		[self.checkInOuButton setImage: [UIImage imageNamed: @"ico_check-in"] forState: UIControlStateNormal];
//    }
    [self showCheckOutFromButton: sender];
#endif
}

////////////////////////////////////////////////////
// returns YES if email process started
////////////////////////////////////////////////////
- (BOOL) sendEmailWithViewedItems {
    if (![MFMailComposeViewController canSendMail] || [self.itemsToEmail count] == 0) {
        return NO;
    }

    EmailSubjectController *controller = [EmailSubjectController creaetEmailSubjectController];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];

    [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:NO];

    return YES;
}

- (void)updateCheckOutButtonsWithContactSelected:(BOOL)contactSelected andLeadSelected:(BOOL)leadSelected {
    NSString *contactImageName;
    NSString *leadImageName;
    CGFloat contactButtonAlpha;
    CGFloat leadButtonAlpha;

    if (contactSelected) {
        contactImageName = @"ico_check-out";
        contactButtonAlpha = 1.0;
    } else {
        contactImageName = @"ico_check-in";
        contactButtonAlpha = kButtonPartialAlpha;
    }

    if (leadSelected) {
        leadImageName = @"icon-lead-checkout";
        leadButtonAlpha = 1.0;
    } else {
        leadImageName = @"icon-lead-checkin";
        leadButtonAlpha = kButtonPartialAlpha;
    }

    [self.checkInOuButton setImage: [UIImage imageNamed: contactImageName] forState: UIControlStateNormal];
    [self.checkInOuButton setAlpha: contactButtonAlpha];
    [self.leadsButton setImage: [UIImage imageNamed: leadImageName] forState: UIControlStateNormal];
    [self.leadsButton setAlpha: leadButtonAlpha];
    self.jumpToSF1Button.hidden = ![self shouldShowSalesforce1Button];
}

////////////////////////////////////////////////////
// returns YES if task is created.  Only create task if we don't use mail to salesforce
////////////////////////////////////////////////////
- (BOOL) createEmailTask
{
    BOOL createTask = YES;
    
#if MAILTOSALESFORCE_ENABLED
    NSString* mailToAddress = @"emailtosalesforce@n-2or5imetpuonkzsicq0x3n7w3.uhymxma4.u.le.salesforce.com";
    //[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultKey_MailToSalesforceAddress];
    if (mailToAddress == nil)
    {
        createTask = NO;
    }
#endif
    
    if (createTask)
    {
        //        SF_Task* task = [SF_Task createTaskInContext:[SF_Store store].context];
        //        
        //        task.status = @"completed";
        //        task.subject = @"Email: Here are the documents you requested";
        //       // task.who = g_appDelegate.currentTrackingContact;
        //        task.priority = @"Normal";
        //        
        //        [[SF_Store store].context save];
        //        [SF_PendingCommit addPendingCommitForObject:task];
    }
    
    return createTask;
}

////////////////////////////////////////////////////
//
////////////////////////////////////////////////////
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    if (result ==  MFMailComposeResultSent)
    {
        [self createEmailTask];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
    [g_appDelegate stopDocumentTrackingForEntity: nil];
    [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:NO];
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) checkinEntitySelected:(NSNotification*) notification
{
    MMSF_Object *entity = (MMSF_Object *) [notification object];
    
    if (g_appDelegate.currentTrackingType == DocumentTracking_DeferredContact || g_appDelegate.currentTrackingType == DocumentTracking_DeferredLead) {
        
        if (g_appDelegate.currentTrackingType == DocumentTracking_DeferredContact && [notification.name isEqualToString: kCheckInLeadDeferred]) {
            
            g_appDelegate.currentTrackingType = DocumentTracking_DeferredLead;
            g_appDelegate.currentTrackingEntity = entity;   //set this so the Document tracker can properly create event and reviews

            [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:YES];

            [self dismissCurrentPopoverController: nil];
        }
        else if (g_appDelegate.currentTrackingType == DocumentTracking_DeferredLead && [notification.name isEqualToString: kCheckInContactDeferred]) {
            
            g_appDelegate.currentTrackingType = DocumentTracking_DeferredContact;
            g_appDelegate.currentTrackingEntity = entity;
            
            [self updateCheckOutButtonsWithContactSelected:YES andLeadSelected:NO];

            [self dismissCurrentPopoverController: nil];
        }
        else if ((g_appDelegate.currentTrackingType == DocumentTracking_DeferredContact && [notification.name isEqualToString: kCheckInContactSelected])
                 || (g_appDelegate.currentTrackingType == DocumentTracking_DeferredLead && [notification.name isEqualToString: kCheckInLeadSelected])) {
            
            g_appDelegate.currentTrackingEntity = entity;   //set this so the Document tracker can properly create event and reviews
            
            NSMutableArray *itemsToSend = [NSMutableArray array];
            for (NSInteger i = 0; i < [g_appDelegate.documentTracker trackedDocumentCount]; i++) {
                
                DocumentHistory* documentHistory = [g_appDelegate.documentTracker trackedDocumentAtIndex: i];
                
                if (documentHistory.markedToSend)
                    [itemsToSend addObject: documentHistory.salesforceId];
                
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName: kCheckoutDone object: itemsToSend];

            [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:NO];

            [g_appDelegate stopDocumentTrackingForEntity: entity];
        }
    }
    else {
        
        //  'entity' will be nil if "Choose Later" button was tapped. Therefore, go by the
        //   notification's name to identify the entity type.
        
        g_appDelegate.documentTracker.checkInStart = [NSDate date];
        
        if ([notification.name isEqualToString: kCheckInContactSelected] || [notification.name isEqualToString: kCheckInContactDeferred]) {
            
            [CheckinContactSelectorViewController dismissPopover];
            [g_appDelegate startDocumentTrackingForContact: (MMSF_Contact *) entity];

            [self updateCheckOutButtonsWithContactSelected:YES andLeadSelected:NO];
        }
        else if ([notification.name isEqualToString: kCheckInLeadSelected] || [notification.name isEqualToString: kCheckInLeadDeferred]) {
            
            [LeadSearchViewController dismissPopover];
            [g_appDelegate startDocumentTrackingForLead: (MMSF_Lead *) entity];

            [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:YES];
        }
        
        [self dismissCurrentPopoverController: nil];
    }
	
	self.jumpToSF1Button.hidden = ![self shouldShowSalesforce1Button];
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) displayMobileConfigSelector:(NSNotification*) notification {
    [self presentMobileConfigSelector: YES];
}

////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////
- (NSArray *) processRatingsReturningViewedItems
{    
	self.jumpToSF1Button.hidden = ![self shouldShowSalesforce1Button];
    return [g_appDelegate.documentTracker createReviewObjects];
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) checkoutDone:(NSNotification*) notification {
    
//    [CheckoutReviewViewController dismissPopover];
    [self dismissCurrentPopoverController: nil];
    
    [self processRatingsReturningViewedItems];

    self.itemsToEmail = notification.object ?: @[];
    // Have to implement the Email Feature
    
    BOOL sendingEmail = [self sendEmailWithViewedItems];
    
    if (!sendingEmail) {
        [g_appDelegate stopDocumentTrackingForEntity: nil];
        [self updateCheckOutButtonsWithContactSelected:NO andLeadSelected:NO];
    }
    
	self.jumpToSF1Button.hidden = ![self shouldShowSalesforce1Button];
}
///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) checkoutCanceled:(NSNotification*) notification
{
	[self dismissCurrentPopoverController: nil];
    self.currentPopoverController = nil;
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (BOOL) isCheckedIn
{
    return (g_appDelegate.currentTrackingType != DocumentTracking_None);
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) userDidLogOut
{
    
}

#pragma mark - MobileConfigSelectionViewControllerDelegate

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) mobileConfigSelectionCanceled:(MobileConfigSelectionViewController*) mobileConfigSelectionViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) mobileConfigSelected:(MMSF_MobileAppConfig__c*) config controller:(MobileConfigSelectionViewController*)mobileConfigSelectionViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureInterface];

    [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_MobileAppConfigurtionChanged 
                                                        object:self];
}

- (void) searchFieldDidBeginEditing: (DSA_SearchField *) field {
	self.searchField.alpha = 1.0;
}

- (void) searchFieldDidFinishEditing: (DSA_SearchField *) field {
	self.searchField.alpha = 0.35;
}

/***
 Search the MOC for ContentVersion objects that match a search string instead of iterating categories, etc.
 While this method is significantly faster (14ms vs 46s for 5 GB of content), it is _not_ limited to the selected
 Mobile App Config (searches all content) and will not be appropriate for every DSA. Respects internal mode.
 ***/
- (NSArray*) fastContentSearchForString:(NSString*)searchString {
    BOOL isInternalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(Title CONTAINS[c] %@ OR TagCsv CONTAINS[c] %@)", searchString, searchString];
    if (!isInternalMode) {
        NSString				*format = $S(@"%@ == 0 || %@ == nil", MNSS(@"Internal_Document__c"), MNSS(@"Internal_Document__c"));
		NSPredicate				*internalPredicate = [NSPredicate predicateWithFormat: format];
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[ internalPredicate, predicate] ];
    }

    MM_ManagedObjectContext	*moc = [MM_ContextManager sharedManager].threadContentContext;
    CFTimeInterval start = CACurrentMediaTime();
    NSArray *results = [moc allObjectsOfType:@"ContentVersion" matchingPredicate:predicate];
    CFTimeInterval stop = CACurrentMediaTime();
    MMLog(@"*** MOC search returned %d results in %f seconds", results.count, stop - start);
	
	NSMutableArray		*filteredResults = [NSMutableArray new];
	for (MMSF_ContentVersion *content in results) {
		if (content.categoryLocationPath.length > 0) [filteredResults addObject: content];
	}
	return filteredResults;

 //   return results;
}

- (void) searchBarDidHitSearchWithText: (NSString *) text {
	NSString				*searchString = text;
	NSArray					*results = nil;
	Class					resultsClass = [ZM_SearchResultsController class];
    
	MM_ManagedObjectContext	*moc = [MM_ContextManager sharedManager].threadContentContext;
    NSArray *macArray = [MMSF_MobileAppConfig__c allActiveMobileConfigurationsInContext:moc];
    NSUInteger macCount = macArray.count;
	
    if (macCount == 1) {
        results = [self fastContentSearchForString:text];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(Title CONTAINS[c] %@ OR TagCsv CONTAINS[c] %@)", searchString, searchString];
        CFTimeInterval start = CACurrentMediaTime();
        results = [[MMSF_User currentUser] allDocumentsMatchingPredicate:predicate];
        CFTimeInterval stop = CACurrentMediaTime();
        MMLog(@"*** existing search returned %d results in %f seconds", results.count, stop - start);
    }
    
	if (results.count) {
        // clear the search field
        UITextField *searchTexField = self.searchField.searchField;
        searchTexField.text = @"";
        [searchTexField resignFirstResponder];
        
		[self.navigationController pushViewController: [resultsClass controllerWithSearchString: searchString andResults: results] animated: YES];
	} else {
		[SA_AlertView showAlertWithTitle: @"Sorry, your search turned up no results." message: nil];
	}
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	NSString				*searchString = searchBar.text;
	NSArray					*results = nil;
	Class					resultsClass = [ZM_SearchResultsController class];
	NSPredicate				*predicate = nil;
	
    predicate = [NSPredicate predicateWithFormat: @"(Title CONTAINS[c] %@ OR TagCsv CONTAINS[c] %@)", searchString, searchString];
    
    results = [[MMSF_User currentUser] allDocumentsMatchingPredicate:predicate];
    
	if (results.count) {
		[self.navigationController pushViewController: [resultsClass controllerWithSearchString: searchString andResults: results] animated: YES];
	} else {
		[SA_AlertView showAlertWithTitle: @"Sorry, your search turned up no results." message: nil];
	}
}

#pragma mark - Notifications

- (void) settingsShown:(NSNotification*) notification {
    self.checkInOuButton.enabled = NO;
    self.leadsButton.enabled = NO;
}

- (void) settingsDismissed:(NSNotification*) notification {
    self.checkInOuButton.enabled = YES;
    self.leadsButton.enabled = YES;
}

- (void) checkinoutShown:(NSNotification*) notification {
}

- (void) checkinoutDismissed:(NSNotification*) notification {
}

- (void) reloadConfiguration:(NSNotification*) notification {
    [self configureInterface];
}

-(void)userChanged:(NSNotification*)note{
    [self applyConfiguration:YES];
}

- (void)internalModeSwitchEngaged:(NSNotification *)aNotif {
    [self configureInterface];
}

- (void)newContentAvailable:(NSNotification *)aNotif {
        
    if (_nLevelShown)
        self.pulseView.alpha = 0;
    else
        self.pulseView.alpha = 0.35f;
    
}

- (void)syncCompleted:(NSNotification *)aNotif {
    [self.pulseView stopAnimation];
    self.pulseView.alpha = 0;
}

- (BOOL)prefersStatusBarHidden
{   BOOL prefersHidden = !(self.currentCategoryConfig == nil);
    NSLog(@"VB->prefers hidden=%d",prefersHidden);
    return prefersHidden;
}

- (void)presentEmailComposerWithSubject:(NSString *)subject {
    MFMailComposeViewController *mailController = [MMSF_ContentVersion controllerForMailing];
    mailController.mailComposeDelegate = self;
    [mailController setSubject:@"Documents you requested"];
    
    NSString *email = nil;
    if (g_appDelegate.currentTrackingEntity) {
        
        if ([g_appDelegate.currentTrackingEntity isKindOfClass: [MMSF_Contact class]])
            email = ((MMSF_Contact *) g_appDelegate.currentTrackingEntity).Email;
        else if ([g_appDelegate.currentTrackingEntity isKindOfClass: [MMSF_Lead class]])
            email = ((MMSF_Lead *) g_appDelegate.currentTrackingEntity).Email;
        
    }
    
    if (email != nil)
    {
        [mailController setToRecipients:[NSArray arrayWithObject:email]];
    }
    
    // Fill out the email body text.
    NSMutableString* emailBody = [NSMutableString stringWithString:@"<p>Here are the documents you requested during our meeting.</p>"];

    BOOL hasLinkInBody = NO;
    for (NSString* itemId in self.itemsToEmail)
    {
        MMSF_ContentVersion* item = [MMSF_ContentVersion contentItemBySalesforceId:itemId];
        
        NSString * itemBody = [item contentBodyForMailing];
        if (itemBody && itemBody.length)
        {
            if (!hasLinkInBody) {
                hasLinkInBody = YES;
                [emailBody appendString:@"<p>Links to content:</p>"];
            }
            [emailBody appendString:itemBody];
        } else
        {
            // add attachment
            [mailController addAttachmentData:[item contentItemAsData] mimeType:item.mimeType fileName:item.filenameForMailing];
        }
    }
    
    [mailController setMessageBody:emailBody isHTML:YES];
    [mailController setSubject:subject];

    [self presentViewController:mailController animated:YES completion:nil];
}

- (void)emailSubjectSelected:(NSString *)subject {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self presentEmailComposerWithSubject:subject];
}

- (void)emailSubjectCanceled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
