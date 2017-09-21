//
//  MM_LoginViewController.m
//
//  Created by Ben Gottlieb on 11/13/11.
//  Copyright 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_LoginViewController.h"
#import "MM_Notifications.h"
#import "MM_Constants.h"
#import "MM_SyncManager.h"
#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"
#import "MM_SABase_ConvenienceMethods.h"
#import "MM_ContextManager.h"
#import "MM_Log.h"
#import "NSString+MM_String.h"
#import <SalesforceNativeSDK/SFRestAPI.h>
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFAuthenticationViewHandler.h>

static NSString *s_currentAccountIdentifier = @"Default";
static BOOL s_clearDataOnNewUser = YES;

@interface MM_LoginViewController () <SFAuthenticationManagerDelegate, SFUserAccountManagerDelegate>
+ (MM_LoginViewController *) controller;

@property (nonatomic, weak) UIBarButtonItem *presentingBarButtonItem;
@property (nonatomic, weak) UIWebView *authWebView;
@property (nonatomic, weak) id <UIWebViewDelegate> authWebViewDelegate;
@property (nonatomic) BOOL togglingServer, newUserLoggedIn, autofilledCredentials;
@property (nonatomic, weak) UIViewController *viewControllerToPresentIn;
@property (nonatomic, readonly) NSString *preloadedPassword, *preloadedUsername;

- (IBAction) cancel: (id) sender;
- (IBAction) toggleServer: (id) sender;

- (void) logout;
- (void) login;
- (void) setupBarButtonItems;
@end


@interface SFUserAccountManager (fullKeychainIdentifier)
+ (NSString *) fullKeychainIdentifier: (NSString *) accountIdentifier;
@end


static BOOL								s_loggedIn = NO, s_loggingOut = NO, s_authenticated = NO, s_forceLoginOnFreshInstall = NO;
static MM_LoginViewController			*s_activeLoginController = nil;
static NSString							*s_redirectURI = nil, *s_loginDomain = nil, *s_remoteAccessConsumerKey = nil, *s_remoteAccessSandboxConsumerKey = nil, *s_remoteAccessProductionConsumerKey = nil;

@implementation MM_LoginViewController
@synthesize canToggleServer = _canToggleServer;

+ (void) setupUserAgent {
	NSString				*uaString =  [SFRestAPI userAgentString];
	NSDictionary			*dictionary = @{ @"UserAgent": uaString };

	[[NSUserDefaults standardUserDefaults] registerDefaults: dictionary];
}

+ (void) load {
	@autoreleasepool {
		s_loggedIn = [[NSUserDefaults standardUserDefaults] boolForKey: DEFAULTS_CURRENTLY_LOGGED_IN];
	}
}

//=============================================================================================================================
#pragma mark - Factory

+ (MM_LoginViewController *) controller {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[SFAuthenticationManager sharedManager].authViewHandler = [[SFAuthenticationViewHandler alloc] initWithDisplayBlock: ^(SFAuthenticationManager *mgr, UIWebView *webview) {
			s_activeLoginController.authWebView = webview;
		} dismissBlock: ^(SFAuthenticationManager *mgr) {
			
		}];
		
		s_activeLoginController = [[MM_LoginViewController alloc] init];
		
		s_activeLoginController.modalPresentationStyle = UIModalPresentationFormSheet;
		
		s_activeLoginController.canCancel = YES;
		IF_DEBUG(s_activeLoginController.canToggleServer = YES;);
		s_activeLoginController.useTestServer = [[NSUserDefaults standardUserDefaults] boolForKey: DEFAULTS_USE_SANDBOX] || s_activeLoginController.preloadedUseSandbox;
		//s_activeLoginController.credentialsIdentifier = [SFUserAccountManager fullKeychainIdentifier: @"Default"];//[NSBundle identifier];
		[s_activeLoginController addAsObserverForName: kNotification_ConnectionStatusChanged selector: @selector(connectionStateChanged:)];
		//[s_activeLoginController addAsObserverForName: UIApplicationDidFinishLaunchingNotification selector: @selector(didFinishLaunching:)];
		[[SFAuthenticationManager sharedManager] addDelegate: s_activeLoginController];
		[[SFUserAccountManager sharedInstance] addDelegate: s_activeLoginController];

	});
	
	return s_activeLoginController;
}

- (NSString *) preloadedPassword {
	NSString					*password = nil;
	
	if (self.useTestServer) password = [[[NSProcessInfo processInfo] environment] objectForKey: @"SANDBOX_PASSWORD"];
	return password ?: [[[NSProcessInfo processInfo] environment] objectForKey: @"PRELOADED_PASSWORD"];
}

- (BOOL) disableAutoLogin { return [[[[NSProcessInfo processInfo] environment] objectForKey: @"DISABLE_AUTO_LOGIN"] intValue]; }

- (BOOL) preloadedUseSandbox {
	if (_useTestServer) return _useTestServer;
	return [[[[NSProcessInfo processInfo] environment] objectForKey: @"PRELOADED_USE_SANDBOX"] intValue] > 0;
}

- (NSString *) preloadedUsername {
	NSString			*username = nil;
	
	if (self.useTestServer) username = [[[NSProcessInfo processInfo] environment] objectForKey: @"SANDBOX_USERNAME"];
	return username ?: [[[NSProcessInfo processInfo] environment] objectForKey: @"PRELOADED_USERNAME"];
}

- (BOOL) forceLoginOnFreshInstall { return s_forceLoginOnFreshInstall; }
- (void) setForceLoginOnFreshInstall: (BOOL) forceLoginOnFreshInstall {
	[MM_LoginViewController setForceLoginOnFreshInstall: forceLoginOnFreshInstall];
}

+ (void) setRedirectURI: (NSString *) redirectURI { s_redirectURI = redirectURI; }
+ (void) setLoginDomain: (NSString *) loginDomain {s_loginDomain = loginDomain; }
+ (NSString *) currentLoginDomain { return [[NSUserDefaults standardUserDefaults] stringForKey: DEFAULTS_LOGIN_DOMAIN]; }
+ (BOOL) isInSandbox { return [[self currentLoginDomain] containsCString: "test."]; }
+ (void) setRemoteAccessConsumerKey: (NSString *) remoteAccessConsumerKey { s_remoteAccessConsumerKey = remoteAccessConsumerKey; }
+ (void) setRemoteAccessSandboxConsumerKey: (NSString *) remoteAccessConsumerKey { s_remoteAccessSandboxConsumerKey = remoteAccessConsumerKey; }
+ (void) setRemoteAccessProductionConsumerKey: (NSString *) remoteAccessConsumerKey { s_remoteAccessProductionConsumerKey = remoteAccessConsumerKey; }

+ (BOOL) clearDataOnNewUser { return s_clearDataOnNewUser; }
+ (void) setClearDataOnNewUser: (BOOL) clearDataOnNewUser { s_clearDataOnNewUser = clearDataOnNewUser; }


+ (void) setForceLoginOnFreshInstall: (BOOL) forceLoginOnFreshInstall {
	if (s_forceLoginOnFreshInstall == forceLoginOnFreshInstall) return;
	s_forceLoginOnFreshInstall = forceLoginOnFreshInstall;
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey: DEFAULTS_HAS_LOGGED_IN_AT_LEAST_ONCE] && forceLoginOnFreshInstall) {
		[[MM_LoginViewController controller].credentials revokeRefreshToken];
		[MM_LoginViewController clearLoginState];
	}
}

+ (MM_LoginViewController *) presentModallyInParent: (UIViewController *) parent {
	[self controller].viewControllerToPresentIn = parent;
	if ([SA_ConnectionQueue sharedQueue].offline || [self controller].parentViewController || [MM_SyncManager sharedManager].isSyncInProgress) return nil;
	[self controller].presentingBarButtonItem = nil;
	dispatch_async_main_queue(^{ [[self controller] login]; });
	return [self controller];
}

+ (MM_LoginViewController *) presentFromBarButtonItem: (UIBarButtonItem *) item {
	if ([SA_ConnectionQueue sharedQueue].offline) return nil;
	[self controller].presentingBarButtonItem = item;
	dispatch_async_main_queue(^{ [[self controller] login]; });
	return [self controller];
}

+ (MM_LoginViewController *) currentController { return s_activeLoginController; }

+ (void) logout {
	if (!s_loggedIn) return;
	
	s_loggingOut = YES;
	[NSNotificationCenter postNotificationNamed: kNotification_WillLogOut];
	dispatch_async_main_queue(^{ [[self controller] logout]; });
}

+ (BOOL) isLoggingIn { return [self controller].isViewLoaded && [self controller].view.superview; }
+ (BOOL) isLoggedIn { return s_loggedIn; }
+ (BOOL) isAuthenticated { return s_authenticated; }
+ (BOOL) isLoggingOut { return s_loggingOut; }
+ (BOOL) isEnteringCredentials { return [self controller].view.window != nil; }


//================================================================================================================
#pragma mark Notifications

- (void) connectionStateChanged: (NSNotification *) note {
	if ([SA_ConnectionQueue sharedQueue].offline) {
		[self dismissViewControllerAnimated: YES completion: nil];
	} else {
		if (!s_loggedIn && ![SA_ConnectionQueue sharedQueue].offline) [MM_LoginViewController presentModallyInParent: nil];
	}
}

- (void) didFinishLaunching: (NSNotification *) note {
	[self login];
}

//=============================================================================================================================
#pragma mark - OAuth

- (void) setupLoginEnvironment {
	NSString				*redirectURI = s_redirectURI;
	NSString				*loginDomain = s_loginDomain;
	
	if (self.useTestServer) {
		redirectURI = [redirectURI stringByReplacingOccurrencesOfString: @"login." withString: @"test."];
		loginDomain = [loginDomain stringByReplacingOccurrencesOfString: @"login." withString: @"test."];
	}
	
	
	NSString				*clientID = s_remoteAccessConsumerKey;
	
	if (self.useTestServer && s_remoteAccessSandboxConsumerKey.length) clientID = s_remoteAccessSandboxConsumerKey;
	if (!self.useTestServer && s_remoteAccessProductionConsumerKey.length) clientID = s_remoteAccessProductionConsumerKey;

	[SFAuthenticationManager sharedManager].useSnapshotView = NO;
	[SFUserAccountManager sharedInstance].loginHost = loginDomain;
	[SFUserAccountManager sharedInstance].oauthClientId = clientID;
	[SFUserAccountManager sharedInstance].oauthCompletionUrl = redirectURI;
	[SFUserAccountManager sharedInstance].scopes = [NSSet setWithObjects:@"web", @"api", nil];
}

- (void) login {
    MMLog(@"%s", __FUNCTION__);
	[self setupLoginEnvironment];

//	if (self.presentingViewController) return;
	
	self.wasUIPresented = NO;

	if (s_redirectURI == nil || s_loginDomain == nil || (s_remoteAccessConsumerKey == nil && s_remoteAccessProductionConsumerKey == nil && s_remoteAccessSandboxConsumerKey == nil)) {
		[SA_AlertView showAlertWithTitle: @"MISSING VALUES" message: @"You must set the remoteAccessConsumerKey, redirectURI and loginDomain properties on the login controller before attempting to log in."];
		return;
	}
	
	if ([SA_ConnectionQueue sharedQueue].offline) {
		return;
	}

	[[SFAuthenticationManager sharedManager] loginWithCompletion:^(SFOAuthInfo *info) {
		
	} failure:^(SFOAuthInfo *info, NSError *error) {
        MMLog(@"SFAuthenticationManager failed to login, error: %@", error);
	}];
}

- (void) revokeAuthentication {
	if (!self.coordinator) return;
	if (self.credentials.accessToken) {
        MMLog(@"%@", @"Revoking refresh token");
        [self.credentials revokeRefreshToken];
    }
}

+ (void) handleFailedOAuth {
    MMLog(@"%s", __FUNCTION__);
	[[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_auth_failed];
	if (s_loggedIn) [self logout];
	//	[NSNotificationCenter postNotificationNamed: kNotification_WillLogOut];
	//  [s_activeLoginController revokeAuthentication];
	//	[NSNotificationCenter postNotificationNamed: kNotification_DidLogOut];
}

+ (void) clearLoginState {
    MMLog(@"%s", __FUNCTION__);
	[[self currentController].coordinator stopAuthentication];
	[[self currentController].coordinator revokeAuthentication];
	
	[MM_SyncManager sharedManager].oauthValidated = NO;
	//[MM_SyncManager sharedManager].hasSyncedOnce = NO;
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_CURRENT_INSTANCE_URL];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_CURRENT_IDENTITY_URL];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_CURRENT_ACCESS_TOKEN];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_FULL_USER_ID];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_SOAP_URL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_CURRENT_CLIENT_ID];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: DEFAULTS_REFRESH_TOKEN];

	[[NSUserDefaults standardUserDefaults] synchronize];
	s_loggedIn = NO;
	s_loggingOut = NO;
	s_authenticated = NO;
	[[NSUserDefaults standardUserDefaults] setBool: s_loggedIn forKey: DEFAULTS_CURRENTLY_LOGGED_IN];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[NSNotificationCenter postNotificationNamed: kNotification_DidLogOut];
}

- (void) logout {
    MMLog(@"%s", __FUNCTION__);
	[MM_LoginViewController clearLoginState];
	[NSObject performBlock: ^{
		[self performSelectorOnMainThread: @selector(login) withObject: nil waitUntilDone: NO];
	} afterDelay: 1.0];
}

#pragma mark - SFOAuthCoordinatorDelegate


- (void)authManagerWillBeginAuthWithView:(SFAuthenticationManager *)manager {
	
}

#if OS_70_BUILD
- (UIRectEdge) edgesForExtendedLayout { return UIRectEdgeNone; }
#endif

//- (void)authManagerDidStartAuthWebViewLoad:(SFAuthenticationManager *)manager {
- (void)authManager:(SFAuthenticationManager *)manager willDisplayAuthWebView:(UIWebView *)view {
	MMLog(@"%s", __FUNCTION__);

	self.wasUIPresented = YES;
	[self.authWebView removeFromSuperview];

	self.authWebView = view;
	
	[self presentLoginController];
	
	if (self.togglingServer) {
		self.togglingServer = NO;
	}
}

- (void) presentLoginController {
	UINavigationController			*nav = [[UINavigationController alloc] initWithRootViewController: self];
	
	nav.modalPresentationStyle = self.modalPresentationStyle;
	
	if (self.presentingViewController == nil && self.SA_PopoverController == nil) {
		if (self.viewControllerToPresentIn) {
			[self.viewControllerToPresentIn dismissViewControllerAnimated:NO completion:nil];
			[self.viewControllerToPresentIn presentViewController: nav animated: YES completion: nil];
		}
		else if (self.presentingBarButtonItem)
			[self presentSA_PopoverFromBarButtonItem: self.presentingBarButtonItem permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
	}
}

- (void) setAuthWebView: (UIWebView *) view {
	_authWebView = view;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview: view];
}

- (void)authManagerDidFail:(SFAuthenticationManager *)manager error:(NSError*)error info:(SFOAuthInfo *)info {
	[[SA_ConnectionQueue sharedQueue] hideActivityIndicator];
	
//    MMLog(@"%s, coordinator delegate: %@, error: %d, description: %@", __FUNCTION__, coordinator.delegate, error.code, error.localizedDescription);
	
	// 672 is com.salesforce.OAuth.ErrorDomain invalid_grant : expired access/refresh token.
    // This is pretty common, so we won't show the user
    // kSFOAuthErrorInvalidGrant = 672, kSFOAuthErrorAccessDenied = 669 ?!?
    if (error.code != kSFOAuthErrorInvalidGrant && error.code != kSFOAuthErrorAccessDenied && ![MM_LoginViewController isLoggedIn]) {
        MMLog(@"Error: %@", error);
        //similarly, if the user is already logged in, we're probably having a minor conenction issue, so let's not bug
		[self.loginErrorAlert dismissWithClickedButtonIndex: 0 animated: YES];
		
        /* Localized description of the error message */
        self.loginErrorAlert = [SA_AlertView showAlertWithTitle: NSLocalizedString(@"An Error Occurred While Authorizing", nil) message:[error localizedDescription]];
    }
	if (![MM_SyncManager sharedManager].hasSyncedOnce && !s_forceLoginOnFreshInstall) {
		[MM_LoginViewController setForceLoginOnFreshInstall: YES];
		[MM_LoginViewController setForceLoginOnFreshInstall: NO];
	}
	
	if (!s_loggingOut) {
		[NSNotificationCenter postNotificationNamed: kNotification_OAuthLoginFailed];
		s_loggedIn = NO;
		[[MM_LoginViewController currentController].coordinator revokeAuthentication];
		[self dismissViewControllerAnimated:NO completion:nil];
		
		// avoid "Exception: cannot authenticate with nil delegate"
		[self login];
	}
}

- (void)authManagerDidAuthenticate:(SFAuthenticationManager *)manager credentials:(SFOAuthCredentials *)credentials authInfo:(SFOAuthInfo *)info {
	BOOL					justLoggedIn = !s_loggedIn;
	
    MMLog(@"%s", __FUNCTION__);
	[NSNotificationCenter postNotificationNamed:kNotification_DidAuthenticate object: @(justLoggedIn)];
    
	[NSUserDefaults syncObject: self.credentials.domain forKey: DEFAULTS_LOGIN_DOMAIN];
	[NSUserDefaults syncObject: @([self.credentials.domain containsCString: "test."]) forKey: DEFAULTS_USE_SANDBOX];
	[NSUserDefaults syncObject: @(YES) forKey: DEFAULTS_HAS_LOGGED_IN_AT_LEAST_ONCE];
//	[SFUserAccountManager sharedInstance].coordinator = coordinator;
//	[SFUserAccountManager sharedInstance].credentials = self.credentials;
    [NSObject performBlock: ^{
        [[MM_LoginViewController controller] dismissViewControllerAnimated: YES completion:nil];
    } afterDelay: 0.0];
	s_loggedIn = YES;
	s_authenticated = YES;
	[[NSUserDefaults standardUserDefaults] setBool: s_loggedIn forKey: DEFAULTS_CURRENTLY_LOGGED_IN];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSString *prevUserID = [[NSUserDefaults standardUserDefaults] stringForKey: DEFAULTS_LAST_USER_ID];
	
	self.newUserLoggedIn = (prevUserID == nil || ![prevUserID isEqual: [SFOAuthCoordinator fullUserId]]);
	if (manager && self.newUserLoggedIn) {
        if ([MM_LoginViewController clearDataOnNewUser]) [[MM_ContextManager sharedManager] removeAllDataIncludingMetaData: YES withDelay: 0.0];
        [MM_SyncManager sharedManager].hasSyncedOnce = NO;
        [[MM_Config sharedManager] reset];
        [NSObject performBlock:^{
            [self completeLogin: justLoggedIn];
        } afterDelay: 1.0];
    } else
        [self completeLogin: justLoggedIn];
}

- (void)authManagerDidFinishAuthWebViewLoad:(SFAuthenticationManager *)manager {
	NSString						*title = [self.authWebView stringByEvaluatingJavaScriptFromString: @"document.title"];
	static const NSString			*checkScript = @"(document.title == \"salesforce.com - Forgot Password\" && document.getElementsByTagName('input').length == 0)";
	NSString						*result = [self.authWebView stringByEvaluatingJavaScriptFromString: (id) checkScript];
	[self.authWebView setAccessibilityLabel:@"DSA Login Page"];
    MMLog(@"%s", __FUNCTION__);
	if ([title containsCString: "Customer Secure Login Page"]) {
		if (self.preloadedUsername.length) [self.authWebView stringByEvaluatingJavaScriptFromString: $S(@"document.getElementById('username').value = '%@'", self.preloadedUsername)];
		if (self.preloadedPassword.length) [self.authWebView stringByEvaluatingJavaScriptFromString: $S(@"document.getElementById('password').value = '%@'", self.preloadedPassword)];
		if (!self.autofilledCredentials && self.preloadedUsername.length && self.preloadedPassword.length && !self.disableAutoLogin) {
			[self.authWebView performSelector: @selector(stringByEvaluatingJavaScriptFromString:) withObject: @"document.getElementsByClassName('loginButton')[0].click()" afterDelay: 2.5];
			self.autofilledCredentials = YES;
		}
	} else if (self.autofilledCredentials) {
		[self.authWebView stringByEvaluatingJavaScriptFromString: @"document.getElementsByClassName('btnPrimary btn allowBtn')[0].click()"];
	}
	if ([result isEqual: @"true"]) {
		[self performSelector: @selector(login) withObject: nil afterDelay: 10.0];
	}
	
	NSString *html = [self.authWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
	NSLog(@"raw HTML is %@", html);

}

- (void) completeLogin: (BOOL) justLoggedIn {
    MMLog(@"%s", __FUNCTION__);
	[[NSUserDefaults standardUserDefaults] setObject: [self.coordinator.credentials.instanceUrl absoluteString] forKey: DEFAULTS_CURRENT_INSTANCE_URL];
	[[NSUserDefaults standardUserDefaults] setObject: [self.coordinator.credentials.identityUrl absoluteString] forKey: DEFAULTS_CURRENT_IDENTITY_URL];
	[[NSUserDefaults standardUserDefaults] setObject: self.coordinator.credentials.accessToken forKey: DEFAULTS_CURRENT_ACCESS_TOKEN];
	[[NSUserDefaults standardUserDefaults] setObject: [SFOAuthCoordinator fullUserId] forKey: DEFAULTS_FULL_USER_ID];
	[[NSUserDefaults standardUserDefaults] setObject: [SFOAuthCoordinator fullUserId] forKey: DEFAULTS_LAST_USER_ID];
    [[NSUserDefaults standardUserDefaults] setObject: self.coordinator.credentials.clientId forKey: DEFAULTS_CURRENT_CLIENT_ID];
	[[NSUserDefaults standardUserDefaults] setObject: self.coordinator.credentials.refreshToken  forKey: DEFAULTS_REFRESH_TOKEN];

	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[MM_SFObjectDefinition setupSOAPURL];
	
	NSDictionary						*userInfo = $D(self.coordinator.credentials.accessToken, @"accessToken", 
													   self.coordinator.credentials.instanceUrl, @"instanceURL", 
													   @(self.wasUIPresented), LOGIN_UI_WAS_PRESENTED_KEY,
													   @(self.newUserLoggedIn), LOGIN_NEW_USER_LOGGED_IN_KEY
													);
	
	if (justLoggedIn)
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_DidLogIn object: nil userInfo: userInfo];

	if ([MM_LoginViewController controller] && self.presentingBarButtonItem) [NSObject performBlock: ^{
		[[self SA_PopoverController] dismissSA_PopoverAnimated: YES];
	} afterDelay: 0.0];
}

- (BOOL) popoverControllerShouldDismissPopover: (UIPopoverController *) popoverController {
	return self.canCancel;
}

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController {
}

//=============================================================================================================================
#pragma mark - LifeCycle

- (NSString *) title {
	return (self.useTestServer) ? NSLocalizedString(@"Login [Sandbox]", @"Login [Sandbox]") : NSLocalizedString(@"Login", @"Login");
}

- (void) setupBarButtonItems {
	if (self.serverToggleSwitch == nil) {
		self.serverToggleSwitch = [[UISwitch alloc] initWithFrame: CGRectZero];
		self.serverToggleSwitch.tintColor = [UIColor blackColor];
		[self.serverToggleSwitch addTarget: self action: @selector(toggleServer:) forControlEvents: UIControlEventValueChanged];
	}
	
	self.serverToggleSwitch.on = self.useTestServer;
	
	self.navigationItem.leftBarButtonItem = (!self.canCancel || self.presentingBarButtonItem) ? nil : [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancel:)];
	if (self.canToggleServer) {
		UILabel						*label = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 100, 40)];
		
		label.backgroundColor = [UIColor clearColor];
		label.text = NSLocalizedString(@"Use\n Sandbox", @"Use\n Sandbox");
		label.textAlignment = NSTextAlignmentRight;
		label.lineBreakMode = NSLineBreakByWordWrapping;
		label.numberOfLines = 2;
		label.font = [UIFont boldSystemFontOfSize: 12];
		label.textColor = [UIColor blackColor];
		self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: [UIBarButtonItem itemWithView: self.serverToggleSwitch], [UIBarButtonItem itemWithView: label], nil];
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (void) viewWillAppear: (BOOL) animated {
	[self setupBarButtonItems];
	self.autofilledCredentials = NO;
	[super viewWillAppear: animated];
	//[self.loginErrorAlert dismissWithClickedButtonIndex: 0 animated: YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LoginViewControllerWillDismiss object:nil];
}


- (void) viewDidAppear: (BOOL) animated {
	[super viewDidAppear: animated];
	
	[self.view addSubview: self.authWebView];
	self.authWebView.frame = self.view.bounds;
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_LogInViewDidAppear object: nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	BOOL justLoggedIn = !s_loggedIn;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LoginViewControllerDidDismiss object:@(justLoggedIn)];
    [super viewDidDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation { return RUNNING_ON_IPAD || UIInterfaceOrientationIsPortrait(interfaceOrientation); }

- (void) setCanCancel: (BOOL) canCancel {
	_canCancel = canCancel;
	[self setupBarButtonItems];
}

- (void) setCanToggleServer: (BOOL) canToggleServer {
	_canToggleServer = canToggleServer;
	[self setupBarButtonItems];
}

- (BOOL) canToggleServer { return NO; }

//================================================================================================================
#pragma mark - Properties

- (UIViewController *) viewControllerToPresentIn {
	if (_viewControllerToPresentIn) return _viewControllerToPresentIn;
	
	NSArray				*windows = [UIApplication sharedApplication].windows;
	UIWindow			*base = windows.count ? windows[0] : nil;
	
	return base.rootViewController;
}

- (SFOAuthCoordinator *) coordinator { return [SFAuthenticationManager sharedManager].coordinator; }
- (SFOAuthCredentials *) credentials { return [SFAuthenticationManager sharedManager].coordinator.credentials; }


//- (SFOAuthCoordinator *) coordinator {
//	if (!self.coordinator || self.coordinator.credentials.clientId.length == 0) {
//		NSString				*redirectURI = s_redirectURI;
//		NSString				*loginDomain = s_loginDomain;
//		
//		if (self.useTestServer) {
//			redirectURI = [redirectURI stringByReplacingOccurrencesOfString: @"login." withString: @"test."];
//			loginDomain = [loginDomain stringByReplacingOccurrencesOfString: @"login." withString: @"test."];
//		}
//		
//		NSString				*clientID = s_remoteAccessConsumerKey;
//		
//		if (self.useTestServer && s_remoteAccessSandboxConsumerKey.length) clientID = s_remoteAccessSandboxConsumerKey;
//		if (!self.useTestServer && s_remoteAccessProductionConsumerKey.length) clientID = s_remoteAccessProductionConsumerKey;
//		
//		
//		[SFUserAccountManager sharedInstance].oauthClientId = clientID;
//        [SFUserAccountManager sharedInstance].oauthCompletionUrl = redirectURI;
//        [SFUserAccountManager sharedInstance].scopes = [NSSet setWithObjects:@"web", @"api", nil];
//		_coordinator = [SFAuthenticationManager sharedManager].coordinator;
//		_credentials = [SFAuthenticationManager sharedManager].coordinator.credentials;
//		
////		self.credentials = [[SFOAuthCredentials alloc] initWithIdentifier: s_currentAccountIdentifier clientId: clientID encrypted: NO];
////		self.credentials.domain = loginDomain;
////		self.credentials.redirectUri = redirectURI;
////		
////		_coordinator = [[SFOAuthCoordinator alloc] initWithCredentials: self.credentials];
////        _coordinator.scopes = [NSSet setWithObjects:@"web",@"api",nil];
////		_coordinator.delegate = self;
//	}
//    
//	return _coordinator;
//}

- (void) setUseTestServer: (BOOL) useTestServer {
	_useTestServer = useTestServer;
	[NSUserDefaults syncObject: @(useTestServer) forKey: DEFAULTS_USE_SANDBOX];
	self.navigationItem.title = self.title;
}

- (void) setPrefersTestServer: (BOOL) prefersTestServer {
	if (![[NSUserDefaults standardUserDefaults] hasValueForKey: DEFAULTS_USE_SANDBOX]) self.useTestServer = prefersTestServer;
}

//================================================================================================================
#pragma mark - Actions

- (IBAction) cancel: (id) sender {
	[self dismissViewControllerAnimated: YES completion: nil];
}

- (IBAction) toggleServer: (id) sender {
    MMLog(@"%s", __FUNCTION__);
	self.useTestServer = self.serverToggleSwitch.on;
//	self.togglingServer = YES;
//	self.view.alpha = 0.5;
//	self.view.userInteractionEnabled = NO;
//	self.serverToggleSwitch.userInteractionEnabled = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SandboxSwitchToggled object: sender];
	
	[self dismissViewControllerAnimated: YES completion:^{
		[self setupLoginEnvironment];
		[[SFUserAccountManager sharedInstance] switchToNewUser];
		dispatch_after_main_queue(0.0, ^{
		//	[self presentLoginController];
//			[self.coordinator performSelector: @selector(stopAuthentication) withObject: nil];
//			
//			[self.coordinator performSelector: @selector(beginUserAgentFlow) withObject: nil];
		});
	}];
}

@end

#pragma mark -

@implementation SFOAuthCoordinator (MMFramework)

+ (NSString *) currentClientId { return [SFUserAccountManager sharedInstance].oauthClientId; }
+ (NSString *) refreshToken { return [SFAuthenticationManager sharedManager].coordinator.credentials.refreshToken; }
+ (NSString *) currentAccessToken { return [SFAuthenticationManager sharedManager].coordinator.credentials.accessToken; }
+ (NSURL *) currentInstanceURL { return [SFAuthenticationManager sharedManager].coordinator.credentials.instanceUrl; }
+ (NSURL *) currentIdentityURL { return [SFAuthenticationManager sharedManager].coordinator.credentials.identityUrl; }
+ (NSString *) fullUserId { return [SFAuthenticationManager sharedManager].coordinator.credentials.userId.longSalesforceID; } //	return [[NSUserDefaults standardUserDefaults] stringForKey: DEFAULTS_FULL_USER_ID];
+ (NSString *) userAgent{
    if([SFRestAPI userAgentString]) return ([SFRestAPI userAgentString]);
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"UserAgent"];
}


//- (NSString *) fullUserId { return [SFAuthenticationManager sharedManager].coordinator.credentials.identityUrl.path.lastPathComponent; }
@end
