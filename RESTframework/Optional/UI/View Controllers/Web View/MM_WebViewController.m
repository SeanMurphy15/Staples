//
//  MM_WebViewController.m
//  Cat MCV
//
//  Created by Ben Gottlieb on 3/31/12.
//  Copyright 2012 Model Metrics, Inc. All rights reserved.
//

#import "MM_WebViewController.h"
#import "MM_Headers.h"

static BOOL				s_openLinksInsideApp = YES, s_lockedToLandscape = NO, s_lockedToPortrait = NO;

@interface MM_WebViewController ()
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@end

@implementation MM_WebViewController
@synthesize url, webView, navigationBar;

+ (void) load {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(openURL:) name: kNotification_DisplayWebpage object: nil];
	}
}

+ (NSURL *) sanitizedURLFromString: (NSString *) string {
	string = [string stringByStrippingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] options: 0];
	
	if (![string containsCString: "://"]) string = $S(@"http://%@", string);
	return [NSURL URLWithString: string];
}

+ (void) setLockedToPortrait: (BOOL) lockedToPortrait { s_lockedToPortrait = lockedToPortrait; }
+ (void) setLockedToLandscape: (BOOL) lockedToLandscape { s_lockedToLandscape = lockedToLandscape; }


+ (void) openURL: (NSNotification *) note {
	if (s_openLinksInsideApp)
		[self displayURL: note.object inViewController: nil animated: YES];
	else
		[[UIApplication sharedApplication] openURL: note.object];
}

+ (void) setOpenLinksInsideApp: (BOOL) openInside {
	s_openLinksInsideApp = openInside;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}



//=============================================================================================================================
#pragma mark Factory
+ (id) controller {
	MM_WebViewController		*controller = [[self alloc] init];
	UINavigationController		*nav = [[UINavigationController alloc] initWithRootViewController: controller];
		
	nav.navigationBar.barStyle = UIBarStyleBlack;
	controller.navigationItem.rightBarButtonItem = [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemDone target: controller action: @selector(done:)];
	return nav;
}

+ (void) displayURL: (NSURL *) url inViewController: (UIViewController *) parent animated: (BOOL) animated {
	MM_WebViewController			*controller = [self controller];
	controller.url = url;
	
	if (parent == nil) {
		UIWindow				*window = [UIApplication sharedApplication].keyWindow;
		
		parent = [window rootViewController];
	}
	
	[parent presentViewController: controller animated: YES completion: nil];
}

+ (id) controllerWithDocumentPath: (NSString *) filePath {
	MM_WebViewController			*controller = [self controller];
	controller.url = [NSURL fileURLWithPath: filePath];
	return controller;
}

//=============================================================================================================================
#pragma mark LifeCycle
- (void) viewDidLoad {
	[super viewDidLoad];
	if (self.url) [self.webView loadRequest: [NSURLRequest requestWithURL: self.url]];
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

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { 
	if (s_lockedToPortrait && !UIInterfaceOrientationIsPortrait(interfaceOrientation)) return NO;
	if (s_lockedToLandscape && !UIInterfaceOrientationIsLandscape(interfaceOrientation)) return NO;
	return YES; 
}

//=============================================================================================================================
#pragma mark Properties


//=============================================================================================================================
#pragma mark Actions
- (IBAction) done: (id) sender {
	[self dismissViewControllerAnimated: YES completion: nil];
}

//=============================================================================================================================
#pragma mark Notifications


//=============================================================================================================================
#pragma mark webview delegate
- (void) webViewDidFinishLoad: (UIWebView *) webView {
	self.navigationItem.title = [self.webView stringByEvaluatingJavaScriptFromString: @"document.title"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if (error.code == 204) return;
	
	[SA_AlertView showAlertWithTitle: self.url.absoluteString message: error.localizedDescription];
}

@end


@implementation UINavigationController (MM_WebViewController)
- (MM_WebViewController *) webViewController { return (id) [self.viewControllers objectAtIndex: 0]; }
- (NSURL *) url { return self.webViewController.url; }
- (void) setUrl:(NSURL *)url { self.webViewController.url = url; }
@end