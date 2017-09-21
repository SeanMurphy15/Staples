//
//  SB_AppDelegate.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/21/11.
//  Copyright (c) 2011 Stand Alone, Inc. All rights reserved.
//

#import "SB_AppDelegate.h"
#import "SB_ObjectListViewController.h"
#import "SB_RecordListViewController.h"
#import "MM_Headers.h"
#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"

SB_AppDelegate *g_appDelegate = nil;

#define			USE_TEST_SERVER					NO

//6/21/12
#define				TEST_USER						@"timmodelmetrics@cepheid.com"
#define				TEST_PASSWORD					@"model200"

//5/3/12
//#define				TEST_USER						@"bgottlieb@modelmetrics.com.dpsg"
//#define				TEST_PASSWORD					@"model100"

//12-12-11
//#define			TEST_USER						@"sderen@catdigital.demo"
//#define			TEST_PASSWORD					@"model100"

//11-30-11
//#define			TEST_USER						@"bgottlieb@modelmetrics.com.mining"
//#define			TEST_PASSWORD					@"model100"

//11-21-11
//#define			TEST_USER						@"bgottlieb.dsa@modelmetrics.com"
//#define			TEST_PASSWORD					@"model200"

//11-19-11
//#define			TEST_USER						@"tgersic+mmtestcontentall@modelmetrics.com.zimmer"
//#define			TEST_PASSWORD					@"model300"

@implementation SB_AppDelegate

@synthesize window = _window, accesstoken, instanceurl;

- (id) init {
	if ((self = [super init])) {
		g_appDelegate = self;
	}
	return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[MM_ContextManager sharedManager];
	[self restoreOrgMetaData];
	[self addAsObserverForName: kNotification_OrgSyncObjectsChanged selector:  @selector(saveOrgMetaData)];
	[self addAsObserverForName: kNotification_LoginComplete selector: @selector(loggedIn:)];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	if (RUNNING_ON_IPAD) {
		UISplitViewController		*controller = [[UISplitViewController alloc] init];
		controller.viewControllers = @[ [SB_ObjectListViewController controller], [SB_RecordListViewController wrappedController] ];
		controller.delegate = self;
		self.window.rootViewController = controller;
	} else {	
		self.window.rootViewController = [SB_ObjectListViewController controller];
	}
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
	
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

- (void) presentLoginScreenFromBarButtonItem: (UIBarButtonItem *) item {
	[MM_LoginViewController setRedirectURI: kOAuthRedirectURI];
	[MM_LoginViewController setLoginDomain: kOAuthLoginDomain];
	[MM_LoginViewController setRemoteAccessConsumerKey: kRemoteAccessConsumerKey];

	if (item && RUNNING_ON_IPAD)
		[MM_LoginViewController presentFromBarButtonItem: item];
	else
		[MM_LoginViewController presentModallyInParent: self.window.rootViewController];

	[MM_LoginViewController currentController].useTestServer = USE_TEST_SERVER;
//	[MM_LoginViewController currentController].preloadedUsername = TEST_USER;
//	[MM_LoginViewController currentController].preloadedPassword = TEST_PASSWORD;
}

- (void) saveOrgMetaData {
	[[NSUserDefaults standardUserDefaults] setObject: [MM_OrgMetaData sharedMetaData].objectsToSync forKey: @"objectsToSync"];
}

- (void) restoreOrgMetaData {
	NSArray				*list = [[NSUserDefaults standardUserDefaults]  objectForKey: @"objectsToSync"];
	
	[[MM_OrgMetaData sharedMetaData] setAllObjectsToSync: list];
}

//=============================================================================================================================
#pragma mark Split View Delegate
- (BOOL) splitViewController: (UISplitViewController*) svc shouldHideViewController: (UIViewController *) vc inOrientation: (UIInterfaceOrientation) orientation {
	return NO;
}

//=============================================================================================================================
#pragma mark 
- (void) loggedIn: (NSNotification *) note {
	NSManagedObjectContext	*moc = [MM_ContextManager sharedManager].contentContextForWriting;
	if (![moc.persistentStoreCoordinator.managedObjectModel.entitiesByName objectForKey: @"Attachment"]) return;
	if (![moc.persistentStoreCoordinator.managedObjectModel.entitiesByName objectForKey: @"Account"]) return;
	

	MMSF_Object				*att = [moc anyObjectOfType: @"Attachment" matchingPredicate: nil];
	
//	if (att) {
//		MM_RestOperation	*op = [MM_RestOperation postOperationWithSalesforceID: att.Id pushingData: [NSData dataWithString: @"Goodbye"] ofMimeType: @"text/text" toField: @"Body" onObjectType: @"Attachment" completionBlock: ^(NSError *error, NSData *results) {
//			LOG(@"Error: %@", error);
//		}];
//		[[MM_SyncManager sharedManager] queueOperation: op];
//		return;
//	}
	
	if (att == nil || 1) {
		att = [moc insertNewEntityWithName: @"Attachment"];
		[att beginEditing];
		[att setValue: [[moc anyObjectOfType: @"Account" matchingPredicate: nil] Id] forKey: @"ParentId"];
		[att setValue: [NSData dataWithString: @"Holy Crap!"] forKey: @"Body"];
		[att setValue: @"Spartacus 3" forKey: @"Name"];
		[att finishEditingSavingChanges: YES andPushingToServer: NO];
	}
//	MM_RestOperation		*op = [MM_RestOperation operationToCreateObject: att completionBlock: nil];
//	
//	[[MM_SyncManager sharedManager] queueOperation: op];
}

@end
