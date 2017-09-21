//
//  HY_HTMLHelpController.m
//  Hydra
//
//  Created by Ben Gottlieb on 7/25/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "HY_HTMLHelpController.h"

@implementation HY_HTMLHelpController
@synthesize navigationBar, toolbar, webView;

- (void) dealloc {
	self.webView.delegate = nil;
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}



//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	HY_HTMLHelpController		*controller = [[[HY_HTMLHelpController alloc] init] autorelease];
	
	return controller;
}

- (void) loadInitialContent {
	NSURL				*url = [[NSBundle mainBundle] URLForResource: @"Index" withExtension: @"html" subdirectory: @"HTMLHelp"];
	
	[self.webView loadRequest: [NSURLRequest requestWithURL: url]];
}

//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	[self loadInitialContent];
	[self.navigationBar pushNavigationItem: [[[UINavigationItem alloc] initWithTitle: @"Help"] autorelease] animated: NO];

	self.toolbar.items = $A(
							[UIBarButtonItem SA_flexibleSpacer], 
							[UIBarButtonItem itemWithView: [[[UIImageView alloc] initWithImage: [UIImage imageNamed:@"SalesforceServices.png"]] autorelease]],
							[UIBarButtonItem SA_flexibleSpacer]);

	[super viewDidLoad];
}

//- (void) viewWillAppear: (BOOL) animated {
//	[super viewDidAppear: animated];
//}

//- (void) viewDidAppear: (BOOL) animated {
//	[super viewDidAppear: animated];
//}

//- (void) viewWillDisappear: (BOOL) animated {
//	[super viewWillDisappear: animated];
//}

//- (void) viewDidDisappear: (BOOL) animated {
//	[super viewDidDisappear: animated];
//}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return YES; }

//=============================================================================================================================
#pragma mark Properties


//=============================================================================================================================
#pragma mark Actions
- (IBAction) back {
	[self.navigationController popViewControllerAnimated: YES];
}

//=============================================================================================================================
#pragma mark Notifications
- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
		UINavigationItem				*item = [[[UINavigationItem alloc] initWithTitle: @"Back"] autorelease];
		item.backBarButtonItem = [UIBarButtonItem itemWithTitle: @"Back" target: nil action: nil];
		[self.navigationBar pushNavigationItem: item animated: YES];
	}
	return YES;
}

- (void) webViewDidFinishLoad: (UIWebView *) webView {
	self.navigationBar.topItem.title = [self.webView stringByEvaluatingJavaScriptFromString: @"document.title"];
}

//=============================================================================================================================
#pragma mark Delegates
- (BOOL) navigationBar: (UINavigationBar *) navigationBar shouldPopItem: (UINavigationItem *) item {
	if (self.navigationBar.items.count == 2) {
		[self.navigationController popViewControllerAnimated: YES];
	}
	if (self.webView.canGoBack) {
		if (self.navigationBar.items.count <= 3) {
			[self loadInitialContent];
		} else 
			[self.webView goBack];
		return YES;
	}
	return NO;
}

@end
