//
//  ZM_MediaDisplayController.h
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_ContactSelectionController.h"
#import "MMSF_ContentVersion.h"
#import <MessageUI/MessageUI.h>

#if BUILD_WITH_CORDOVA
    #import <Cordova/CDVViewController.h>
#endif

#if POST_CONTENT_TO_CHATTER
#import "ChatterPostViewController.h"
#endif 

#define kNotification_ContentItemSelected @"com.modelmetrics.dsaapp.contentItemSelected"

@class DSA_MediaDisplayViewController;
@class MPMoviePlayerViewController;

@protocol DSA_MediaDisplayViewControllerDelegate

- (void) donePressed:(DSA_MediaDisplayViewController*) controller;

@end

@interface DSA_MediaDisplayViewController : UIViewController <MFMailComposeViewControllerDelegate, UIPopoverControllerDelegate, DSA_ContactSelectionControllerDelegate, UIDocumentInteractionControllerDelegate, UIWebViewDelegate

#if POST_CONTENT_TO_CHATTER
                                            ,ChatterPostViewControllerDelegate,
                                            CK_ChatterKitRestRequestDelegate
#endif
>
{
    UIPopoverController* historyPopover;
}

@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;
@property (nonatomic, readwrite, weak) IBOutlet UIWebView *webView;
@property (nonatomic, readwrite, weak) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, readwrite, weak) IBOutlet UIBarButtonItem *backBarButtonItem, *forwardBarButtonItem;
@property (nonatomic, readwrite, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, readwrite, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, readwrite, weak) IBOutlet UIView *spinnerHolder;

@property (nonatomic, readwrite, strong) NSURL *url;
@property (nonatomic, readwrite, strong) MMSF_ContentVersion *item;
@property (nonatomic, readwrite) NSInteger previousControllerIndex;
@property (nonatomic, readwrite, strong) NSString *lastLoadedSalesforceID, *contentItemTitle;
@property (nonatomic, readwrite, strong) MPMoviePlayerViewController *movieController;
#if BUILD_WITH_CORDOVA
    @property (nonatomic, strong) CDVViewController *cordovaWebViewController;
#endif

@property (nonatomic, strong) NSString *htmlBundleDataPath;

@property (nonatomic, assign) BOOL sendDocumentTrackerNotifications;

@property (nonatomic, assign) BOOL inHistoryMode;
@property (nonatomic, weak) id mediaDisplayViewControllerDelegate;

@property (nonatomic,readwrite,assign) BOOL isDefaultLoadedFromHistory;

+ (id) controller;
+ (id) controllerForItem: (MMSF_ContentVersion *) item withDelegate: (id <DSA_MediaDisplayViewControllerDelegate>) delegate;
+ (id) controllerWithContentItem:(MMSF_ContentVersion*)contentItem IndexPath:(NSIndexPath*)itemIndexPath totalItems:(NSUInteger)totalItems withDeledate:(id<DSA_MediaDisplayViewControllerDelegate>)delegate;

- (void) updateForOrientation: (UIInterfaceOrientation) newOrientation;

- (IBAction) donePressed;
- (IBAction) docInteractionButtonPressed;
- (IBAction) historyPressed:(id)sender;

- (void) contentItemSelected: (NSNotification *) note;
- (void) loadItem;
- (void) unloadItem;
- (void) showMovie;
- (void) setupToolbar;

@end



