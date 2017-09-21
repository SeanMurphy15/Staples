//
//  RS_AppDelegate.m
//  RESTStarter
//
//  Created by Ben Gottlieb on 10/2/12.
//  Copyright (c) 2012 Model Metrics. All rights reserved.
//

#import "RS_AppDelegate.h"
#import "RS_ObjectTableViewController.h"

@implementation RS_AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self addAsObserverForName: kNotification_DidLogIn selector: @selector(loginComplete:)];
	[self addAsObserverForName: kNotification_SyncBegan selector: @selector(syncBegan:)];
	[self addAsObserverForName: kNotification_SyncComplete selector: @selector(syncComplete:)];
	[self addAsObserverForName: kNotification_SyncCancelled selector: @selector(syncCancelled:)];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
	
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController: [RS_ObjectTableViewController controllerWithObject: @"Account" displayField: @"Name"]];
    [self.window makeKeyAndVisible];
	
	[self logIn];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void) logIn {
	[MM_LoginViewController setRedirectURI: kOAuthRedirectURI];
	[MM_LoginViewController setLoginDomain: kOAuthLoginDomain];
	[MM_LoginViewController setRemoteAccessConsumerKey: kRemoteAccessConsumerKey];
    
	
	MM_LoginViewController			*controller = [MM_LoginViewController presentModallyInParent: self.window.rootViewController];
    
    //controller.useTestServer = YES;
    //controller.forceLoginOnFreshInstall = YES;
	controller.canToggleServer = YES;

	controller.canCancel = NO;
    
	//controller.preloadedUsername = @"cat360alex@modelmetrics.com.demo";
}

//=============================================================================================================================
#pragma mark Notifications
- (void) syncBegan: (NSNotification *) note {
	dispatch_async(dispatch_get_main_queue(), ^{
		[SA_PleaseWaitDisplay showPleaseWaitDisplayWithMajorText: @"Synchronzing…" minorText: @"" cancelLabel: nil showProgressBar: NO delegate: nil];
	});
}

- (void) syncComplete: (NSNotification *) note {
	[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
}

- (void) syncCancelled: (NSNotification *) note {
	[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
}

- (void) loginComplete: (NSNotification *) note {
	[self performSync];
}

- (void) performSync {
	if ([SA_ConnectionQueue sharedQueue].offline) {
		[SA_AlertView showAlertWithTitle: @"No Internet Connection" message: @"Sorry, you can't sync while offline"];
		return;
	}
	
	simpleBlock			fetchAndSyncBlock = ^{
		[[MM_SyncManager sharedManager] fetchRequiredMetaData: NO withCompletionBlock: ^{
			[[MM_SyncManager sharedManager] synchronize: nil withCompletionBlock: nil];
		}];
	};
	
	if (![[MM_OrgMetaData sharedMetaData] isMetadataAvailableForObjects: nil]) {
		[[MM_SyncManager sharedManager] downloadObjectDefinitionsWithCompletionBlock: fetchAndSyncBlock];
	} else {
		fetchAndSyncBlock();
	}
}
@end
