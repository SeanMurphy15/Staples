//
//  DSA_SettingsMenuViewController.m
//  ios_dsa
//
//  Created by Guy Umbright on 11/2/11.
//  Copyright (c) 2011 Kickstand Software. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
// Customizing DSA_SettingsMenuViewController
//
// The Settings menu is based upon a UITableView is a dynamically built.  The default entry type is a
// cell containing a button, but it is possible to specify a custom cell type
//
// Important methods
// -----------------
//
// - (void) initMenuItems
//
//   This is the method where the possible entries in the menu are defined.
//   Entries are held in member variables for use later in assembling the desired menu contents
//
//   Entries are in the form of an NSDictionary.  Default entries need the keys:
//
//    kTitleKey - Button title
//    kTargetKey - method selector to call when pressed
//    kIconKey - name of image to display as icon
//    kCellTypeKey - specifies the position in the group so that the proper background is displayed
//   
//   Custom cells should specify the keys:
//
//    kCustomCellClassKey - string that identifies the class, nib, and reuse identfier
//                          That, of course, indicates that the nib name for the cell should match the class name and the 
//                          reuse identifier specified in interface builder should match as well.
//    kCellTypeKey - for custom cells should be set to [NSNumber numberWithInteger: kSettingsCellType_Custom] 
//
//
//
// - (void) buildMenu
//
//   This method bulds the contents for the menu.  The menu items are stored in array of dictionaries, each element specifying a section
//   of the table.  The dictionaries should include the following keys:
//
//    kSectionTitleKey - string to display for the section header
//    kSectionItemsKey - array of menu items in the section
//
// Custom cells
// ------------
// Custom cells are to be implemented via nibs containing UITableViewCell
// 
// For an example, look for code framed by APP_STORE_BUILD
//
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////

#import "DSA_SettingsMenuViewController.h"
#import "DSA_SettingsMenuCell.h"
#import "DSA_AppDelegate.h"
#import "HY_HTMLHelpController.h"
#import "DSA_ReportBugController.h"
#import "DSA_AboutPaneController.h"
#import "MM_Notifications.h"
#import "DSA_SettingsMenuInternalModeCell.h"
#if APP_STORE_BUILD
#import "DSA_SettingsMenuDemoCell.h"
#endif
#import "MMSF_User.h"
#import "MMSF_MobileAppConfig__c.h"
#import "MM_ContextManager.h"
#import "HY_HTML5DemoController.h"
#import "DSA_CellularDataDefender.h"

static UIPopoverController			*s_popoverController = nil;
static DSA_SettingsMenuViewController  *s_controller;

enum SettingsCellType {
    kSettingsCellType_Top=0,
    kSettingsCellType_Middle,
    kSettingsCellType_Bottom,
    kSettingsCellType_Single,
    kSettingsCellType_Custom
};

#define kTitleKey @"title"
#define kTargetKey @"target"
#define kIconKey @"icon"
#define kCellTypeKey @"type"
#define kSectionTitleKey @"sectionTitle"
#define kSectionItemsKey @"sectionItems"
#define kCustomCellClassKey @"cellClass"

@interface DSA_SettingsMenuViewController ()

@property (nonatomic, strong) NSArray* menuItems;
@property (nonatomic, strong) NSDictionary* signinItem, *soloSigninItem;
@property (nonatomic, strong) NSDictionary* signoutItem;
@property (nonatomic, strong) NSDictionary* selectItem;
@property (nonatomic, strong) NSDictionary* syncItem;
@property (nonatomic, strong) NSDictionary* helpItem;
@property (nonatomic, strong) NSDictionary* reportItem;
@property (nonatomic, strong) NSDictionary* html5Item;
@property (nonatomic, strong) NSDictionary* aboutItem;
@property (nonatomic, retain) NSDictionary* internalDocsItem;

/**
 * This property references the UIView subclass element that "presents"
 * this popover. Could be uiview, button, baritem, etc.
 */

@property (nonatomic, weak) id popoverItem;

#if APP_STORE_BUILD
@property (nonatomic, strong) NSDictionary* demoItem;
@property (nonatomic, strong) NSDictionary* loadDemoContentItem;
#endif

- (void)internalModeSwitchEngaged:(NSNotification *)aNotif;
- (void)orientationChanged:(NSNotification *)notification;

@end

@implementation DSA_SettingsMenuViewController

+ (DSA_SettingsMenuViewController *) controller {
    if (s_controller == nil) {
        s_controller = [[self alloc] init];

		[[NSNotificationCenter defaultCenter] addObserver: s_controller selector: @selector(dismissPopover) name: kNotification_ModelUpdateBegan object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: s_controller selector: @selector(dismissPopover) name: kNotification_SyncBegan object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: s_controller selector: @selector(dismissPopover) name: kNotification_SyncResumed object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: s_controller selector: @selector(dismissPopover) name: kNotification_SyncWillResume object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:s_controller
                                                 selector:@selector(internalModeSwitchEngaged:)
                                                     name:kDSAInternalModeNotificationKey
                                                   object:nil];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:s_controller
                                                 selector:@selector(orientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];

    }

	return s_controller;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
+ (void) popOverFromBarButtonItem: (UIBarButtonItem *) item {
    [self popOverFromBarButtonItem:item dismissable:YES];
}

+ (void) popOverFromButton: (UIButton *) button {
    [self popOverFromButton: button dismissable:YES];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
+ (void) popOverFromButton: (UIButton *) button dismissable:(BOOL) dismissable {
	if (s_popoverController) return;
	
    if ([MM_SyncManager sharedManager].isSyncInProgress) return;
    
	DSA_SettingsMenuViewController				*controller = [self controller];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: controller];
    
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: nav];
	
	s_popoverController.delegate = controller;

	controller.canDismiss  = dismissable;
    controller.popoverItem = button;
    
	[s_popoverController presentPopoverFromRect: button.bounds inView: button permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
+ (void) popOverFromBarButtonItem: (UIBarButtonItem *) item dismissable:(BOOL) dismissable {
	if (s_popoverController) return;
	
    if ([MM_SyncManager sharedManager].isSyncInProgress) return;
    
	DSA_SettingsMenuViewController				*controller = [self controller];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: controller];
    
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: nav];
	
	s_popoverController.delegate = controller;

	controller.canDismiss  = dismissable;
    controller.popoverItem = item;
    
	[s_popoverController presentPopoverFromBarButtonItem: item permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void) initMenuItems {
    self.signinItem = [NSDictionary dictionaryWithObjectsAndKeys: @"Sign In",kTitleKey,
                       [NSValue valueWithPointer:@selector(signInPressed:)],kTargetKey,
                       @"about-btn-icon-signin",kIconKey,
                       [NSNumber numberWithInteger: kSettingsCellType_Top], kCellTypeKey, nil];
    
    self.soloSigninItem = [NSDictionary dictionaryWithObjectsAndKeys: @"Sign In",kTitleKey,
                       [NSValue valueWithPointer:@selector(signInPressed:)],kTargetKey,
                       @"about-btn-icon-signin",kIconKey,
                       [NSNumber numberWithInteger: kSettingsCellType_Single], kCellTypeKey, nil];
    
    self.signoutItem = [NSDictionary dictionaryWithObjectsAndKeys:@"Sign Out",kTitleKey,
                        [NSValue valueWithPointer:@selector(signInPressed:)],kTargetKey,
                        @"about-btn-icon-signout",kIconKey,
                        [NSNumber numberWithInteger: kSettingsCellType_Top], kCellTypeKey, nil];
    
    self.selectItem = [NSDictionary dictionaryWithObjectsAndKeys:@"Select Configuration",kTitleKey,
                       [NSValue valueWithPointer:@selector(selectPressed:)],kTargetKey,
                       @"applications-icon",kIconKey,
                       [NSNumber numberWithInteger: kSettingsCellType_Middle], kCellTypeKey, nil];
    
    self.syncItem = [NSDictionary dictionaryWithObjectsAndKeys:@"Synchronize",kTitleKey,
                     [NSValue valueWithPointer:@selector(synchronizePressed:)],kTargetKey,
                     @"about-btn-icon-sync",kIconKey,
                     [NSNumber numberWithInteger: kSettingsCellType_Bottom], kCellTypeKey, nil];
    
    self.helpItem = [NSDictionary dictionaryWithObjectsAndKeys:@"Help",kTitleKey,
                     [NSValue valueWithPointer:@selector(helpPressed:)],kTargetKey,
                     @"about-btn-iconhelp",kIconKey,
                     [NSNumber numberWithInteger: kSettingsCellType_Top], kCellTypeKey, nil];
    
    self.internalDocsItem = [NSDictionary dictionaryWithObjectsAndKeys:@"DSA_SettingsMenuInternalModeCell",kCustomCellClassKey,
                             [NSNumber numberWithInteger: kSettingsCellType_Custom], kCellTypeKey, nil];
    
#ifdef IPCONNECT
    self.reportItem = [NSDictionary dictionaryWithObjectsAndKeys:@"Report a Problem",kTitleKey,
                       [NSValue valueWithPointer:@selector(reportProblemPressed:)],kTargetKey,
                       @"about-btn-icon-report",kIconKey,
                       [NSNumber numberWithInteger: kSettingsCellType_Bottom], kCellTypeKey, nil];
#else    
    self.reportItem = [NSDictionary dictionaryWithObjectsAndKeys:@"Report a Problem",kTitleKey,
                       [NSValue valueWithPointer:@selector(reportProblemPressed:)],kTargetKey,
                       @"about-btn-icon-report",kIconKey,
                       [NSNumber numberWithInteger: kSettingsCellType_Middle], kCellTypeKey, nil];
#endif
    self.html5Item = [NSDictionary dictionaryWithObjectsAndKeys:@"HTML5 Example",kTitleKey,
                      [NSValue valueWithPointer:@selector(HTML5Pressed:)],kTargetKey,
                      @"about-btn-icon-html5",kIconKey,
                      [NSNumber numberWithInteger: kSettingsCellType_Bottom], kCellTypeKey, nil];
    
    self.aboutItem = [NSDictionary dictionaryWithObjectsAndKeys:@"About DSA",kTitleKey,
                      [NSValue valueWithPointer:@selector(aboutPressed:)],kTargetKey,
                      @"about-btn-about",kIconKey,
                      [NSNumber numberWithInteger: kSettingsCellType_Single], kCellTypeKey, nil];
    
#if APP_STORE_BUILD
    self.demoItem = [NSDictionary dictionaryWithObjectsAndKeys:@"DSA_SettingsMenuDemoCell",kCustomCellClassKey,
                     [NSNumber numberWithInteger: kSettingsCellType_Custom], kCellTypeKey, nil];
    
    self.loadDemoContentItem = [NSDictionary dictionaryWithObjectsAndKeys: @"Load Demo Content",kTitleKey,
                                [NSValue valueWithPointer:@selector(loadDemoContentPressed:)],kTargetKey,
                                @"about-btn-icon-signin",kIconKey,
                                [NSNumber numberWithInteger: kSettingsCellType_Single], kCellTypeKey, nil];
    
#endif
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void) buildMenu			//FIXME should probably pass in a MOC 
{
    NSArray* items;
    
	
	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;

	if ([MM_SyncManager sharedManager].isSyncInProgress || [MM_SyncManager sharedManager].syncInterrupted) {
		items = [NSArray arrayWithObjects: self.signoutItem, self.selectItem, self.syncItem,nil];
	} else if (![MM_SyncManager sharedManager].hasSyncedOnce) {
		//[g_appDelegate logout];
		items = [NSArray arrayWithObjects: self.soloSigninItem, nil];
	} else if ([MMSF_MobileAppConfig__c activeConfigurationCountInContext: moc] > 1)
    {
        if ([MM_LoginViewController isLoggedIn])
        {
            items = [NSArray arrayWithObjects: self.signoutItem, self.selectItem, self.syncItem,nil];
        }
        else
        {
            items = [NSArray arrayWithObjects: self.signinItem, self.selectItem, self.syncItem,nil];
        }
    }
    else
    {
        if ([MM_LoginViewController isLoggedIn])
        {
            items = [NSArray arrayWithObjects: self.signoutItem, self.syncItem,nil];
        }
        else
        {
            items = [NSArray arrayWithObjects: self.signinItem, self.syncItem,nil];
        }
    }
    
    NSDictionary* utilitiesSection = [NSDictionary dictionaryWithObjectsAndKeys:@"Utilities",kSectionTitleKey,
                                  items,kSectionItemsKey,nil];
    
   
    NSDictionary* supportSection = [NSDictionary dictionaryWithObjectsAndKeys:@"Support",kSectionTitleKey,
                                  [NSArray arrayWithObjects:self.helpItem,self.reportItem,self.html5Item,nil],kSectionItemsKey,nil];
    
    
    NSDictionary* aboutSection = [NSDictionary dictionaryWithObjectsAndKeys:@"About",kSectionTitleKey,
                    [NSArray arrayWithObjects:self.aboutItem,nil],kSectionItemsKey,nil];
    
  
    NSDictionary* securitySection = [NSDictionary dictionaryWithObjectsAndKeys:@"Security",kSectionTitleKey,
                                     [NSArray arrayWithObjects:self.internalDocsItem, nil],kSectionItemsKey, nil];
    
    
    NSArray* menu = [NSArray arrayWithObjects:utilitiesSection, securitySection, supportSection, aboutSection, nil];
    
    self.menuItems = menu;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (id)init {
    self = [super initWithNibName:@"DSA_SettingsMenu" bundle:nil];
    if (self) {
#if APP_STORE_BUILD
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(demoModeChanged:) 
                                                     name:DEMO_MODE_CHANGED_NOTIFICATION 
                                                   object:nil];
#endif
		
		[self addAsObserverForName: kNotification_LogInViewDidAppear selector: @selector(dismissPopover)];
        [self initMenuItems];
        [self buildMenu];
    }
    return self;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
#if APP_STORE_BUILD
    self.demoItem = nil;
    self.loadDemoContentItem = nil;
#endif

}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

///////////////////////////////////////////
//
///////////////////////////////////////////
- (CGFloat) heightForCellType:(NSInteger) cellType {
    CGFloat cellHeight=0.0;
    
    switch (cellType) {
        case kSettingsCellType_Top:
            cellHeight = 59.0;
            break;
            
        case kSettingsCellType_Middle:
            cellHeight = 61.0;
            break;
            
        case kSettingsCellType_Bottom:
            cellHeight = 51.0;
            break;
            
        case kSettingsCellType_Single:
            cellHeight = 53.0;
            break;
            
        case kSettingsCellType_Custom:
            cellHeight = 44.0;
            break;
    }
    
    return cellHeight;
    
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (CGFloat) menuHeight {
    CGFloat height = 0;
    
    for (NSDictionary* section in self.menuItems) {
        height += 40;
        
        for (NSDictionary* menuItem in [section objectForKey:kSectionItemsKey]) {
            height += [self heightForCellType:[[menuItem objectForKey:kCellTypeKey] integerValue]];
            
        }
    }
    
    return height;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void)viewDidLoad {
    [super viewDidLoad];
    
    isAboutPressed = NO;
    self.table.backgroundColor = [UIColor clearColor];
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_POPOVER_PRESENTED object:self];
    self.navigationController.navigationBarHidden = YES;
}

//////////////////////////////////////////////////
//Modified By India Team to fix Bug No 
//////////////////////////////////////////////////
- (void) viewDidDisappear:(BOOL) animated {
    [super viewDidDisappear:animated];
    
    if (!isAboutPressed) 
        [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_POPOVER_DISMISSED
                object:self];
    else
        isAboutPressed = NO;
    
}

///////////////////////////////////////////
//
///////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.menuItems.count;
}


///////////////////////////////////////////
//
///////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary* sectionDict = [self.menuItems objectAtIndex: section];
    NSArray* sectionItems = [sectionDict objectForKey:kSectionItemsKey];
    return sectionItems.count;
}

///////////////////////////////////////////
//
///////////////////////////////////////////
- (void) configureTopCell:(DSA_SettingsMenuCell*) cell withMenuItem:(NSDictionary*) menuItem {
    [cell.button setBackgroundImage: [UIImage imageNamed:@"about-btn-top"] forState:UIControlStateNormal];
    
    cell.button.frame = CGRectMake(20,0,278,59);
}

///////////////////////////////////////////
//
///////////////////////////////////////////
- (void) configureMiddleCell:(DSA_SettingsMenuCell*) cell withMenuItem:(NSDictionary*) menuItem {
    [cell.button setBackgroundImage: [UIImage imageNamed:@"about-btn-middle"] forState:UIControlStateNormal];
    cell.button.frame = CGRectMake(20,0,278,61);
}

///////////////////////////////////////////
//
///////////////////////////////////////////
- (void) configureBottomCell:(DSA_SettingsMenuCell*) cell withMenuItem:(NSDictionary*) menuItem {
    [cell.button setBackgroundImage: [UIImage imageNamed:@"about-btn-bottom"] forState:UIControlStateNormal];
    cell.button.frame = CGRectMake(20,0,278,51);
}

///////////////////////////////////////////
//
///////////////////////////////////////////
- (void) configureSingleCell:(DSA_SettingsMenuCell*) cell withMenuItem:(NSDictionary*) menuItem {
    [cell.button setBackgroundImage: [UIImage imageNamed:@"about-btn"] forState:UIControlStateNormal];
    cell.button.frame = CGRectMake(20,0,278,53);
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* resultCell = nil;
    
    NSDictionary* sectionDict = [self.menuItems objectAtIndex:[indexPath section]];
    NSArray* sectionItems = [sectionDict objectForKey:kSectionItemsKey];
    NSDictionary* menuItem = [sectionItems objectAtIndex:[indexPath row]];
    
    if ([[menuItem objectForKey:kCellTypeKey] integerValue] == kSettingsCellType_Custom) {
        //load the cell
        resultCell = [tableView dequeueReusableCellWithIdentifier:[menuItem objectForKey:kCustomCellClassKey]];
        if (resultCell == nil) 
        {
            UINib* nib = [UINib nibWithNibName:[menuItem objectForKey:kCustomCellClassKey] bundle:nil];
            NSArray* arr = [nib instantiateWithOwner:nil options:nil];
            resultCell = [arr objectAtIndex:0];
            resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else {
        DSA_SettingsMenuCell *cell = nil;
        
        cell = (DSA_SettingsMenuCell*) [tableView dequeueReusableCellWithIdentifier:@"settingsCell"];
        if (cell == nil) {
            UINib* nib = [UINib nibWithNibName:@"DSA_SettingsMenuCell" bundle:nil];
            NSArray* arr = [nib instantiateWithOwner:nil options:nil];
            cell = [arr objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        switch ([[menuItem objectForKey:kCellTypeKey] integerValue]) {
            case kSettingsCellType_Top:
                [self configureTopCell:cell withMenuItem:menuItem];
                break;
                
            case kSettingsCellType_Middle:
                [self configureMiddleCell:cell withMenuItem:menuItem];
                break;
                
            case kSettingsCellType_Bottom:
                [self configureBottomCell:cell withMenuItem:menuItem];
                break;
                
            case kSettingsCellType_Single:
                [self configureSingleCell:cell withMenuItem:menuItem];
                break;
        }
        
        [cell.button setImage: [UIImage imageNamed:[menuItem objectForKey:kIconKey]] forState:UIControlStateNormal];
        [cell.button setTitle:[menuItem objectForKey:kTitleKey] forState:UIControlStateNormal];
		cell.accessibilityLabel = menuItem[kTitleKey];
        
        
        for (UIGestureRecognizer* recognizer in cell.button.gestureRecognizers) {
            [cell.button removeGestureRecognizer:recognizer];
        }
        
        if (menuItem == self.syncItem) {
            UILongPressGestureRecognizer* gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self 
                                                                                             action:@selector(fullSynchronize:)];
            gr.minimumPressDuration = 2.0;
            [cell.button addGestureRecognizer:gr];
        }

        if (menuItem == self.syncItem) {
            BOOL trackingAlwaysOn = g_appDelegate.currentTrackingType == DocumentTracking_AlwaysOn;
            BOOL trackingTypeNone = g_appDelegate.currentTrackingType == DocumentTracking_None;
            BOOL loggedIn = [MM_LoginViewController isLoggedIn];
            BOOL checkingForUpdatedContent = g_appDelegate.contentUpdateCheckQueue.operationCount > 0;
            cell.button.enabled = (loggedIn && !checkingForUpdatedContent && (trackingAlwaysOn || trackingTypeNone));
        }
        
        if (menuItem == self.selectItem) {
            cell.button.enabled = [MM_LoginViewController isLoggedIn];
        }
        
        if(menuItem == self.signoutItem) {
            
            cell.button.enabled =  ((g_appDelegate.currentTrackingType == DocumentTracking_AlwaysOn || g_appDelegate.currentTrackingType == DocumentTracking_None));
        }
        
        SEL aSel = [[menuItem objectForKey:kTargetKey] pointerValue];
        [cell.button removeTarget:self action:NULL forControlEvents: UIControlEventTouchUpInside];
        [cell.button addTarget:self action:aSel forControlEvents: UIControlEventTouchUpInside];
        resultCell = cell;
    }
    
    return resultCell;
}

///////////////////////////////////////////
//
///////////////////////////////////////////
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* header = [[[UIView alloc] initWithFrame:CGRectMake(0,0,self.table.frame.size.width,40)] autorelease];
    UILabel* label = [[[UILabel alloc] initWithFrame:CGRectMake(25,0,self.table.frame.size.width-25,40)] autorelease];
    [header addSubview:label];
    
    label.font = [UIFont fontWithName:@"Helvetica" size:18.0];
    label.textColor = [UIColor grayColor];
    
    NSDictionary* sectionDict = [self.menuItems objectAtIndex:section];
    
    label.text = [sectionDict objectForKey:kSectionTitleKey];
    
    return header;
}
///////////////////////////////////////////
//
///////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}


///////////////////////////////////////////
//
///////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight;
    
    NSDictionary* sectionDict = [self.menuItems objectAtIndex:[indexPath section]];
    NSArray* sectionItems = [sectionDict objectForKey:kSectionItemsKey];
    NSDictionary* menuItem = [sectionItems objectAtIndex:[indexPath row]];
    
    cellHeight = [self heightForCellType:[[menuItem objectForKey:kCellTypeKey] integerValue]];
                  
    return cellHeight;
}

#pragma mark - UIPopoverControllerDelegate

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController {
    s_controller        = nil;
	s_popoverController = nil;
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
- (BOOL) popoverControllerShouldDismissPopover: (UIPopoverController *) popoverController {
    return self.canDismiss;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) dismissPopover {
	[s_popoverController dismissPopoverAnimated: YES];
	s_popoverController = nil;
    s_controller = nil;
}

#pragma mark - Actions

- (IBAction) signInPressed:(id)sender {
    if ([[UIDevice currentDevice] connectionType] != connection_none){
        [self dismissPopover];
        
        if ([MM_LoginViewController isLoggedIn])
            [g_appDelegate logout];
            
        else
            [g_appDelegate login];
    }
    else
        [SA_AlertView showAlertWithTitle: @"Please try again when the device has connectivity" message: @""];
}

#if APP_STORE_BUILD
///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) loadDemoContentPressed:(id)sender {
    [g_appDelegate loadDemoContent];
}
#endif

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) purgeAllContentItemFiles {
#if IF_CONTENT_DELETE_TESTING
	[SA_AlertView showAlertWithTitle: @"Purging All Content Items" message: @""];
#endif
	NSError					*error;
    NSString* privateDocumentsPath = [MMSF_Object privateDocumentsPath];
	NSArray					*allFileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: [MMSF_Object privateDocumentsPath]
                                                                                    error: &error];
	
	for (NSString *filename in allFileNames)
    {
		[[NSFileManager defaultManager] removeItemAtPath: [privateDocumentsPath stringByAppendingPathComponent: filename] error: &error];
	}
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) fullSynchronize:(UILongPressGestureRecognizer*) gr
{
    if (gr.state == UIGestureRecognizerStateBegan)
    {
        __weak typeof(self) weakSelf = self;
        
        SFAlertViewDismissBlock dismissBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                NSLog(@"Continue Sync");
                [weakSelf continueFullSyncrhonize];
            } else {
                [weakSelf dismissPopover];
            }
        };
        if ([[DSA_CellularDataDefender sharedInstance] willAlertAboutFullSyncWithDismissBlock:dismissBlock]) {
            return;
        }
        [self continueFullSyncrhonize];
    }
}

- (void)continueFullSyncrhonize
{
        if ([[UIDevice currentDevice] connectionType] != connection_none) {
			[[MM_SyncManager sharedManager] resyncAllDataIncludingMetadata: NO withCompletionBlock: nil];
//			[MM_SyncManager sharedManager].hasSyncedOnce = NO;
//            [self purgeAllContentItemFiles];
//            [[MM_ContextManager sharedManager] removeAllData];
//            
//            int64_t delayInSeconds = 1.0;
//            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//            dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//                [[MM_SyncManager sharedManager] fullResync:nil withCommpletionBlock: nil];
//
//            });
//            
            // Showing this now to avoid seeing usual screen with buttons before sync screen appears
            //!!!gmu handlePleaseWaitDisplayWithText seems totally gone
			//[[DSARestClient sharedInstance] handlePleaseWaitDisplayWithText: @"" andProgressBarValue: 0.0];
    //        [SA_PleaseWaitDisplay showPleaseWaitDisplayWithMajorText: @"Loading From Salesforce..." minorText:nil cancelLabel: nil showProgressBar: NO delegate: nil];

            [self dismissPopover];
            s_popoverController = nil;
        }
        else
        {
            [SA_AlertView showAlertWithTitle: @"Please try again when the device has Connectivity." message: @""];
        }
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) synchronizePressed:(id)sender {
    if ([[UIDevice currentDevice] connectionType] != connection_none) {
        [self dismissPopover];
        [[DSARestClient sharedInstance] deltaSync];
        s_popoverController = nil; 
    }
    else
        [SA_AlertView showAlertWithTitle: @"Please try again when the device has connectivity." message: @""];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) helpPressed:(id)sender {
	UINavigationController			*navController=nil;// = self.targetNavigationController;
	
	if (navController == nil)
        navController = g_appDelegate.topNavigationController;
	
    [navController pushViewController: [HY_HTMLHelpController controller] animated: YES];
	[self dismissPopover];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) reportProblemPressed:(id)sender {
    if (![MFMailComposeViewController canSendMail]) {
		[SA_AlertView showAlertWithTitle: @"No Mail Setup" message: @"Please setup a mail account first."];
		return;
	}
	MFMailComposeViewController						*controller = [[[MFMailComposeViewController alloc] init] autorelease];
	
	//[controller addAttachmentData: [NSData dataWithContentsOfFile: CONTEXT_PATH] mimeType: @"data/data" fileName: [CONTEXT_PATH lastPathComponent]];
	[controller setSubject: $S(@"Problem found in %@", [NSBundle visibleName])];
    
	@try {
		[controller setToRecipients: @[ [MMSF_MobileAppConfig__c activeMobileConfigInContext: nil][MNSS(@"Report_an_Issue__c")]]];
	} @catch (id e) {
		MMLog(@"%@", @"Couldn't access report-a-problem email address");
	}
	controller.mailComposeDelegate = self;
	
	[self presentViewController: controller animated: YES completion: nil];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) mailComposeController: (MFMailComposeViewController *) controller didFinishWithResult: (MFMailComposeResult) result error: (NSError *) error {
	[self dismissPopover];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) HTML5Pressed:(id)sender {
	UINavigationController			*navController=nil;// = self.targetNavigationController;
	
	if (navController == nil) navController = g_appDelegate.topNavigationController;
	
    [navController pushViewController: [HY_HTML5DemoController controller] animated: YES];
    
	[self dismissPopover];    
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) aboutPressed:(id)sender {
    isAboutPressed = YES;
    [self.navigationController pushViewController: [DSA_AboutPaneController controller] animated: YES];    
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (IBAction) selectPressed:(id)sender {
    [self dismissPopover];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_DisplayMobileConfigSelector object:self];
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (CGSize)contentSizeForViewInPopover {
    CGSize sz = CGSizeMake(self.view.bounds.size.width,[self menuHeight]+10);
    return sz;
}

- (CGSize)preferredContentSize {
    return CGSizeMake(self.view.bounds.size.width, [self menuHeight]);
}

#pragma mark Notifications

#if APP_STORE_BUILD
///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) demoModeChanged:(NSNotification*) notification {
    [g_appDelegate demoModeChanged];
    [self buildMenu];
    [table reloadData];
    
    CGRect frame = self.view.frame;
    frame.size = CGSizeMake(self.view.bounds.size.width, [self menuHeight]+44+10);
    self.view.frame = frame;
    self.contentSizeForViewInPopover = self.view.frame.size;
    [s_popoverController setPopoverContentSize:self.view.frame.size animated:YES];
    
    [self dismissPopover];
}
#endif

- (void)internalModeSwitchEngaged:(NSNotification *)aNotif {
    
    [g_appDelegate updateNavBarForInternalMode];
    
    [self dismissPopover];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    UIButton *buttonItem = (UIButton *)self.popoverItem;
    
            [DSA_SettingsMenuViewController popOverFromButton:buttonItem];
    

}


- (void)prepareCellsForDismissal {
    for (UITableViewCell * cell in self.table.visibleCells) {
        if([cell isKindOfClass:[DSA_SettingsMenuInternalModeCell class]]) {
            DSA_SettingsMenuInternalModeCell * internalCell = (DSA_SettingsMenuInternalModeCell*)cell;
            [internalCell prepareForDismissal];
            break;
        }
    }
}

- (void)orientationChanged:(NSNotification *)notification {

    NSAssert(self.popoverItem != nil, @"popoverItem can't be nil");

    if ([s_popoverController isPopoverVisible]) {
        
        [self prepareCellsForDismissal];
        
        if ([self.popoverItem isKindOfClass:[UIButton class]]) {

            [self dismissPopover];

            UIButton *buttonItem = (UIButton *)self.popoverItem;
            
            [DSA_SettingsMenuViewController popOverFromButton:buttonItem];
            
        } else if([self.popoverItem isKindOfClass:[UIBarButtonItem class]]) {

            [self dismissPopover];
            
            UIBarButtonItem *barButtonItem = (UIBarButtonItem *)self.popoverItem;

            [DSA_SettingsMenuViewController popOverFromBarButtonItem:barButtonItem];

        }
    }
}

@end
