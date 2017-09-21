//
//  DSA_PreviewViewController.m
//  DSA
//
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_PreviewViewController.h"
#import "DSA_AddFavoriteViewController.h"
#import "MMSF_ContentVersion.h"
#import "MMSF_Contact.h"
#import "DocumentTracker.h"
#import "DSA_AppDelegate.h"

@interface DSA_PreviewViewController ()

@property (nonatomic, strong) UINavigationBar *previewNavBar;
@property (nonatomic, strong) UIPopoverController *favoritesPopover;

@end

@implementation DSA_PreviewViewController

#pragma mark - init

- (instancetype)initWithItem:(MMSF_ContentVersion *)item {
    if (self = [super init]) {
        _item = item;
    }
    
    return self;
}

#pragma mark - lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.previewNavBar = [[UINavigationBar alloc] initWithFrame:[self navigationBarFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]]];
    self.previewNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.previewNavBar];
    
    // Now initialize the custom navigation bar with required items
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:self.item.Title];
    UIBarButtonItem *doneButton  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    item.leftBarButtonItem = doneButton;
    item.hidesBackButton = YES;
    
    [self.previewNavBar pushNavigationItem:item animated:NO];
    [self setupToolbar];
}

- (void) setupToolbar
{
    NSMutableArray *barButtonItems = [NSMutableArray array];
    UIBarButtonItem			*buttonItem = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail"] target: self action: @selector(sendAsEmail:)];
    
    if ([self.item isProtectedContent]) {
        buttonItem = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail_forbidden"] target: self action: @selector(sendAsEmail:)];
        buttonItem.enabled = NO;
    } else if ([g_appDelegate.documentTracker documentMarkedToSendAsEmail: self.item.Id]) {
        buttonItem = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail_marked"] target: self action: @selector(clearSendAsEmail:)];
    }
    [barButtonItems addObject:buttonItem];
    [barButtonItems addObject:[UIBarButtonItem spacerOfWidth:20]];
    
    UIBarButtonItem *favButton = [UIBarButtonItem itemWithImage: [UIImage imageNamed: @"star.png"] target:self action:@selector(favoritesPressed:)];
    
    [barButtonItems addObject:favButton];
    
    self.previewNavBar.topItem.rightBarButtonItems = barButtonItems;
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStartViewingNotification object:self.item.Id];
    [[NSNotificationCenter defaultCenter] postNotificationName:ContentItemHistoryItemViewedNotification object:self.item.Id];
}

- (CGRect)navigationBarFrameForOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat navBarHeight;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if(UIInterfaceOrientationIsLandscape(orientation)) {
            navBarHeight = 52.0;
        } else {
            navBarHeight = 64.0;
        }
    } else {
        navBarHeight = 64.0;
    }
    return CGRectMake(0.0, 0.0, self.view.bounds.size.width, navBarHeight);
}

#pragma mark - Actions

- (void) done {
    [self.favoritesPopover dismissPopoverAnimated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName: DocumentTrackerStopViewingNotification object: self.item];
    [self dismissViewControllerAnimated: YES completion: nil];
}


- (void) sendAsEmail: (id) sender {
    if (![MFMailComposeViewController canSendMail]) {
        [SA_AlertView showAlertWithTitle: @"Please set up your Mail account on this iPad before attempting to mail a document." message: @""];
        return;
    }
    
    if (g_appDelegate.isTrackingDocuments && g_appDelegate.currentTrackingEntity != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerMarkToSendNotification object:[self.item Id]];    //To Fix; Defect ID:2621552
        [self setupToolbar];
    } else {
        if ((g_appDelegate.currentTrackingType == DocumentTracking_None) ||
            (g_appDelegate.currentTrackingType == DocumentTracking_AlwaysOn)) {
            
            id matchedEntity = [self.item.moc anyObjectOfType: [MMSF_Contact entityName] matchingPredicate:nil];
            
            BOOL useSFDCContacts = CONTACTS_AVAILABLE && (matchedEntity != nil);
            
            if (useSFDCContacts)  {
                
                DSA_ContactSelectionController *vc = [DSA_ContactSelectionController controllerToMailContentItem:self.item];
                
                vc.contactSelectionDelegate = self;
                
                [self presentViewController:vc animated:YES completion:nil];
                
            } else {
                
                // To fix Bug no 2593773
                MFMailComposeViewController *controller = [self.item controllerForMailingTo:nil];
                
                [self presentViewController:controller animated:YES completion:nil];
            }
            
        } else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerMarkToSendNotification
                                                                object:[self.item Id]];
            [self setupToolbar];
        }
    }
}
- (void) clearSendAsEmail: (id) sender
{
    if (g_appDelegate.isTrackingDocuments && g_appDelegate.currentTrackingEntity != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerClearMarkToSendNotification object:[self.item Id]];   ////To Fix ; Defect ID:2621552
        [self setupToolbar];
    }
}

- (IBAction) favoritesPressed:(id)sender {
    
    if (self.favoritesPopover != nil) {
        [self.favoritesPopover dismissPopoverAnimated:YES];
        self.favoritesPopover = nil;
    } else {
        DSA_AddFavoriteViewController *controller = [[[DSA_AddFavoriteViewController alloc] initWithNibName:@"DSA_AddFavoriteViewController" bundle:nil] autorelease];
        controller.delegate = self;
        controller.item = self.item;
        self.favoritesPopover = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
        [self.favoritesPopover setPopoverContentSize:CGSizeMake(372, 650)];
        [self.favoritesPopover setDelegate:self];
        [self.favoritesPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [self.favoritesPopover setPassthroughViews:nil];
    }
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.item;
}

#pragma mark - DSA_ContactSelectionControllerDelegate

- (void) contactSelectionControllerSendPressed: (DSA_ContactSelectionController*) contactSelectionController
{
    NSMutableArray	*addresses = [NSMutableArray array];
    NSMutableArray	*contactIDs = [NSMutableArray array];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: kDefaultsKey_DemoMode])
    {
        [addresses addObject: contactSelectionController.demoEmailAddress];
    }
    else
    {
        NSArray* mailTargets = contactSelectionController.selectedContacts;
        for (MMSF_Contact *contact in mailTargets)
        {
            [addresses addObject: contact.Email ?: @""];
            if (contact.Id) [contactIDs addObject: contact.Id];
        }
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    // To fix Bug no 2593773
    MFMailComposeViewController *controller = [self.item controllerForMailingTo: addresses];
    
    controller.SA_CompletionBlock = ^(MFMailComposeResult result) {
        if (result != MFMailComposeResultCancelled)
        {
         //!!!gmu   [g_appDelegate.documentTracker addMailedToContactIDs: contactIDs forDocumentID: self.item.Id];
        }
        
    };
    if (controller) {
        [self presentViewController:controller animated:YES completion:nil];
    }
}

- (void) contactSelectionControllerCancelPressed: (DSA_ContactSelectionController*) contactSelectionController;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end