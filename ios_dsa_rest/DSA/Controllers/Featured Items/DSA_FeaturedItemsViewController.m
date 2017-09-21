//
//  DSA_FeaturedItemsViewController.m
//  DSA
//
//  Created by Mike McKinley on 3/14/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_FeaturedItemsViewController.h"
#import "MMSF_ContentVersion.h"
#import "UIColor+DSA.h"
#import "DSA_AppDelegate.h"
#import "Branding.h"

static NSString * const DSA_SpotlightItemTableCell  = @"DSA_SpotlightItemTableCell";
static NSString * const DSA_SpotlightHeaderCell     = @"DSA_SpotlightHeaderCell";

static NSString * const DSA_HeaderTitle_Featured    = @"FEATURED";
static NSString * const DSA_HeaderTitle_Updated     = @"NEW & UPDATED CONTENT";
static NSString * const DSA_MenuTitle_All           = @"All";
static NSString * const DSA_MenuTitle_Featured      = @"Featured";
static NSString * const DSA_MenuTitle_Updated       = @"New & Updated";


//  uncomment one method
//  #define DSA_FeaturedContentMethod_None                  0     // not supported
#define DSA_FeaturedContentMethod_FeaturedContentBoost  1     // checkbox
//  #define DSA_FeaturedContentMethod_Tag                   2     // tags
//  #define DSA_FeaturedContentMethod_ContentWorkspaceDoc   3       // Library defined in sync_objects.plist

#ifdef DSA_FeaturedContentMethod_Tag
// this tag determines which Content displays under Featured
static NSString * const DSA_FeaturedContentTag      = @"HK_Feature";
#endif

typedef NS_ENUM(NSInteger, DSA_ViewOptions) {
    DSA_ViewOptionsAll,
    DSA_ViewOptionsFeatured,
    DSA_ViewOptionsUpdated
};

@interface DSA_FeaturedItemsViewController ()
@property (assign, nonatomic) DSA_ViewOptions selectedViewOption;
@property (strong, nonatomic) NSDateFormatter *relativeDateFormatter;

- (void)reset;
- (void)loadData;
@end

@implementation DSA_FeaturedItemsViewController

- (void)adjustColors {
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [Branding staplesHeaderColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)observe {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(reset) name:kNotification_MobileAppConfigurtionChanged object:nil];
    [center addObserver:self selector:@selector(syncCompleted:) name:kNotification_SyncComplete object:nil];
    [center addObserver:self selector:@selector(didLogOut:) name:kNotification_DidLogOut object:nil];
    [center addObserver:self selector:@selector(internalModeChanged:) name:kDSAInternalModeNotificationKey object:nil];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    
    [self adjustColors];
    [self observe];
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Spotlight" image:[UIImage imageNamed:@"spotlight-tab.png"] tag: 0];
    self.selectedViewOption = DSA_ViewOptionsAll;
    
    self.relativeDateFormatter = [[NSDateFormatter alloc] init];
    [self.relativeDateFormatter setDoesRelativeDateFormatting:YES];
    [self.relativeDateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [self.relativeDateFormatter setDateStyle:NSDateFormatterMediumStyle];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSPredicate*)featuredContentPredicate {
    NSPredicate *predicate = nil;
    
#if defined(DSA_FeaturedContentMethod_FeaturedContentBoost)
    predicate = [NSPredicate predicateWithFormat: @"(FeaturedContentBoost >= %@)", @(1)];
#elif defined(DSA_FeaturedContentMethod_Tag)
    predicate = [NSPredicate predicateWithFormat:@"(TagCsv CONTAINS[cd] %@)", DSA_FeaturedContentTag];
#elif defined(DSA_FeaturedContentMethod_ContentWorkspaceDoc)
    NSArray * featuredIdArray = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultKey_featuredContentItems];
    if (featuredIdArray.count) {
        predicate = [NSPredicate predicateWithFormat:@"Id IN %@", featuredIdArray];
    }
#else
#warning "Featured Content Method is not defined"
#endif
    
    return  predicate;
}

- (void) loadData {
    
    // load Featured items
    MM_ManagedObjectContext	*moc = [MM_ContextManager sharedManager].threadContentContext;
    NSPredicate *featuredPredicate = [self featuredContentPredicate];
    NSArray * featured = nil;
    NSArray * updated = nil;
    if (featuredPredicate) {
        featured = [moc allObjectsOfType:@"ContentVersion" matchingPredicate:featuredPredicate];
    }
    
    // load Updated items
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *contentSyncDate = [defaults valueForKey:kUserDefaultKey_previousContentSyncDate];

    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"LastModifiedDate" ascending:NO];
    NSPredicate *updatedPredicate = [NSPredicate predicateWithFormat:@"LastModifiedDate >= %@", contentSyncDate];
    updated = [moc allObjectsOfType:@"ContentVersion" matchingPredicate:updatedPredicate sortedBy:@[dateSort]];
	
	NSMutableArray		*filteredUpdated = [NSMutableArray new];
	for (MMSF_ContentVersion *content in updated) {
		if (content.categoryLocationPath.length > 0) [filteredUpdated addObject: content];
	}
	updated = filteredUpdated;
    
    // filter if internal mode
    BOOL internalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
    if (!internalMode) {
        NSPredicate * internalPred = [NSPredicate predicateWithFormat:@"%K = %d", MNSS(@"Internal_Document__c"),0];
        self.featuredContentArray = [featured filteredArrayUsingPredicate:internalPred];
        self.updatedContentArray = [updated filteredArrayUsingPredicate:internalPred];
    } else {
        self.featuredContentArray = featured;
        self.updatedContentArray = updated;
    }
}

- (void) reset {
    BOOL syncInProgress = [MM_SyncStatus status].isSyncInProgress;
    if (!syncInProgress) {
        self.selectedViewOption = DSA_ViewOptionsAll;
        [self loadData];
        [self.spotlightTableView reloadData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.spotlightTableView.accessibilityLabel = NSLocalizedString(@"Features Products Table", nil);
	
    [self adjustColors];
    
    [self.spotlightTableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:DSA_SpotlightHeaderCell];
    
    [self loadData];
    
    UIBarButtonItem *viewBarButton = [[UIBarButtonItem alloc] initWithTitle:@"VIEW" style:UIBarButtonItemStyleBordered target:self action:@selector(viewButtonTouched:)];
    
    //adding accessibility
    [viewBarButton setAccessibilityLabel:@"VIEW"];
    [viewBarButton isAccessibilityElement];
    self.spotlightTableView.accessibilityIdentifier = @"Features Products Table";
    self.spotlightTableView.isAccessibilityElement = YES;
    
    self.navigationItem.leftBarButtonItem = viewBarButton;
    self.view.accessibilityLabel = @"Spotlight Controller View";
    self.view.accessibilityIdentifier = @"Spotlight Controller View";
    self.view.isAccessibilityElement = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.tabBarItem.badgeValue = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSArray*)dataSourceArrayForSection:(NSInteger)section {
    NSArray *dataArray;
    
    switch (self.selectedViewOption) {
        case DSA_ViewOptionsAll:
            if (section == 0) { dataArray = self.featuredContentArray; }
            else { dataArray = self.updatedContentArray; }
            break;
            
        case DSA_ViewOptionsFeatured:
            dataArray = self.featuredContentArray;
            break;
            
        case DSA_ViewOptionsUpdated:
            dataArray = self.updatedContentArray;
            break;
    }
    
    return dataArray;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionCount = 1;
    if (self.selectedViewOption == DSA_ViewOptionsAll) sectionCount = 2;
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *dataSourceArray = [self dataSourceArrayForSection:section];
    return dataSourceArray.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DSA_SpotlightItemTableCell];
    NSArray *dataSourceArray = [self dataSourceArrayForSection:indexPath.section];
    MMSF_ContentVersion *content = dataSourceArray[indexPath.row];
    NSString *contentLocation = [content categoryLocationPath];
    
    UIImageView *cellImageView = (UIImageView*)[cell viewWithTag:201];
    
    CGSize thumbSize = CGSizeMake(40.f, 40.f);
	cell.tag = content.objectIDString.hash;
	
    [content generateThumbnailSize:thumbSize completionBlock:^(UIImage *image) {
		if (cell.tag == content.objectIDString.hash)  cellImageView.image = image;
    }];
    cellImageView.image = content.tableCellImage;
    
    UILabel *cellTitleLabel = (UILabel*)[cell viewWithTag:202];
    cellTitleLabel.text = content[@"Title"];
    UILabel *cellDescriptionLabel = (UILabel*)[cell viewWithTag:203];
    cellDescriptionLabel.text = content[@"Description"];
    UILabel *cellLocationLabel = (UILabel*)[cell viewWithTag:204];
    cellLocationLabel.text = contentLocation;
    UILabel *cellDateLabel = (UILabel*)[cell viewWithTag:205];
    NSDate *modifiedDate = content[@"LastModifiedDate"];
    cellDateLabel.text = [self.relativeDateFormatter stringFromDate:modifiedDate];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:DSA_SpotlightHeaderCell];
    
    sectionHeaderView.contentView.backgroundColor = [UIColor colorWithRed:179.0/255.0 green:179.0/255.0 blue:179.0/255.0 alpha:1.0];
    sectionHeaderView.textLabel.textColor = [UIColor whiteColor];
    sectionHeaderView.tintColor = [UIColor orangeColor];
//    sectionHeaderView.textLabel.text = @"blah";
    return sectionHeaderView;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleString = @"";
    if (section == 0) {
        titleString = DSA_HeaderTitle_Featured;
        if (self.selectedViewOption == DSA_ViewOptionsUpdated) {
            titleString = DSA_HeaderTitle_Updated;
        }
    } else if (section == 1) {
        titleString = DSA_HeaderTitle_Updated;
    }
    
    return titleString;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor whiteColor];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *dataSourceArray = [self dataSourceArrayForSection:indexPath.section];
    MMSF_ContentVersion *content = dataSourceArray[indexPath.row];
    DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controllerForItem:content withDelegate:self];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - DSA_MediaDisplayViewControllerDelegate

- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewController

- (NSString *)title {
    return @"Spotlight";
}

#pragma mark - Notifications

- (void)internalModeChanged:(NSNotification *)note {
    [self reset];
}

- (void)syncCompleted:(NSNotification*)notification {
    // the tab bar is not a UITabBar so badging isn't free...
    //self.tabBarItem.badgeValue = @(self.updatedContentArray.count).stringValue;
    
    [self reset];
    
   /* 
    // post an alert for now
    NSString *messageString = [NSString stringWithFormat:@"Synchronization completed with %d items updated.", self.updatedContentArray.count];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Synchronization Completed" message:messageString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    */
}

- (void)didLogOut:(NSNotification*)notification {
    // avoid displaying content immediately post log out
    self.featuredContentArray = nil;
    self.updatedContentArray = nil;
    [self.spotlightTableView reloadData];
}

#pragma mark - Actions

- (IBAction)viewButtonTouched:(id)sender {
    if (!self.presentingViewMenu) {
         NSMutableArray *titleArray = @[DSA_MenuTitle_All, DSA_MenuTitle_Featured, DSA_MenuTitle_Updated].mutableCopy;
        titleArray[self.selectedViewOption] = [NSString stringWithFormat:@"\u2713 %@", titleArray[self.selectedViewOption]];

        UIActionSheet *viewActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"" destructiveButtonTitle:nil otherButtonTitles:titleArray[0], titleArray[1], titleArray[2], nil];
        [viewActionSheet showFromBarButtonItem:sender animated:YES];
        self.presentingViewMenu = YES;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        self.selectedViewOption = buttonIndex;
        [self.spotlightTableView reloadData];
    }
    self.presentingViewMenu = NO;
}

@end
