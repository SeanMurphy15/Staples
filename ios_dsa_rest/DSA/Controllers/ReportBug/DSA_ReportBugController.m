//
//  DSA_ReportBugController.m
//  Hydra
//
//  Created by Ben Gottlieb on 7/25/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "DSA_ReportBugController.h"

@implementation DSA_ReportBugController
@synthesize navigationBar, toolbar, webView, docWebView = _docWebView;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}



//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	DSA_ReportBugController		*controller = [[[DSA_ReportBugController alloc] init] autorelease];
	
	return controller;
}


//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	NSURL				*url = [NSURL URLWithString:@"http://www.modelmetrics.com/digital-sales-aid-support/"];
	UINavigationItem	*item = [[[UINavigationItem alloc] initWithTitle: @"Report A Problem"] autorelease];
	
	item.backBarButtonItem = [UIBarButtonItem itemWithTitle: @"Back" target: nil action: nil];
	
	[self.webView loadRequest: [NSURLRequest requestWithURL: url]];
	[self.navigationBar pushNavigationItem: item animated: NO];

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

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return YES; }// UIInterfaceOrientationIsLandscape(interfaceOrientation); }

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

//=============================================================================================================================
#pragma mark WebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	MMLog(@"request: %@", request);
	
	if ([request.URL.scheme isEqual: @"view"]) {
		NSString					*path = [request.URL.resourceSpecifier stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
		
		path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: path]; 
		self.docWebView.alpha = 0.0;
		[self.docWebView loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath: path]]];
		[UIView animateWithDuration: 0.2 animations: ^{self.docWebView.alpha = 1.0; }];
		[self.navigationBar pushNavigationItem: [[[UINavigationItem alloc] initWithTitle: @""] autorelease] animated: YES];
		return NO;
	}
	
	return YES;
}

- (UIWebView *) docWebView {
	if (_docWebView == nil) {
		self.docWebView = [[[UIWebView alloc] initWithFrame: self.webView.frame] autorelease];
		self.docWebView.scalesPageToFit = YES;
		[self.view addSubview: self.docWebView];
	}
	return _docWebView;
}

//=============================================================================================================================
#pragma mark Actions
- (IBAction) back {
	[self.navigationController popViewControllerAnimated: YES];
}

//=============================================================================================================================
#pragma mark Notifications


//=============================================================================================================================
#pragma mark Delegates
- (BOOL) navigationBar: (UINavigationBar *) navigationBar shouldPopItem: (UINavigationItem *) item {
	if (_docWebView) {
		[UIView animateWithDuration: 0.2 animations: ^{ self.docWebView.alpha = 0.0; } completion: ^(BOOL finished) { [self.docWebView removeFromSuperview]; _docWebView = nil; }];
		return YES;
	}
	[self.navigationController popViewControllerAnimated: YES];
	return NO;
}

@end
