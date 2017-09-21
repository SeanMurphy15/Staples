//
//  ZM_MediaDisplayController.m
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_MediaDisplayViewController.h"

#import "DocumentTracker.h"
#import "DSA_AppDelegate.h"
#import "ContentItemHistory.h"
#import "ContentItemHistoryController.h"
#import "SSZipArchive.h"
#import "MM_ContextManager.h"
#import "DSA_ContentShelvesModel.h"
#import "MMSF_ContentDocument.h"
#import "MMSF_Contact.h"
#import "MMSF_Lead.h"
#import "DSA_PreviewViewController.h"
#import "DSA_AddFavoriteViewController.h"
#import "EmailSubjectController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>

#if SHOPPING_CART_SUPPORT
#import "SF_ContentItem (ShoppingCart).h"
#endif

@interface DSA_MediaDisplayViewController () <EmailSubjectControllerDelegate>

@property (nonatomic, strong) UIPopoverController* postPopover;
@property (nonatomic, unsafe_unretained) UIBarButtonItem* chatterButton;  //???
@property (nonatomic, strong) NSIndexPath* currentItemIndexPath; // current iten indexpath when clicked from favorites shelf
@property (nonatomic, readwrite) NSUInteger totalNumberOfItems; // total number of items in shelf
@property (nonatomic, strong) UIPopoverController *favoritesPopover;
@property (nonatomic, strong) NSArray *toAddresses;

@end

@implementation DSA_MediaDisplayViewController

BOOL unzipped = FALSE;

- (void)observe {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteringForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(contentItemSelected:) name: kNotification_ContentItemSelected object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(historyItemSelected:) name: kContentItemHistoryItemSelectedNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(userDidLogOut:) name: kNotification_DidLogOut object: nil];
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internalModeSwitchEngaged:) name:kDSAInternalModeNotificationKey object:nil];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        _sendDocumentTrackerNotifications = NO;
        _inHistoryMode = NO;
        [self observe];
    }
    
    return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    self.docInteractionController.delegate = nil;
    
    self.webView.delegate = nil;
    [self.webView stopLoading];
    
#if BUILD_WITH_CORDOVA
    self.cordovaWebViewController = nil;
#endif
}

//////////////////////////////////////
//
//////////////////////////////////////
- (void) configuredTitleLabel: (UILabel *) label withString: (NSString *) titleString {
    MMSF_MobileAppConfig__c *mac = [g_appDelegate selectedMobileAppConfig];
    
    label.text = titleString;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [mac titleTextColor];
    
}

+ (id) controller {
	DSA_MediaDisplayViewController			*controller = [[[self alloc] init] autorelease];
    
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    
	return controller;
}

+ (id) controllerForItem: (MMSF_ContentVersion *) item withDelegate: (id <DSA_MediaDisplayViewControllerDelegate>) delegate {
	if (item.requiresQuicklook) {
		DSA_PreviewViewController *controller = [[DSA_PreviewViewController alloc] initWithItem: item];
        controller.dataSource = (id) controller;
		
		return controller;
	}
    
    DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controller];
    vc.sendDocumentTrackerNotifications = YES;
    vc.item = item;
    vc.mediaDisplayViewControllerDelegate = delegate;
    
	return vc;
}

// Constructor to use from DSA_ContentShelvesController

+ (id)controllerWithContentItem:(MMSF_ContentVersion*)contentItem
                      IndexPath:(NSIndexPath*)itemIndexPath
                     totalItems:(NSUInteger)totalItems
                   withDeledate:(id<DSA_MediaDisplayViewControllerDelegate>)delegate {
    
    UIViewController *controller = [DSA_MediaDisplayViewController controllerForItem:contentItem withDelegate:delegate];
//    UIViewController *topController = navController.topViewController;
    
    if ([controller isKindOfClass:[DSA_MediaDisplayViewController class]]) {
        DSA_MediaDisplayViewController *mdc = (DSA_MediaDisplayViewController*)controller;
        mdc.totalNumberOfItems = totalItems;
        mdc.currentItemIndexPath = itemIndexPath;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mdc];
        return navController;
    }
    return controller;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation {
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) toInterfaceOrientation duration: (NSTimeInterval) duration {
	[super willAnimateRotationToInterfaceOrientation: toInterfaceOrientation duration: duration];
	[self updateForOrientation: toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation: fromInterfaceOrientation];
	[self updateForOrientation: self.interfaceOrientation];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) updateForOrientation: (UIInterfaceOrientation) newOrientation {
    //	if (newOrientation == UIDeviceOrientationUnknown) newOrientation = self.interfaceOrientation;
	
    CGRect					bounds = self.view.bounds;// UIInterfaceOrientationIsPortrait(newOrientation) ? CGRectMake(0, 0, 768, 1004) : CGRectMake(0, 0, 1024, 748);
	
	bounds.origin.y = self.webView.frame.origin.y;
	bounds.size.height = bounds.size.height - bounds.origin.y;
	self.webView.normalizedFrame = bounds;
	return;
	
	self.view.frame = bounds;
	self.toolbar.normalizedFrame = CGRectMake(0, 0, bounds.size.width, 44);
	self.webView.normalizedFrame = CGRectMake(0, 44, bounds.size.width, bounds.size.height - 94);
}

- (void) viewDidLoad {
	[super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
#if BUILD_WITH_CORDOVA
    CDVViewController *viewController = [CDVViewController new];
    viewController.wwwFolderName = @"www";
    viewController.startPage = @"index.html";
    viewController.view.frame = self.webView.frame;
    [self.webView removeFromSuperview];
    self.webView = nil;
    [self.view addSubview:viewController.view];
    self.webView = viewController.webView;
    self.webView.delegate = self;
    self.cordovaWebViewController = viewController;
    self.webView.scalesPageToFit = YES;
#endif
    
	if (self.url) [self.webView loadRequest: [NSURLRequest requestWithURL: self.url]];
    //	if (self.title.length) self.titleLabel.text = self.title;
	self.spinnerHolder.alpha = 0.0;
	self.spinnerHolder.layer.cornerRadius = 10;
	if (self.url == nil && self.item == nil) [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media" ofType: @"html"]]]];

	[self setupToolbar];
    
    [self useSwipeGesture];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.item)
        [self loadItem];
    self.isDefaultLoadedFromHistory = NO;
    
    if (self.inHistoryMode) {
        if([[g_appDelegate.contentItemHistory contentItemHistory] count] == 0)
            return;
        
        if([[g_appDelegate documentTracker] trackedDocumentCount] == 0 && [g_appDelegate isTrackingDocuments])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self historyPressed:nil];
            });
        }
    }
}

- (void) viewWillAppear: (BOOL)animated {
	[super viewWillAppear: animated];
	
	self.navigationController.navigationBarHidden = YES;
    
    MMSF_MobileAppConfig__c * mac = [g_appDelegate selectedMobileAppConfig];
	
    self.toolbar.tintColor = [mac titleBarColor];
    
    //  if (self.contentItemTitle.length && self.item == nil) self.item = [[SF_Store store].context anyObjectOfType: [SF_ContentItem entityName] matchingPredicate: $P(@"title == %@", self.contentItemTitle)];
    //	if (self.item) [self loadItem];
    [self configuredTitleLabel: self.titleLabel withString: self.title.length ? self.title : [self.item Title]];
    
    if (self.inHistoryMode)
    {
        //Default Content Item should not be not displayed in History Mode when "Check in" is Enabled.
        if([g_appDelegate isTrackingDocuments])
            self.isDefaultLoadedFromHistory = YES;
        
        NSArray* arr = [g_appDelegate.contentItemHistory contentItemHistory];
		MM_ManagedObjectContext			*moc = (id) self.item.moc ?: [MM_ContextManager sharedManager].threadContentContext;

        if (arr.count > 0)
        {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"Id = %@",[[arr objectAtIndex:0] objectForKey:@"contentVersionID" ]];
            MMSF_ContentVersion* ci = (id) [moc anyObjectOfType:@"ContentVersion" matchingPredicate: pred];
            self.item = ci;
            [self loadItem];
        }else {
            /*to fix the crash make the item object nil when array count is 0*/
            self.item = nil;
            if (self.url == nil && self.item == nil) [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media" ofType: @"html"]]]];
        }
        
        self.view.accessibilityLabel = @"History Media Display Controller View";
        self.view.accessibilityIdentifier = @"History Media Display Controller View";
    } else {
        self.view.accessibilityLabel = @"Media Display Controller View";
        self.view.accessibilityIdentifier = @"Media Display Controller View";
    }
    self.view.isAccessibilityElement = YES;

}

- (void) viewWillDisappear: (BOOL) animated {
    if ([self.item isMovieFile]) 	[self.webView loadHTMLString: @"" baseURL: nil];
    
    [super viewWillDisappear: animated];
}

- (void) didReceiveMemoryWarning {
	if ([self isViewLoaded] && self.view.superview == nil) {
		self.webView.delegate = nil;
        [self.webView stopLoading];
	}
	[super didReceiveMemoryWarning];
	if (!self.isViewLoaded) self.item = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark -

- (UIBarButtonItem *) backBarButtonItem {
	if (_backBarButtonItem == nil) {
		_backBarButtonItem = [UIBarButtonItem SA_borderlessItemWithImage: [UIImage imageNamed:@"back.png"] target: self action: @selector(goBack)];
	}
	_backBarButtonItem.enabled = self.webView.canGoBack;
	return _backBarButtonItem;
}

- (UIBarButtonItem *) forwardBarButtonItem {
	if (_forwardBarButtonItem == nil) {
		_forwardBarButtonItem = [UIBarButtonItem SA_borderlessItemWithImage: [UIImage imageNamed:@"forward.png"] target: self action: @selector(goForward)];
	}
	_forwardBarButtonItem.enabled = self.webView.canGoForward;
	return _forwardBarButtonItem;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) setupToolbar {
	NSMutableArray			*barButtonItems = [NSMutableArray array];
    UIBarButtonItem* bbi;
    
    self.toolbar.tintColor = [UIColor whiteColor];
	
    if (self.inHistoryMode) {
		UIBarButtonItem			*historyItem = nil;
		
		if (RUNNING_ON_70) {
			UIButton				*historyButton = [UIButton buttonWithType: UIButtonTypeSystem];
			
			[historyButton setTitle: @"History" forState: UIControlStateNormal];
			IF_SIM([historyButton setTitle: @"View History" forState: UIControlStateNormal]);
			[historyButton sizeToFit];
			[historyButton addTarget:self action: @selector(historyPressed:) forControlEvents:UIControlEventTouchUpInside];
            historyButton.tintColor = [UIColor whiteColor];
			historyItem = [UIBarButtonItem itemWithView: historyButton];
			historyButton.accessibilityLabel = @"History Button";
		} else {
			historyItem = [UIBarButtonItem itemWithTitle:@"History" target:self action:@selector(historyPressed:)];
			historyItem.accessibilityLabel = @"History Button";
		}
		
        [barButtonItems addObject: historyItem];
    }
    else {
        bbi = [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemDone
                                           target: self
                                           action: @selector(donePressed)];
        if (RUNNING_ON_70) {
            bbi.tintColor = [UIColor whiteColor];
        }
        [barButtonItems addObject: bbi];
    }
	[barButtonItems	addObject: [UIBarButtonItem SA_flexibleSpacer]];
    
	if (self.url) {
		[barButtonItems addObject: self.backBarButtonItem];
		[barButtonItems addObject: self.forwardBarButtonItem];
		[barButtonItems addObject: [UIBarButtonItem spacerOfWidth: 20]];
	}
    
#if POST_CONTENT_TO_CHATTER
    bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"ChatterIcon"] target:self action:@selector(chatterButtonPressed:)];
    bbi.style = UIBarButtonItemStylePlain;
    [barButtonItems addObject:bbi];
    self.chatterButton = bbi;
#endif
    
#if OPENWITHSUPPORTED
    NSString *documentKeyValue = [self.item valueForKey:MNSS(@"Document_Type__c") ];
    if (!([self.item isMovieFile]) && ([self.item fullPath]!=nil) && (![documentKeyValue isEqualToString:@"ZIP"]) && (![documentKeyValue isEqualToString:@"LINK"])) {        
        UIBarButtonItem *docInteractionBarButtonItem=[UIBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAction target:self action:@selector(docInteractionButtonPressed)];
        
        [docInteractionBarButtonItem setTag:1];
        if ([self.item isProtectedContent]) {
            docInteractionBarButtonItem.enabled=NO;
        }
        if (RUNNING_ON_70) {
            docInteractionBarButtonItem.tintColor = [UIColor whiteColor];
        }
        [barButtonItems addObject:docInteractionBarButtonItem];
        
    }
#endif  // OPENWITHSUPPORTED
    
    //email button
    if ([self.item isProtectedContent]) {
        bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail_forbidden"]
                                      target: self
                                      action: @selector(sendAsEmail:)];
        bbi.enabled = NO;
    }
    else if ([g_appDelegate.documentTracker documentMarkedToSendAsEmail:[self.item Id]]) {
        bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail_marked"]
                                      target: self
                                      action: @selector(clearSendAsEmail:)];
    }
    else {
        bbi = [UIBarButtonItem itemWithImage:[UIImage imageNamed:@"mail"]
                                      target: self
                                      action: @selector(sendAsEmail:)];
    }
    
    bbi.tintColor = [UIColor whiteColor];
    bbi.style = UIBarButtonItemStylePlain;

    
#if SHOPPING_CART_SUPPORT
	[barButtonItems addObject: [UIBarButtonItem itemWithImage: [UIImage imageNamed: @"cart.png"] block: ^(id item) {
		self.item.currentlyInCartValue = !self.item.currentlyInCartValue;
		[self.item save];
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ShoppingCartContentsChanged object: self.item.objectID];
	}]];
#endif
	
    if ([self.item fullPath]) {
        [barButtonItems addObject:bbi];
    }
    
    // add to playlist
    UIImage *addToPlaylistImage = [UIImage imageNamed:@"AddToPlaylist.png"];
    UIBarButtonItem *playlistButton = [UIBarButtonItem itemWithImage:addToPlaylistImage target:self action:@selector(favoritesPressed:)];
    [barButtonItems addObject:playlistButton];
    
	self.toolbar.items = barButtonItems;
}

#if POST_CONTENT_TO_CHATTER
- (void) chatterButtonPressed:(id) sender
{
    ChatterPostViewController* vc = [[ChatterPostViewController alloc] init];
    vc.chatterPostDelegate = self;
    vc.item = self.item;
    
    self.postPopover = [[[UIPopoverController alloc] initWithContentViewController:vc] autorelease];
    vc.containerPopoverController = self.postPopover;
    [self.postPopover setPopoverContentSize:CGSizeMake(400.0, 315.0) animated:NO];
    [self.postPopover presentPopoverFromBarButtonItem:self.chatterButton
                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                             animated:YES];
    
}

/////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////
- (void) chatterPostViewController:(ChatterPostViewController*) controller donePressedWithPostBody:(NSString*) postBody
{
    CK_AttachmentInput* attach;
    
    if ([self.item isLinkContent])
    {
        NSString* link = self.item.ContentUrl;
        attach = [CK_AttachmentInputLink attachmentWithLink:[NSURL URLWithString:link] forName:[self.item valueForKey:@"Title"]];
    }
    else
    {
        NSString                    *contentID = self.item.documentID;
        attach = [CK_AttachmentInputExistingContent attachmentWithExistingContent: contentID];
    }
    
    NSArray* segments = [NSArray arrayWithObjects:
                         [CK_MessageSegmentInputText messageSegmentWithText:postBody],
                         nil];
    
    [[ChatterKit sharedInstance] postItemToPath:[ChatterKit pathForMyFeed]
                                messageSegments:segments
                                     attachment:attach
                                       delegate:self
                                       userInfo:nil];
    
    [self.postPopover dismissPopoverAnimated:YES];
    self.postPopover = nil;
}

/////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////
- (void) chatterPostViewControllerCancelPressed:(ChatterPostViewController*) controller
{
    [self.postPopover dismissPopoverAnimated:YES];
}
#endif

- (IBAction) goBack {
	[self.webView goBack];
}

- (IBAction) goForward {
	[self.webView goForward];
}

- (void)presentMailComposeControllerWithSubject:(NSString *)subject {
    MFMailComposeViewController *controller = [self.item controllerForMailingTo:self.toAddresses];
    [controller setSubject:subject];
    [self presentViewController: controller animated: YES completion: nil];
}

#pragma mark - Webview Delegate

- (void) webViewDidStartLoad: (UIWebView *) webViewLocal {
	self.spinnerHolder.alpha = 1.0;
    [self.spinner startAnimating];
    
	[self setupToolbar];
#if BUILD_WITH_CORDOVA
    [self.cordovaWebViewController webViewDidStartLoad:webViewLocal];
#endif
}
- (void) webViewDidFinishLoad: (UIWebView *) webViewLocal {
	[self.spinner stopAnimating];
    if (self.sendDocumentTrackerNotifications && !self.isDefaultLoadedFromHistory && [self.item ContentUrl])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStartViewingNotification object:self.item.Id];
    }
	self.spinnerHolder.alpha = 0.0;
	[self setupToolbar];
#if BUILD_WITH_CORDOVA
    [self.cordovaWebViewController webViewDidFinishLoad:webViewLocal];
#endif
}

- (void) webView: (UIWebView *) webView didFailLoadWithError: (NSError *) error {
    
	self.spinnerHolder.alpha = 0.0;
    [self.spinner stopAnimating];
    
    if (error.internetConnectionFailed) {
        [SA_AlertView showAlertWithTitle:@"" message:@"Connection not available"];
        
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		if ([request.URL.absoluteString hasSuffix: @"link_restart_movie_file"]) {
			self.lastLoadedSalesforceID = nil;
            if (self.item.isMovieFile && self.inHistoryMode){
                [self showMovie];
            }else {
                [self loadItem];
            }
			return NO;
		}
		[self.webView loadRequest: request];
		return NO;
	}
#if BUILD_WITH_CORDOVA
    [self.cordovaWebViewController webView:self.webView shouldStartLoadWithRequest:request navigationType:navigationType];
#endif
	return YES;
}

#pragma mark - Actions

- (void) sendAsEmail: (id) sender {
    [self.docInteractionController dismissMenuAnimated:YES];//Added to dissmiss open with menu if there
    
	if (![self.item canEmail]) {
        
        [SA_AlertView showAlertWithTitle:@"Sorry, you can't email this file." message: nil];
		
        return;
	}
    
	if (![MFMailComposeViewController canSendMail]) {
        
		[SA_AlertView showAlertWithTitle:@"Please set up your Mail account on this iPad before attempting to mail a document." message:@""];
		
        return;
	}

    if (g_appDelegate.isTrackingDocuments && (g_appDelegate.currentTrackingEntity || g_appDelegate.currentTrackingType == DocumentTracking_DeferredContact || g_appDelegate.currentTrackingType == DocumentTracking_DeferredLead)) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName: DocumentTrackerMarkToSendNotification object: [self.item Id]];
        [self setupToolbar];
    }
    else {
        
        if ((g_appDelegate.currentTrackingType == DocumentTracking_None) ||
            (g_appDelegate.currentTrackingType == DocumentTracking_AlwaysOn)) {

            id matchedEntity = [self.item.moc anyObjectOfType: [MMSF_Contact entityName] matchingPredicate: nil];
            if (!matchedEntity)
                matchedEntity = [self.item.moc anyObjectOfType: [MMSF_Lead entityName] matchingPredicate: nil];

            BOOL useSFDCContacts = CONTACTS_AVAILABLE && (matchedEntity != nil);
            if (useSFDCContacts)  {
                DSA_ContactSelectionController *vc = [DSA_ContactSelectionController controllerToMailContentItem: self.item];
                vc.contactSelectionDelegate = self;
                [self presentViewController: vc animated: YES completion: nil];
            }
            else {

                [self showEmailSubjectController];
            }
        }
        else {
            
            [[NSNotificationCenter defaultCenter] postNotificationName: DocumentTrackerMarkToSendNotification object: [self.item Id]];
            [self setupToolbar];
        }
    }
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller {
    for (NSUInteger i = 0; i < self.toolbar.items.count; i++) {
        if(((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).tag == 1)
            ((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).enabled=YES;
    }
    
}

////////////////////////////////////////////////////////////////
//On 21/12/2011 added by Subodh to implement open in capability
////////////////////////////////////////////////////////////////
- (IBAction) docInteractionButtonPressed
{
	NSString				*path = self.item.fullPath;
	NSString				*tmp = [@"~/tmp" stringByExpandingTildeInPath];
	NSString				*newPath = [tmp stringByAppendingPathComponent: self.item.filenameForMailing];
	NSError					*error = nil;
	NSURL					*fileURL = [NSURL fileURLWithPath:self.item.fullPath];
	
	if ([[NSFileManager defaultManager] createDirectoryAtPath: tmp withIntermediateDirectories: YES attributes: nil error: &error]) {
		[[NSFileManager defaultManager] removeItemAtPath: newPath error: &error];
		if ([[NSFileManager defaultManager] copyItemAtPath: path toPath: newPath error: &error]) {
			fileURL = [NSURL fileURLWithPath: newPath];
		}
	}
	
	
    self.docInteractionController = [UIDocumentInteractionController  interactionControllerWithURL: fileURL];
    self.docInteractionController.delegate = self;
    
    for (NSUInteger i = 0; i < [self.toolbar.items count]; i++)
    {
        if(((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).tag == 1)
        {
            ((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).enabled=NO;
            
            if (![self.docInteractionController presentOptionsMenuFromBarButtonItem:[self.toolbar.items objectAtIndex:i] animated:NO]) {
                
                [SA_AlertView showAlertWithTitle: @"Supporting applications not found" message: @""];
                ((UIBarButtonItem*)[self.toolbar.items objectAtIndex:i]).enabled=NO;
                
            }
            
        }
        
    }
}

- (void) clearSendAsEmail: (id) sender
{
    if (g_appDelegate.isTrackingDocuments)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerClearMarkToSendNotification object:[self.item Id]];   ////To Fix ; Defect ID:2621552
        [self setupToolbar];
    }
}

- (void) mailComposeController: (MFMailComposeViewController *) controller
           didFinishWithResult: (MFMailComposeResult) result error: (NSError *) error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) donePressed {
        [self.docInteractionController dismissMenuAnimated:NO];
        [self.favoritesPopover dismissPopoverAnimated:NO];
    
    [self.webView stopLoading];
#if BUILD_WITH_CORDOVA
    [self.cordovaWebViewController.webView stopLoading];
    self.cordovaWebViewController.webView.delegate = nil;
#endif
    
    
    if (self.sendDocumentTrackerNotifications)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStopViewingNotification object:self.item];
    }
    
    if ([self.mediaDisplayViewControllerDelegate respondsToSelector:@selector(donePressed:)]) {
        [self.mediaDisplayViewControllerDelegate donePressed:self];
    }

    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
    [self.webView loadRequest:req];
}

//////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////
- (IBAction) historyPressed:(id)sender
{
	if (![MM_LoginViewController isLoggedIn]) return;
	
    [self.docInteractionController dismissMenuAnimated:YES];
    if (historyPopover == nil) {
        ContentItemHistoryController* vc = [[[ContentItemHistoryController alloc] init] autorelease];
        
        historyPopover = [[UIPopoverController alloc] initWithContentViewController:vc];
        historyPopover.popoverContentSize = CGSizeMake(475, 44*15);
        
        UIBarButtonItem *barButton = self.toolbar.items[0];
        [historyPopover presentPopoverFromBarButtonItem:barButton permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionLeft animated:YES];
        
        historyPopover.delegate = self;
    }
    else {
        [historyPopover dismissPopoverAnimated:YES];
        historyPopover = nil;
    }
}

- (IBAction) favoritesPressed:(id)sender {
    [self.docInteractionController dismissMenuAnimated:YES];
    
    if (self.favoritesPopover != nil) {
        [self.favoritesPopover dismissPopoverAnimated:YES];
        self.favoritesPopover = nil;
    } else {
        DSA_AddFavoriteViewController *controller = [[DSA_AddFavoriteViewController alloc] initWithNibName:@"DSA_AddFavoriteViewController" bundle:nil];
        controller.delegate = self;
        controller.item = self.item;
        self.favoritesPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
        [self.favoritesPopover setPopoverContentSize:CGSizeMake(372, 650)];
        [self.favoritesPopover setDelegate:self];
        [self.favoritesPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [self.favoritesPopover setPassthroughViews:nil];
    }
}

#pragma mark - DSA_ContactSelectionControllerDelegate

- (void) contactSelectionControllerSendPressed: (DSA_ContactSelectionController*) contactSelectionController
{
	NSMutableArray	*addresses = [NSMutableArray array];
    NSMutableArray	*contactIDs = [NSMutableArray array];
    NSMutableArray  *leadIDs    = [NSMutableArray array];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: kDefaultsKey_DemoMode])
    {
        [addresses addObject: contactSelectionController.demoEmailAddress];
    }
    else
    {
        NSArray* mailTargets = contactSelectionController.selectedContacts;
        for (NSManagedObject *entity in mailTargets) {
            
            if ([entity isKindOfClass: [MMSF_Contact class]]) {
                
                MMSF_Contact *contact = (MMSF_Contact *) entity;
                [addresses addObject: contact.Email ?: @""];
                if (contact.Id) [contactIDs addObject: contact.Id];
            }
            else if ([entity isKindOfClass: [MMSF_Lead class]]) {
                
                MMSF_Lead *lead = (MMSF_Lead *) entity;
                if (lead.Email.length > 0)
                    [addresses addObject: lead.Email];
                
                if (lead.Id)
                    [leadIDs addObject: lead.Id];
                
            }
        }
    }

    [self dismissViewControllerAnimated:NO completion:nil];

    self.toAddresses = addresses;
    [self showEmailSubjectController];
}


//////////////////////////////////////
//
//////////////////////////////////////
- (void) contactSelectionControllerCancelPressed: (DSA_ContactSelectionController*) contactSelectionController;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if ([self.favoritesPopover isEqual:popoverController]) {
        self.favoritesPopover = nil;
    } else {
        historyPopover = nil;
    }
}

#pragma mark - Favorite delegate methods

- (void) addFavoriteViewControllerDonePressed:(id) sender {
    [self.favoritesPopover dismissPopoverAnimated:YES];
    self.favoritesPopover = nil;
}

#pragma mark - SwipeGestures

- (void)useSwipeGesture {
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [swipeRight setNumberOfTouchesRequired:2];
    //    [swipeRight setDelegate:self];
    [self.webView addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeLeft setNumberOfTouchesRequired:2];
    //    [swipeLeft setDelegate:self];
    [self.webView addGestureRecognizer:swipeLeft];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
    [pan setMaximumNumberOfTouches:2];
    [pan setMinimumNumberOfTouches:2];
    [self.webView addGestureRecognizer:pan];
    
    [pan requireGestureRecognizerToFail:swipeLeft];
    [pan requireGestureRecognizerToFail:swipeRight];
}

- (void)swipeRight:(UISwipeGestureRecognizer *)recognizer {
    NSUInteger touches = recognizer.numberOfTouches;
    if (touches == 2 && [self isPreviousItemAvailable]) {
        // show previous item
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentItemIndexPath.row - 1
                                                    inSection:self.currentItemIndexPath.section];
        MMSF_ContentVersion *prevItem = [[DSA_ContentShelvesModel sharedModel] contentItemAtIndexPath:indexPath];
        self.currentItemIndexPath = indexPath;
        self.item = prevItem;
        [self loadItem];
    }
}

- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer {
    NSUInteger touches = recognizer.numberOfTouches;
    if (touches == 2 && [self isNextItemavailable]) {
        // show next item
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentItemIndexPath.row + 1
                                                    inSection:self.currentItemIndexPath.section];
        MMSF_ContentVersion *prevItem = [[DSA_ContentShelvesModel sharedModel] contentItemAtIndexPath:indexPath];
        self.currentItemIndexPath = indexPath;
        self.item = prevItem;
        [self loadItem];
    }
}

#pragma mark - Swipe utility

- (BOOL)isNextItemavailable {
    if (self.currentItemIndexPath.row + 1 < self.totalNumberOfItems)
        return YES;
    return NO;
}

- (BOOL)isPreviousItemAvailable {
    if (self.currentItemIndexPath.row > 0)
        return YES;
    return NO;
}

#pragma mark - Notifications

- (void) userDidLogOut:(NSNotification*)note {
	self.item = nil;
	NSURL				*urlToLoad = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media" ofType: @"html"]];
	
	[self.webView loadRequest: [NSURLRequest requestWithURL: urlToLoad]];
	[historyPopover dismissPopoverAnimated:YES];
	historyPopover = nil;
}

- (void) contentItemDownloadCompleted: (NSNotification *) note {
	MMSF_ContentVersion				*newItem = note.object;
	
	if (![[self.item Id] isEqual: [newItem Id]]) return;
	
	self.lastLoadedSalesforceID = nil;
	[self contentItemSelected: note];
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
- (void) displayItem {
	[self view];
	
    //	self.navigationBar.topItem.title = self.item.title;
    [self configuredTitleLabel: self.titleLabel withString: [self.item Title]];
/*
    if (!g_appDelegate.isTrackingContact) {
        BOOL canDistribute = [self.item canEmail] && (![[self.item valueForKey:MNSS(@"Document_Type__c")]isEqualToString:@"Competitive Information"]);
        self.navigationBar.topItem.rightBarButtonItem = (canDistribute) ? [UIBarButtonItem itemWithTitle: @"Send as Email" target: self action: @selector(sendAsEmail:)] : nil;
	}
    else {
        self.navigationBar.topItem.rightBarButtonItem = nil;
    }
*/
    if(self.item.isMovieFile) {
        [self showMovie];
    }
    else {
		[self performSelector: @selector(loadItem) withObject: nil afterDelay: 0.0];
    }
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
- (void) contentItemSelected: (NSNotification *) note {
    NSString *contentId = note.object;
	if (![[self.item Id] isEqual:contentId]) {
		[self unloadItem];
        self.item = [MMSF_ContentVersion contentItemBySalesforceId:contentId];
		self.lastLoadedSalesforceID = nil;
		
		[self.webView loadHTMLString: @"" baseURL: nil];
	}
    
    [self displayItem];
}

- (void) unloadItem {
    if (self.item && self.sendDocumentTrackerNotifications && !self.isDefaultLoadedFromHistory) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStopViewingNotification object:nil];
    }
}

////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////
- (void) loadItem {
    // only display internal Content when in internal mode
    BOOL internalContent = [self.item[MNSS(@"Internal_Document__c")] boolValue];
    if (internalContent) {
        BOOL internalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
        if (!internalMode) {
            self.item = nil;
            self.lastLoadedSalesforceID = nil;
        }
    }
    
    //Default Content Item should not be not displayed in History Mode when Check in Enabled.
    if(self.item && (!self.isDefaultLoadedFromHistory || [[g_appDelegate documentTracker] trackedDocumentCount] != 0))
    {
		NSManagedObjectContext		*moc = self.item.moc ?: [MM_ContextManager sharedManager].threadContentContext;
        if (moc) {
            self.item = (id) [moc objectWithID: self.item.objectID];
        }
    }
    else
    {
        self.item = nil;
        
    }
    [self configuredTitleLabel: self.titleLabel withString: self.title.length ? self.title : [self.item Title]];
    
    if (!self.inHistoryMode)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:ContentItemHistoryItemViewedNotification
                                                            object:self.item.Id];
    }
    
    if (self.sendDocumentTrackerNotifications && !self.isDefaultLoadedFromHistory && ![self.item ContentUrl]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStartViewingNotification object:self.item.Id];
    }
	
    NSURL *urlToLoad = nil;
    
    if(![g_appDelegate isTrackingDocuments])
        urlToLoad = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media" ofType: @"html"]];
    else
        urlToLoad = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media_History" ofType: @"html"]];
    
	if (self.item.isMovieFile)
    {
		urlToLoad = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"tap_for_movie" ofType: @"html"]];
	}
    else if([self.item ContentUrl])
    {
        urlToLoad = [NSURL URLWithString:[self.item.ContentUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
    }
#if HTMLBUNDLECONTENTSUPPORTED
    else if ([self.item isZipFile])
    {
        // Need to unzip the file and set the URL of the unzipped file to view
        if ([self.item fullPath ].length)
        {
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentPath = [paths objectAtIndex:0];
            NSError				*e = nil;
            NSString *directoryPath = [documentPath stringByAppendingPathComponent:@"Test"];
            NSString * itemFileName = [NSString stringWithFormat:@"%@.htmlbundle", self.item.Title];
            NSString * newPath = [NSString stringWithFormat:@"%@/%@", directoryPath, itemFileName];
            
            BOOL isDir;
            if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:&e];
            }
            
            
			self.htmlBundleDataPath = [NSString tempFileNameWithSeed: self.item.Title ofType: @"htmlbundle"];
            
            /* Remove check for the existance of Unzipped HTML bundle file in a test folder */
            /* Unzip the file everytime so that when we update a HTML bundle version it should display updated file */
            [SSZipArchive unzipFileAtPath:[self.item fullPath] toDestination:newPath];
            
            self.htmlBundleDataPath = newPath;
            
        }
    }
#endif
    else if ([self.item fullPath ].length)
    {
        //this may seem a little weird but here is why it is here:
        //
        //Initially the stringByReplacingPercentEscapesUsingEncoding was added to handle a file name that had a umlat and all was happy
        //but one day a file name  with a % in it came by, it confused the replace and everybody was sad
        //But along came stringByAddingPercentEscapesUsingEncoding and it now worked for both cases and everybody lived happily ever after.
        //
        NSString* s = [self.item.fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlToLoad = [NSURL fileURLWithPath: [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
#if  HTMLBUNDLECONTENTSUPPORTED
	//self.backToolbar.hidden = (self.previousControllerIndex == NSNotFound);
	if (self.item.isZipFile)
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[self.htmlBundleDataPath stringByAppendingPathComponent:@"index.html"] isDirectory:NO]]];
        return;
    }
    else
#endif
        if (urlToLoad && ![urlToLoad isEqual: self.webView.request.URL])
        {
            /* set the delay to 0.0 to fix the crash issue at history */
            [self.webView performSelector: @selector(loadRequest:) withObject: [NSURLRequest requestWithURL: urlToLoad] afterDelay: 0.0];
        }
    
	if ([self.lastLoadedSalesforceID isEqual: [self.item Id]])
        return;
    
	self.lastLoadedSalesforceID = self.item.Id;
	if(!self.inHistoryMode){
        if (self.item.isMovieFile)
        {
            [self showMovie];
        }
    }
}

- (NSString*) mimeTypeForFileAtPath: (NSString *) path {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    //    return [NSMakeCollectable((NSString *)mimeType) autorelease];
    return [NSString stringWithString:CFBridgingRelease(mimeType)]; //possibly unnecessary
    
}


////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////
- (void) showMovie {
	self.movieController = [[[MPMoviePlayerViewController alloc] initWithContentURL: [NSURL fileURLWithPath: self.item.fullPath]] autorelease];
    [self presentViewController:self.movieController animated:YES completion:nil];
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (void) enteringForeground:(NSNotification*) notification
{
    if (self.sendDocumentTrackerNotifications && self.item != nil)
    {
        UIViewController* vc = self.tabBarController.selectedViewController;
        if (vc == self.navigationController)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:DocumentTrackerStartViewingNotification object:self.item.Id];
        }
    }
}

- (void) contextChanged: (NSNotification *) notification
{
	[self unloadItem];
	self.item = nil;
	NSURL				*urlToLoad = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: @"no_media" ofType: @"html"]];
	[self.webView loadRequest: [NSURLRequest requestWithURL: urlToLoad]];
}

/////////////////////////////////////////////
//
/////////////////////////////////////////////
- (void) historyItemSelected: (NSNotification *) note {
    [historyPopover dismissPopoverAnimated:YES];
    [historyPopover autorelease];
    historyPopover = nil;
    
    NSString *selectedId = note.object;
    MMSF_ContentVersion *content = [MMSF_ContentVersion contentItemBySalesforceId:selectedId];
    NSString *contentId = content.Id;
    
	if (![self.item.Id isEqual:contentId]) {
		[self unloadItem];
		self.item = content;
		self.lastLoadedSalesforceID = nil;
		[self.webView loadHTMLString: @"" baseURL: nil];
	}
    
    [self displayItem];
}

#pragma mark - EmailSubjectControllerDelegate

- (void)emailSubjectSelected:(NSString *)subject {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self presentMailComposeControllerWithSubject:subject];
}

- (void)emailSubjectCanceled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showEmailSubjectController {
    EmailSubjectController *controller = [EmailSubjectController creaetEmailSubjectController];
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

@end
