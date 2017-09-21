//
//  DSA_ContentShelvesViewController.m
//  DSA
//
//  Created by Mike Close on 7/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelvesController.h"
#import "DSA_ContentShelvesModel.h"
#import "DSA_ContentShelvesContentItemCollectionViewCell.h"
#import "DSA_ContentShelfHeaderView.h"
#import "DSA_ContentShelvesConfig.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "DSA_CreateFavoriteShelfController.h"
#import "UIResponder+UIResponder_FirstResponderTracking.h"
#import "MMSF_ContentDocument.h"
#import "DSA_AppDelegate.h"
#import "DSA_BaseTabsViewController.h"
#import "Branding.h"
#import "MMSF_DSA_Playlist__c.h"

@interface DSA_ContentShelvesController ()

@property (strong, nonatomic) UICollectionView                              *collectionView;
@property (strong, nonatomic) LXReorderableCollectionViewFlowLayout         *collectionViewLayout;
@property (strong, nonatomic) DSA_ContentShelvesSupplementaryReusableView   *backgroundGradientView;
@property (strong, nonatomic) NSString                                      *state;
@property (strong, nonatomic) UIBarButtonItem                               *editButton;
@property (strong, nonatomic) UIBarButtonItem                               *doneButton;
@property (strong, nonatomic) UIBarButtonItem                               *createShelfButton;
@property (nonatomic)         CGFloat                                        keyboardOffset;
@property (strong, nonatomic) NSIndexPath                                   *dragItemDestinationIndexPath;
@property (strong, nonatomic) NSIndexPath                                   *dragItemSourceIndexPath;
@property (strong, nonatomic) NSMutableArray                                *layoutConstraints;
@property (strong, nonatomic) DSA_MediaDisplayViewController                *mediaDisplayVC;
@property (strong, nonatomic) DSA_ContentShelvesModel                       *bookshelvesModel;
@property (nonatomic)         BOOL                                           organizing;

@end

@implementation DSA_ContentShelvesController

+ (instancetype)controller {
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"contentShelfConfig" ofType:@"json"];
    DSA_ContentShelvesController *controller = [[DSA_ContentShelvesController alloc] initWithConfigPath:configPath];
    
    return controller;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observe {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceChanged:) name:kNotification_ContentShelfCreated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceChanged:) name:kNotification_ContentShelfDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceChanged:) name:kNotification_SyncComplete object:nil];
}

- (id)initWithConfigPath:(NSString *)path {
    // call designated initializer
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        DSA_ContentShelvesConfig *config = [[DSA_ContentShelvesConfig alloc] initWithConfigPath:path];
        if (config == nil) return nil;
        [self setConfig:config];
        [self.bookshelvesModel setConfig:[self config]];
        [self.bookshelvesModel setDelegate:self];
        
        self.title = self.config.navBarTitle;
        
        [self setEditButton:[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(editTouched:)]];
        [self setDoneButton:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneEditingTouched:)]];
        [self setCreateShelfButton:[[UIBarButtonItem alloc] initWithTitle:@"New Playlist" style:UIBarButtonItemStyleDone target:self action:@selector(newTouched:)]];
        
        NSArray *backgroundColors = [(DSA_ContentShelfConfig*)[[self config] defaultShelfConfig] sectionBackgroundColors];
        NSArray *backgroundColorLocations = [(DSA_ContentShelfConfig*)[[self config] defaultShelfConfig] sectionBackgroundColorLocations];
        [self setBackgroundGradientView:[[DSA_ContentShelvesSupplementaryReusableView alloc] init]];
        [[self backgroundGradientView] setContentMode:UIViewContentModeRedraw];
        [[self backgroundGradientView] setBackgroundColors:backgroundColors andLocations:backgroundColorLocations];
        
        [self observe];
    }
    
    return self;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - View Lifecycle
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize the custom UICollectionViewLayout - it's a subclass of UICollectionViewFlowLayout
    [self setCollectionViewLayout:[[LXReorderableCollectionViewFlowLayout alloc] init]];
    [[self collectionViewLayout] setMinimumInteritemSpacing:0];
    [[self collectionViewLayout] setMinimumLineSpacing:0];
    self.collectionView = [[UICollectionView alloc] initWithFrame:[self.view frame] collectionViewLayout:[self collectionViewLayout]];
    
    // configure the collection view
    self.collectionView.contentMode = UIViewContentModeRedraw;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    // accessibility for testing
    [self.collectionView setIsAccessibilityElement:YES];
    [self.collectionView setAccessibilityLabel:@"Playlists Collection View"];
    [self.collectionView setAccessibilityIdentifier:@"Playlists Collection View"];
    
    [self.view setIsAccessibilityElement:YES];
    [self.view setAccessibilityLabel:@"Playlists Controller View"];
    [self.view setAccessibilityIdentifier:@"Playlists Controller View"];

    [[self collectionView] registerClass:[DSA_ContentShelvesContentItemCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([DSA_ContentShelvesContentItemCollectionViewCell class])];
    [[self collectionView] registerClass:[DSA_ContentShelfHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([DSA_ContentShelfHeaderView class])];
    
    // configure the background
    self.view.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:[self backgroundGradientView] atIndex:0];
    [self.view addSubview:self.collectionView];
    
    // set up view constraints
    [self createConstraints];
    
    // set up the insets for the tab bar
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 50, 0);
    [self.collectionView setContentInset:insets];
    [self.collectionView setScrollIndicatorInsets:insets];
    
    self.navigationController.navigationBar.barTintColor = [Branding staplesHeaderColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.organizing = NO;
}

- (void)createConstraints {
    // Reset constraints if they exist.
    if ([self layoutConstraints] != nil) {
        if ([[self layoutConstraints] count] > 0) [self.view removeConstraints:[self layoutConstraints]];
        [[self layoutConstraints] removeAllObjects];
    }
    else {
        [self setLayoutConstraints:[NSMutableArray array]];
    }
    
    // Background View Constraints
    [[self backgroundGradientView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    id gradientXConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    id gradientYConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    id gradientWidthConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    id gradientHeightConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [self.view addConstraints:@[gradientXConstraint,gradientYConstraint,gradientWidthConstraint,gradientHeightConstraint]];
    [[self layoutConstraints] addObjectsFromArray:@[gradientXConstraint,gradientYConstraint,gradientWidthConstraint,gradientHeightConstraint]];
    
    // Collection View Constraints
    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    id collectionViewXConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    id collectionViewYConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    id collectionViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    id collectionViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.collectionView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
    [self.view addConstraints:@[collectionViewXConstraint,collectionViewYConstraint,collectionViewWidthConstraint,collectionViewHeightConstraint]];
    [[self layoutConstraints] addObjectsFromArray:@[collectionViewXConstraint,collectionViewYConstraint,collectionViewWidthConstraint,collectionViewHeightConstraint]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // set up the personal library
    NSMutableArray *shelfItems = [NSMutableArray array];
    NSArray *contentVersions = [MMSF_ContentVersion personalLibraryContentVersions];
    BOOL inInternalMode = g_appDelegate.inInternalMode;
    [contentVersions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MMSF_ContentVersion *cv = (MMSF_ContentVersion*)obj;
        if (inInternalMode || (!inInternalMode && [cv[MNSS(@"Internal_Document__c")] boolValue] != YES))
        {
            [shelfItems addObject:cv.Id];
        }
    }];
    [self.bookshelvesModel setItems:shelfItems forSpecialShelf:kContentShelfConfiguration_PersonalLibrary];
    
    [self reloadData];
    
    self.organizing = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // when the controller is being hidden, we want to reset the state to normal
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ContentShelvesStateChanged object:self userInfo:@{@"state": kContentShelvesStateNormal}];
    // when the controller is being hidden, we want to reset the state to normal
    self.organizing = NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self reloadData];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (UIRectEdge)edgesForExtendedLayout {
    return UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DataSource Management
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (DSA_ContentShelvesModel*)bookshelvesModel {
    return [DSA_ContentShelvesModel sharedModel];
}

- (void)reloadData {
    [self.collectionView reloadData];
    [self.collectionViewLayout invalidateLayout];
}

- (void)dataSourceChanged:(NSNotification *)note {
    [self reloadData];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DSAContentShelvesModelDelegate Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)insertSections:(NSIndexSet *)sections {
    [self.collectionView insertSections:sections];
}

- (BOOL)insertItemsAtIndexPaths:(NSArray *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
    }
    
    return YES;
}

- (BOOL)deleteItemsAtIndexPaths:(NSArray *)indexPaths {
    __weak typeof(self) weakSelf = self;

    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        for (NSIndexPath *indexPath in indexPaths)
        {
            [[strongSelf collectionView] deleteItemsAtIndexPaths:@[indexPath]];
        }
    } completion:^(BOOL finished) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.collectionViewLayout invalidateLayout];
    }];

    return YES;
}

- (NSArray *)itemIdsForSpecialShelf:(NSString *)configurationId {
    NSMutableArray *shelfItems = nil;
    if ([configurationId isEqualToString:kContentShelfConfiguration_PersonalLibrary]) {
        // TODO:    Return the array of itemIds for the Personal Library shelf.
        //          If you don't have the Personal Library items yet, you can set them directly by calling:
        //          [self.bookshelvesModel setItems:items forSpecialShelf:kContentShelfConfiguration_PersonalLibrary];
        //          where "items" is an array of MMSF_ContentVersion ids.
        //        shelfItems = @[];
        NSArray *contentVersions = [MMSF_ContentVersion personalLibraryContentVersions];
        [contentVersions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            MMSF_ContentVersion *cv = (MMSF_ContentVersion*)obj;
            [shelfItems addObject:cv.Id];
        }];
    }
    
    return shelfItems;
}

#pragma mark - Organizing

- (void)setOrganizing:(BOOL)organizing {
    _organizing = organizing;
    
    // disable the tab bar while editing
    [g_appDelegate.baseViewController enableTabBar:!organizing];

    if(organizing) {
        [DSA_ContentShelvesModel sharedModel].state = kContentShelvesStateEdit;
        self.navigationItem.leftBarButtonItem = [self doneButton];
        self.navigationItem.rightBarButtonItem = [self createShelfButton];
        [self.collectionViewLayout enableGestureRecognizers];
    } else {
        [DSA_ContentShelvesModel sharedModel].state = kContentShelvesStateNormal;
        self.navigationItem.leftBarButtonItem = [self editButton];
        self.navigationItem.rightBarButtonItem = nil;
        [self.collectionViewLayout disableGestureRecognizers];
    }
}

#pragma mark - Actions

- (IBAction)editTouched:(id)sender {
    self.organizing = YES;
}

- (IBAction)newTouched:(id)sender {
    [DSA_CreateFavoriteShelfController showFromBarButtonItem:[self createShelfButton] withItemToAdd:nil];
}

- (IBAction)doneEditingTouched:(id)sender {
    self.organizing = NO;
    [self.bookshelvesModel synchronizePlaylistsAndShelves];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewDataSource protocol Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DSA_ContentShelvesContentItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([DSA_ContentShelvesContentItemCollectionViewCell class]) forIndexPath:indexPath];
    
    [cell setContentMode:UIViewContentModeRedraw];
    
    DSA_ContentShelfModel *shelf = [self.bookshelvesModel shelfAtIndex:indexPath.section];
    [shelf setShelfIndex:indexPath.section];
    
    NSString *itemId = [shelf itemAtIndex:indexPath.row];
    [cell setShelfModel:shelf];
    [cell setItemId:itemId];
    cell.selected = NO;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item != 0) {
        return nil;
    }
    
    DSA_ContentShelvesSupplementaryReusableView *view = (DSA_ContentShelfHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                                         withReuseIdentifier:NSStringFromClass([DSA_ContentShelfHeaderView class])
                                                                                                                                forIndexPath:indexPath];;
    
    if (view == nil) return nil;
    
    [view setContentMode:UIViewContentModeRedraw];
    
    DSA_ContentShelfModel *shelfModel = [self.bookshelvesModel shelfAtIndex:indexPath.section];
    [view setShelfModel:shelfModel];
    
    return view;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.bookshelvesModel shelfCount];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    DSA_ContentShelfModel *shelf = [self.bookshelvesModel shelfAtIndex:section];
    return [shelf itemCount];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewDelegate Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // we don't want to show content during accidental taps while editing.
    if(self.organizing) return;
    
    DSA_ContentShelfModel *shelf = [self.bookshelvesModel shelfAtIndex:indexPath.section];
    NSUInteger count = [shelf itemCount];
    
    MMSF_ContentVersion *contentItem = [self.bookshelvesModel contentItemAtIndexPath:indexPath];
    if (contentItem) {
        DSA_MediaDisplayViewController *mdc = [DSA_MediaDisplayViewController controllerWithContentItem:contentItem IndexPath:indexPath totalItems:count withDeledate:self];
        __weak typeof(self) weakSelf = self;
        [self presentViewController:mdc animated:YES completion:^{
            typeof(self) strongSelf = weakSelf;
            strongSelf.mediaDisplayVC = mdc;
        }];
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    DSA_ContentShelfModel *shelf = [self.bookshelvesModel shelfAtIndex:section];
    if (shelf.itemCount)
    {
        return UIEdgeInsetsZero;
    }
    else
    {
        DSA_ContentShelfConfig *sectionConfig = [[self config] shelfConfigForSection:section];
        return UIEdgeInsetsMake(sectionConfig.cellCGSize.height, 0.f, 0.f, 0.f);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DSA_MediaDisplayViewControllerDelegate Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)donePressed:(DSA_MediaDisplayViewController *)controller {
    __weak typeof(self) weakSelf = self;
    [[self mediaDisplayVC] dismissViewControllerAnimated:YES completion:^{
        [weakSelf setMediaDisplayVC:nil];
    }];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewDelegateFlowLayout Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    DSA_ContentShelfConfig *sectionConfig = [[self config] shelfConfigForSection:section];
    
    return CGSizeMake(self.view.bounds.size.width, [sectionConfig headerHeight]);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    DSA_ContentShelfConfig *sectionConfig = [[self config] shelfConfigForSection:indexPath.section];
    return sectionConfig.cellCGSize;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LXReorderableCollectionViewDataSource Methods - Drag & Drop Rules Enforcement
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
//    MMLog(@"Can Move - There are %d items in the destination shelf.", [[self.bookshelvesModel shelfAtIndex:toIndexPath.section] itemCount]);
    NSString *itemId = [self.bookshelvesModel itemAtIndexPath:fromIndexPath];
    if (itemId == nil)
    {
        MMLog(@"Can't move. Is the fromIndexPath (%d, %d) valid?", fromIndexPath.section, fromIndexPath.row);
        return NO;
    }
    
    return [self.bookshelvesModel canMoveItem:itemId fromIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    NSString *itemId = [self.bookshelvesModel itemAtIndexPath:fromIndexPath];
    [self.bookshelvesModel moveItem:itemId fromIndexPath:fromIndexPath toIndexPath:toIndexPath updateLayout:NO animated:NO];
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canCopyToIndexPath:(NSIndexPath *)toIndexPath {
    NSString *itemId = [self.bookshelvesModel itemAtIndexPath:fromIndexPath];
    return [self.bookshelvesModel canInsertItem:itemId atIndexPath:toIndexPath];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willCopyToIndexPath:(NSIndexPath *)toIndexPath {
    NSString *itemId = [self.bookshelvesModel itemAtIndexPath:fromIndexPath];
    [self.bookshelvesModel insertItem:itemId atIndexPath:toIndexPath updateLayout:NO animated:NO];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canRemoveItemAtIndexPath:(NSIndexPath *)fromIndexPath
{
    return [self.bookshelvesModel canDeleteItemAtIndexPath:fromIndexPath];
}

- (void)collectionView:(UICollectionView *)collectionView willRemoveItemAtIndexPath:(NSIndexPath *)fromIndexPath
{
    [self.bookshelvesModel deleteItemAtIndexPath:fromIndexPath updateLayout:NO animated:NO];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LXReorderableCollectionViewDelegateFlowLayout Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [self setDragItemDestinationIndexPath:toIndexPath];
    [self setDragItemSourceIndexPath:fromIndexPath];
    
    DSA_ContentShelfModel *sourceShelf = [self.bookshelvesModel shelfAtIndex:[self dragItemSourceIndexPath].section];
    DSA_ContentShelfModel *destinationShelf = [self.bookshelvesModel shelfAtIndex:[self dragItemDestinationIndexPath].section];
    
    if (destinationShelf == sourceShelf) {
        [[self collectionViewLayout] finalizeMoveToIndex:toIndexPath];
        // reorder the junctions for the shelf we've moved within.
//        [destinationShelf orderJunctions];
        return;
    }
    
    if ([[sourceShelf shelfConfig] canRemoveContent] && [sourceShelf canModifyShelf]) {
        [self showCopyOrMoveAlert];
    }
    else {
        [self showCopyOnlyAlert];
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout itemAtIndexCanBeManipulated:(NSIndexPath *)indexPath
{
    DSA_ContentShelfModel *shelf = [self.bookshelvesModel shelfAtIndex:indexPath.section];
    MMSF_DSA_Playlist__c* playlist = [MMSF_DSA_Playlist__c playlistBySalesforceId:shelf.playlistId];
    NSNumber* n = [playlist valueForKey:MNSS(@"IsFeatured__c")];
    return !n.boolValue;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sectionAtIndexCanBeChanged:(NSUInteger)sectionIndex
{
    DSA_ContentShelfModel *shelf = [self.bookshelvesModel shelfAtIndex:sectionIndex];
//    MMSF_DSA_Playlist__c* playlist = [MMSF_DSA_Playlist__c playlistBySalesforceId:shelf.playlistId];
//    NSNumber* n = [playlist valueForKey:MNSS(@"IsFeatured__c")];
    return [shelf canModifyShelf];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Adjustments For Keyboard
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)keyboardWillShow:(NSNotification *)note {
    UITextField *textField = [UIResponder currentFirstResponder];
    if (textField == nil) return;
    
    CGPoint textFieldInControllerView = [textField.superview convertPoint:textField.frame.origin toView:self.view];
    CGRect	rawKeyboardFrame = [[[note userInfo] objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect	keyboardFrame = [self.view convertRect:rawKeyboardFrame fromView:nil];
    self.keyboardOffset = textFieldInControllerView.y - (keyboardFrame.origin.y - 20);
    
    if (self.keyboardOffset < 0) {
        self.keyboardOffset = 0;
        return;
    }
    
    CGFloat	duration = [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve) [[note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut;
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
        default:
            break;
    }
    
    CGFloat collectionViewOffset = self.collectionView.contentOffset.y;
    CGPoint newCollectionViewOffset = CGPointMake(0, collectionViewOffset + self.keyboardOffset);
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations: ^{
        self.collectionView.contentOffset = newCollectionViewOffset;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    CGFloat collectionViewOffset = self.collectionView.contentOffset.y;
    CGPoint newCollectionViewOffset = CGPointMake(0, collectionViewOffset - self.keyboardOffset);
    
    CGFloat	duration = [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    UIViewAnimationCurve curve = (UIViewAnimationCurve) [[note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseInOut;
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
        default:
            break;
    }
	
    [UIView animateWithDuration:duration delay:0.0 options:options animations: ^{
        self.collectionView.contentOffset = newCollectionViewOffset;
    } completion:^(BOOL finished) {
        
    }];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Alert Management
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)showCopyOrMoveAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please Confirm" message:@"Would you like to move or copy the file to this shelf?" delegate:self cancelButtonTitle:@"Move" otherButtonTitles:@"Copy", nil];
    [alertView setTag:kContentShelvesCopyOrMoveAlertTag];
    [alertView show];
}

- (void)showCopyOnlyAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please Confirm" message:@"Would you like to copy the file to this shelf?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Copy", nil];
    [alertView setTag:kContentShelvesCopyOnlyAlertTag];
    [alertView show];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIAlertViewDelegate And Related Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch ([alertView tag]) {
        case kContentShelvesCopyOrMoveAlertTag:
            [self handleCopyOrMoveWithButtonIndex:buttonIndex];
            break;
        case kContentShelvesCopyOnlyAlertTag:
            [self handleCopyOnlyWithButtonIndex:buttonIndex];
            break;
        default:
            break;
    }
}

- (void)handleCopyOrMoveWithButtonIndex:(NSUInteger)buttonIndex {
    switch (buttonIndex) {
        case kContentShelvesMoveButtonIndex:
            [self.bookshelvesModel deleteItemAtIndexPath:[self dragItemSourceIndexPath] updateLayout:NO animated:NO];
            [[self collectionViewLayout] finalizeMoveToIndex:[self dragItemDestinationIndexPath]];
            break;
            
        case kContentShelvesConfirmButtonIndex:
            [[self collectionViewLayout] finalizeCopyToIndex:[self dragItemDestinationIndexPath]];
            break;
            
        default:
            break;
    }
}

- (void)handleCopyOnlyWithButtonIndex:(NSUInteger)buttonIndex {
    switch (buttonIndex) {
        case kContentShelvesCancelButtonIndex:
            [self.bookshelvesModel deleteItemAtIndexPath:[self dragItemDestinationIndexPath] updateLayout:NO animated:NO];
            [[self collectionViewLayout] cancelMoveToIndex:[self dragItemSourceIndexPath]];
            break;
            
        case kContentShelvesConfirmButtonIndex:
            [[self collectionViewLayout] finalizeCopyToIndex:[self dragItemDestinationIndexPath]];
            break;
            
        default:
            break;
    }
}

// this code should ideally live in the model, but 

NSUInteger const kContentShelvesMoveButtonIndex = 0;
NSUInteger const kContentShelvesConfirmButtonIndex = 1;
NSUInteger const kContentShelvesCancelButtonIndex = 0;
NSUInteger const kContentShelvesCopyOrMoveAlertTag = 0;
NSUInteger const kContentShelvesCopyOnlyAlertTag = 1;

@end
