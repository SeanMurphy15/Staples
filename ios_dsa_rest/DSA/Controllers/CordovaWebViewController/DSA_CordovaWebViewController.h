//
//  DSA_CordovaWebViewController
//
//  Created by Alexey Bilous.
//  Copyright 2012 ModelMetrics, Inc. All rights reserved.
//

#if BUILD_WITH_CORDOVA

#import <Cordova/CDVViewController.h>
#import "MMSF_ContentVersion.h"
#import <MessageUI/MessageUI.h>
#import "DSA_ContactSelectionController.h"

@class DSA_CordovaWebViewController;

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
@protocol DSA_CordovaWebViewControllerDelegate

- (void) donePressed:(DSA_CordovaWebViewController*) controller;

@end

@interface DSA_CordovaWebViewController : CDVViewController <UIDocumentInteractionControllerDelegate, MFMailComposeViewControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;
@property (nonatomic, readwrite, strong) MMSF_ContentVersion *item;
@property (nonatomic, readwrite, weak) IBOutlet UIBarButtonItem *backBarButtonItem, *forwardBarButtonItem;
@property (nonatomic, readwrite, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, readwrite, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, assign) BOOL sendDocumentTrackerNotifications;
@property (nonatomic, assign) BOOL inHistoryMode;
@property (nonatomic, weak) NSObject<DSA_CordovaWebViewControllerDelegate>* cordovaWebViewControllerDelegate;

//13/01/2012 added by India team to resolve issue no 2573341
@property (nonatomic,readwrite,assign) BOOL isDefaultLoadedFromHistory;
+ (id) controller ;
@end

#endif
