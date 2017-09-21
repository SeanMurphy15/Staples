//
//  MM_LoginViewController.h
//
//  Created by Ben Gottlieb on 11/13/11.
//  Copyright 2011 Model Metrics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SFOAuthCoordinator.h"


@interface MM_LoginViewController : UIViewController <SFOAuthCoordinatorDelegate, UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UISwitch *serverToggleSwitch;

@property (nonatomic) BOOL canCancel;				//can the user cancel this? If not, there will be no cancel button on iPhone, and the user won't be able to cancel by tapping outside a popover on iPad 
@property (nonatomic) BOOL canToggleServer;			//show the Dev switch to toggle between Production and Sandbox servers
@property (nonatomic) BOOL useTestServer;			//should we hit Prod or Sandbox initially
@property (nonatomic, strong) NSString *preloadedPassword, *preloadedUsername;	//used when testing, allows you to pre-fill the username and password fields in the web form
@property (nonatomic, strong) NSString *credentialsIdentifier;	//defaults to the application identifier; used to distinguish credentials from one another. Generally leave it alone
@property (nonatomic) BOOL wasUIPresented;			//was any UI presented in a -login call?
@property (nonatomic, readonly) BOOL newUserLoggedIn;	//is the just-logged-in user different from the last user?
@property (nonatomic) BOOL prefersTestServer;		//set this to use the test server if one has not already been chosen
@property (nonatomic) BOOL forceLoginOnFreshInstall;			//just calls the static methods
@property (nonatomic, weak) SA_AlertView *loginErrorAlert;

+ (MM_LoginViewController *) presentModallyInParent: (UIViewController *) parent;
+ (MM_LoginViewController *) presentFromBarButtonItem: (UIBarButtonItem *) item;
+ (MM_LoginViewController *) currentController;
+ (void) logout;
+ (BOOL) isLoggingIn;				//is the user in the process of logging in?
+ (BOOL) isLoggedIn;
+ (BOOL) isEnteringCredentials;		//is the login screen visible
+ (BOOL) isAuthenticated;
+ (BOOL) isInSandbox;				//right now, this just checks to see if the URL contains "test.". Probably need a more robust way to do this
+ (BOOL) isLoggingOut;
+ (NSString *) currentLoginDomain;

+ (void) setupUserAgent;
+ (void) handleFailedOAuth;
+ (void) setRedirectURI: (NSString *) redirectURI;
+ (void) setLoginDomain: (NSString *) loginDomain;
+ (void) setRemoteAccessConsumerKey: (NSString *) remoteAccessConsumerKey;
+ (void) setRemoteAccessSandboxConsumerKey: (NSString *) remoteAccessConsumerKey;
+ (void) setRemoteAccessProductionConsumerKey: (NSString *) remoteAccessConsumerKey;
+ (void) setForceLoginOnFreshInstall: (BOOL) force;		//if the user is installing a fresh copy (ie, they deleted beforehand), require a new login
+ (BOOL) clearDataOnNewUser;
+ (void) setClearDataOnNewUser: (BOOL) clearDataOnNewUser;
- (void) clearLoginState;
@end



@interface SFOAuthCoordinator (MMFramework)
@property (nonatomic, readonly) NSString *fullUserId;

+ (NSString *) refreshToken;
+ (NSString *) userAgent;
+ (NSString *) currentClientId;
+ (NSString *) fullUserId;
+ (NSString *) currentAccessToken;
+ (NSURL *) currentInstanceURL;
+ (NSURL *) currentIdentityURL;
@end