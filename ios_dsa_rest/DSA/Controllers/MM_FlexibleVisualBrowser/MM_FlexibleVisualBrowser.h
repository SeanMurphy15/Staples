//
//  MM_ImprovedVisualBrowser.h
//  ModelMetrics
//
//  Created by Ben Gottlieb on 2/1/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "MobileConfigSelectionViewController.h"

@class SF_CategoryMobileConfig;
@class SF_Category;
@class DSA_CategoryContentsViewController;
@class DSA_PulseView;
@class DSA_SearchField;

#define			kNotification_VisualBrowserSubCategorySelected @"kNotification_VisualBrowserSubCategorySelected"

typedef enum  
{
    FB_ToolbarStateCheckin=0,
    FB_ToolbarStateCheckout,
    FB_ToolbarStateNoTracking
} FBToolbarState;

@interface MM_FlexibleVisualBrowser : UIViewController <UIPopoverControllerDelegate, MFMailComposeViewControllerDelegate, MobileConfigSelectionViewControllerDelegate, UISearchBarDelegate, UIToolbarDelegate> {
	NSString	*_currentCategoryName;
    BOOL        initialAnimationDone;
}

@property (nonatomic, readwrite, strong) IBOutlet UILabel *instructionLabel;
@property (nonatomic, readwrite, strong) IBOutlet UIImageView *background, *categoryBackgroundImageView;
@property (nonatomic, readwrite, strong) IBOutlet UIView *buttonContainer, *categoryBackgroundTintView;

@property (nonatomic, strong) DSA_CategoryContentsViewController *currentCategoryController;

@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (nonatomic, weak) IBOutlet UIButton *leadsButton;
@property (nonatomic, weak) IBOutlet UIButton *jumpToSF1Button;
@property (nonatomic, weak) IBOutlet UIButton *checkInOuButton;
@property (nonatomic, weak) IBOutlet UIButton *settingsButton;
@property (nonatomic, weak) IBOutlet DSA_PulseView *pulseView;
@property (nonatomic, weak) IBOutlet DSA_SearchField *searchField;

@property (nonatomic, readwrite, strong) MMSF_Category__c *currentSubCategory;

@property (nonatomic, readwrite, strong) NSString *currentCategoryName;
@property (nonatomic, readwrite, strong) MMSF_CategoryMobileConfig__c *currentCategoryConfig;

@property (nonatomic, readwrite, strong) NSMutableArray *buttons;
@property (nonatomic, readonly) BOOL isCheckedIn;
@property (nonatomic, strong) UIView *categoryBackgroundContainerView;

+ (instancetype) controller;
+ (UINavigationController*)navController;

- (void) categoryButtonTouched: (id) sender;

- (IBAction)pulseViewTapped:(UITapGestureRecognizer*)recognizer;
- (IBAction) showSettingsMenu: (id) sender;

- (void) adjustForOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (void) showContentsForCategory: (MMSF_Category__c *) category;
- (void)showButtonsWithDelay:(CGFloat)delay;

@end
