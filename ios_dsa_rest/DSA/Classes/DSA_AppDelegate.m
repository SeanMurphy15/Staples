//
//  DSA_AppDelegate.m
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright Stand Alone, Inc. 2010. All rights reserved.
//

#import "DSA_AppDelegate.h"
#import "MM_Notifications.h"
#import "MM_SyncManager.h"
#import "MM_Config.h"
#import "DSARestClient.h"
#import "MM_Log.h"
#import "MMSF_ContentDocument.h"
#import "UIView+DSA_Additions.h"
#import "DSA_RemoteObjectStatusClient.h"
#import "DSA_ObjectUpdatedStatusView.h"
#import "MM_SOQLQueryString.h"
#import "MMSF_ContentVersion.h"
#import "MMSF_User.h"
#import "MMSF_Contact.h"
#import "MMSF_Lead.h"
#import "DSA_CellularDataDefender.h"
#import "DSA_BaseTabsViewController.h"
#import "DSA_Defines.h"
#import "DSA_ProgressView.h"
#import <SA_Base/SA_AlertView.h>
#import <Crashlytics/Crashlytics.h>
#import "Branding.h"
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFAuthErrorHandlerList.h>
#import <SalesforceSDKCore/SFAuthErrorHandler.h>
#import <SalesforceCommonUtils/SFLogger.h>
#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"
#import "DSA_AppLaunchEvent.h"

@import Fabric;

#ifdef ORG_CUSTOM_PREFIX
#define OCPVAL ORG_CUSTOM_PREFIX
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define ORG_CUSTOM_PREFIX_STRING @ STRINGIZE2(OCPVAL)
#endif

#define         ZKS_TESTING             0

#define DEMO_TIME_LIMIT_KEY         @"firstLaunch"
#define DEMO_TIME_LIMIT_DAYS        30

@interface DSA_AppDelegate()

@property (nonatomic, strong) MMSF_Contact *currentTrackingContact;

- (void)checkForContentUpdates;
- (void)showStatusNofitication;
- (void)adaptAppearanceForMac:(MMSF_MobileAppConfig__c *)mac;

@end

@implementation DSA_AppDelegate

static void uncaughtExceptionHandler(NSException *exception) {
    MMLog(@"Exception: %@", exception);
}

- (void) dealloc {
	[self removeAsObserver];
}

DSA_AppDelegate     *g_appDelegate = nil;

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
+ (void)initialize {
    [SA_ConnectionQueue sharedQueue];
    
    [[DSA_CellularDataDefender sharedInstance] setOptions:(AlertOptionWarnAboutCellularDataWhenAvailable |
                                                           AlertOptionWarnAboutWifiForFullSync |
                                                           AlertOptionRequireWifiForInitialSync |
                                                           AlertOptionRequireCellularFileSizeLimit)];
}


///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (id) init {
    if ((self = [super init])) {
        g_appDelegate = self;
        
        [DSARestClient sharedInstance];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didAuthenticate:)
                                                     name: kNotification_DidAuthenticate //posted every time coordinator authenticates
                                                   object: nil];
		
		
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(userLoggedOut:)
                                                     name: kNotification_DidLogOut
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(loginCompleted:)
                                                     name: kNotification_LoginComplete
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(connectionStateChanged:)
                                                     name: kNotification_ConnectionStatusChanged
                                                   object: nil];
        
		[self addAsObserverForName: kNotification_SyncComplete selector: @selector(syncCompleted:)];
		
        [self addAsObserverForName: kNotification_SA_ErrorWhileGeneratingFetchRequest selector: @selector(fetchRequestError:)];
        [self contentItemHistory];
        
        [MM_SyncManager sharedManager].maxSimultaneousConnections = 1;
        [self addAsObserverForName: kNotification_OAuthCredsExpired selector: @selector(oauthCredsExpired)];
        
        _contentUpdateCheckQueue = [[NSOperationQueue alloc] init];
        _contentUpdateCheckQueue.maxConcurrentOperationCount = 1;
        _contentUpdateCheckQueue.name = @"com.iosdsa.contentcheck.queue";
        
		[MM_SyncManager sharedManager].useAtomicSync = YES;
    }
    
    return self;
}

- (void) loginCompleted:(NSNotification*)note
{
    SFAlertViewDismissBlock dismissBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        [DSA_ProgressView hide];
    };
    
    
    // If the user is logging in for the first time, ensure that a Wi-Fi network connection exists for the required
    // initial full sync.
    
    MMSF_Object *user = [[MM_SyncManager currentUserInContext: nil] valueForKey: @"Id"];
    BOOL isNewUser = [[note.userInfo objectForKey: LOGIN_NEW_USER_LOGGED_IN_KEY] boolValue] || user == nil;
    BOOL hasNeverSynced = ![MM_SyncManager sharedManager].hasSyncedOnce;
    
    if (isNewUser && hasNeverSynced && [[DSA_CellularDataDefender sharedInstance] willAlertAboutInitialSyncWithDismissBlock: dismissBlock])
        return;

    [[DSARestClient sharedInstance] connectWithSalesForce:note];
    
#if DEBUG
    // add user email to Crashlytics
    [Crashlytics setUserEmail:[MMSF_User currentUser][@"Email"]];
#endif
}

- (void)connectionStateChanged:(NSNotification *)notification {
    if ([MM_LoginViewController isLoggedIn] &&
        ![MM_LoginViewController isAuthenticated] &&
        ![SA_ConnectionQueue sharedQueue].offline) {
        [self login];
    }
}

- (void) fetchRequestError: (NSNotification *) note {
    MMLog(@"fetchRequestError: %@", note.object);
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) showDSAUserOrg {
    
#ifdef ORG_CUSTOM_PREFIX
    //[SF_Entity setOrgCustomPrefix: ORG_CUSTOM_PREFIX_STRING];
#endif
    //[SF_Category setDSAAppContentMode: NO];
    
#if 1
    //NSString* appSuppDir = privateDocumentsPath();
    
    //have to leave the support dir literal here for now as the shared code has the app name appended and requires it
    
    //[SF_Store setupStoreWithDocumentsDirectory: appSuppDir andApplicationSupportDirectory: appSuppDir];
#else
    NSArray* paths =  NSSearchPathForDirectoriesInDomains (NSDocumentDirectory,NSUserDomainMask,YES);
    
    //have to leave the support dir literal here for now as the shared code has the app name appended and requires it
    
    //[SF_Store setupStoreWithDocumentsDirectory: [[paths objectAtIndex:0] stringByExpandingTildeInPath] andApplicationSupportDirectory: [@"~/Library/Application Support/Sales Aid/" stringByExpandingTildeInPath]];
#endif
    
    if (g_appDelegate.baseViewController == nil) g_appDelegate.baseViewController = [[DSA_BaseTabsViewController alloc] init];
    
    if (self.window.rootViewController != g_appDelegate.baseViewController) {
        if (self.introViewController) {
            if (g_appDelegate.baseViewController.navigationController != self.introViewController)
                [self.introViewController pushViewController: g_appDelegate.baseViewController animated: YES];
        } else {
            self.window.rootViewController = g_appDelegate.baseViewController;
        }
    }
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) applicationWillEnterForeground: (UIApplication *) application {
    [[SA_ConnectionQueue sharedQueue] determineConnectionLevelAvailable];
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) checkDemoTimeLimit
{
#if TIME_LIMITED_DEMO
    NSDate* firstLaunch = [[NSUserDefaults standardUserDefaults] objectForKey:DEMO_TIME_LIMIT_KEY];
    if (firstLaunch == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:DEMO_TIME_LIMIT_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        NSDate* now = [NSDate date];
        
        NSInteger numDays;
        NSUInteger unitFlags = NSDayCalendarUnit;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:firstLaunch toDate:now options:0];
        numDays = [components day];
        
        if (numDays > 30)
        {
            demoExpiredAlert = [[UIAlertView alloc] initWithTitle:@"Demo expired"
                                                          message:@"Your 30 day Digital Sales Aid demo period has ended. Please contact Salesforce Services. for the full version."
                                                         delegate:self
                                                cancelButtonTitle:@"Exit"
                                                otherButtonTitles:nil];
            [demoExpiredAlert show];
        }
    }
#endif
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Crashlytics
	[Fabric with:@[[Crashlytics class]]];
 //   [Crashlytics startWithAPIKey:@"85cd5936488988b6a08f1c71064802d6aea4ec3f"];
 //   [Crashlytics sharedInstance].debugMode = NO;
    
    [NewRelicAgent startWithApplicationToken:@"AAf38f5a63de4da26ec831f1cb0e68bd4001734b84"];
    
    // background fetch interval (Never = disabled)
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
	
//	[[Crashlytics sharedInstance] crash];
	
    [self setLoginParameters];
    
    [self stylizeUIAppearance];

    self.enableDocumentTrackingWithoutCheckIn = YES;
    
    NSString* isFirstRun =  [[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"];
    
    if(isFirstRun == nil)
    {
        [MM_LoginViewController logout];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"FirstRun"];
    }
    
#if !DISABLE_DSA_LOGGING
    [MM_Log sharedLog].currentLogLevel = MM_LOG_LEVEL_LOW;
#endif
    
    [SA_ConnectionQueue sharedQueue].managePleaseWaitDisplay = NO;
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
#if SHOW_MEMORY_STATUS
    [SA_MemoryDisplayView showMemoryView];
#endif
    
    // [self setupStore];
    
    self.baseViewController = [[DSA_BaseTabsViewController alloc] init];
    self.window.rootViewController = self.baseViewController;
    
    [self updateNavBarForInternalMode];
    
    [_window makeKeyAndVisible];
    
    //IF_DEBUG([SA_MemoryDisplayView showMemoryView]);
#if SHOPPING_CART_SUPPORT
    [self updateCartBadge: nil];
#endif
    
    
    if ([MM_Log zombieEnabled]) {
        CATextLayer             *zombieLayer = [CATextLayer layer];
        zombieLayer.bounds = CGRectMake(0, 0, 1024 * 1.25, 1024);
        zombieLayer.string = @"          ZOMBIES\n          ZOMBIES\n          ZOMBIES\n          ZOMBIES\n          ZOMBIES\n          ZOMBIES";
        zombieLayer.fontSize = 150;
        zombieLayer.wrapped = YES;
        zombieLayer.backgroundColor = [UIColor redColor].CGColor;
        zombieLayer.opacity = 0.15;
        zombieLayer.position = CGPointMake(self.window.bounds.size.width / 2, self.window.bounds.size.height / 2);
        zombieLayer.zPosition = 1;
        [self.window.rootViewController.view.layer addSublayer: zombieLayer];
    }
    
    if([[MMSF_User currentUser] isLoggedIn]) {
        [self login];
    } else {
        if ([[UIDevice currentDevice] connectionType] == connection_none) {
            [SA_AlertView showAlertWithTitle: @"You're not connected to the network, and will be unable to log in." message: nil];
            
#if (USE_MODAL_LOGIN || USE_POPOVER_LOGIN)
            self.baseViewController.selectedIndex = 0;
#else
            self.baseViewController.selectedIndex = 1;
#endif
        } else {                                                            //no valid creds, show the login screen
#if USE_MODAL_LOGIN
            [self.baseViewController presentModalViewController: [ZM_LoginViewController splashController] animated: NO];
#endif
        }
    }
    
    [self preventSDKErrorAlerts];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BOOL handled = NO;
    
    MMLog(@"Opening url: %@ from application: %@", url, sourceApplication);

    if ([[url scheme] isEqualToString:@"sfdcdsa"]) {
        NSString *queryString = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        queryString = [queryString lowercaseString];
        NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *queryInfo = [NSMutableDictionary dictionaryWithCapacity:queryComponents.count];
        for (NSString *component in queryComponents) {
            NSArray *params = [component componentsSeparatedByString:@"="];
            queryInfo[params[0]] = params[1];
        }
        
        // open content
        // sfdcdsa://opencontent?contentid=06930000003sHWw, where 06930000003sHWw is the Content Document Id
        if ([[url host] isEqualToString:@"opencontent"]) {
            NSString *idString = queryInfo[@"contentid"];
            if (idString) {
                MMSF_ContentVersion *content = [MMSF_ContentVersion versionMatchingDocumentID:idString inContext:nil];
                if (content) {
                    DSA_MediaDisplayViewController* mediaVC = [DSA_MediaDisplayViewController controllerForItem:content withDelegate:self.baseViewController];
                    [self.baseViewController presentViewController:mediaVC animated:YES completion:nil];
                    handled = YES;
                } else {
                    MMLog(@"Content ID not found:, %@", idString);
                    [SA_AlertView showAlertWithTitle:@"Content Not Found" message:@"Linked content was not found on this device. Sync now?" buttons:@[@"Cancel", @"Sync Now"] buttonBlock:^(NSInteger buttonIndex) {
                        if (buttonIndex == 1) {
                            [[DSARestClient sharedInstance] deltaSync];
                        }
                    }];
                }
            } else {
                MMLog(@"Opening url with query, %@, not supported", queryInfo);
            }
        } else {
            MMLog(@"Opening url, %@, not supported", url);
        }
    } else if ([[url scheme] isEqualToString:@"staplesdsa"] && [[url pathComponents] count] == 2) {
        NSString *host = [url host];
        NSString *sfID = url.pathComponents[1];
        MM_ManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;

        if ([host isEqualToString:@"contact"]) {
            MMSF_Contact *contact = [moc anyObjectOfType: [MMSF_Contact entityName] matchingPredicate: $P(@"Id == %@", sfID)];

            if (contact) {
                [self startDocumentTrackingForContact:contact];

                [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ContactCheckedIn object:sfID];
                handled = YES;
            } else {
                [SA_AlertView showAlertWithTitle:@"Contact Not Found"
                                         message:@"The Contact you are attempting to check in with is not yet synchronized with the DSA.  Please synchronize the DSA and try again."
                                         buttons:@[@"OK"]
                                     buttonBlock:nil];
            }
        } else if ([host isEqualToString:@"lead"]) {
            MMSF_Lead *lead = [moc anyObjectOfType: [MMSF_Lead entityName] matchingPredicate: $P(@"Id == %@", sfID)];

            if (lead) {
                [self startDocumentTrackingForLead:lead];

                [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_LeadCheckedIn object:sfID];
                handled = YES;
            } else {
                [SA_AlertView showAlertWithTitle:@"Lead Not Found"
                                         message:@"The Lead you are attempting to check in with is not yet synchronized with the DSA.  Please synchronize the DSA and try again."
                                         buttons:@[@"OK"]
                                     buttonBlock:nil];
            }
        }
    }

    return handled;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    MMLog(@"%s", __PRETTY_FUNCTION__);
    [self.contentUpdateCheckQueue cancelAllOperations];
}

- (void)logVersionInfo {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    MMLog (@"%@, Version %@ (%@)", info[@"CFBundleDisplayName"], info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]);
    
#if TARGET_IPHONE_SIMULATOR
    // log the arcane iOS 8 app and Private Documents path
    MMLog(@"Bundle path: %@", [NSBundle mainBundle].bundlePath);
    
    NSURL *libraryUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *privateDocumentsPath = [libraryUrl.absoluteString stringByAppendingPathComponent:@"Private Documents"];
    MMLog(@"Private Documents path: %@", privateDocumentsPath);
#endif
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    MMLog(@"%s", __PRETTY_FUNCTION__);
    [self logVersionInfo];
    
    [DSA_AppLaunchEvent triggerEventAfterDelay:30];
    
    if([[MM_SyncManager sharedManager] hasSyncedOnce]
       && ![SA_ConnectionQueue sharedQueue].offline
       && ![[MM_SyncManager sharedManager] isSyncInProgress]
       //&& [[SFNetworkEngine sharedInstance] isReachable]
       && ![[SFAuthenticationManager sharedManager] authenticating]) {
        MMLog(@"%@", @"applicationDidBecomeActive: logging in");
        
        [self login];
	}
}

- (void)applicationWillResignActive:(UIApplication *)application {
    MMLog(@"%s", __PRETTY_FUNCTION__);
    [self.contentUpdateCheckQueue cancelAllOperations];    
}

- (void) applicationWillTerminate: (UIApplication *) application {
    MMLog(@"%s", __PRETTY_FUNCTION__);
    [self.contentUpdateCheckQueue cancelAllOperations];
}

#pragma mark - Actions

- (void) setLoginParameters {
    [MM_LoginViewController setForceLoginOnFreshInstall: YES];
    [MM_LoginViewController setRedirectURI:kOAuthRedirectURI];
    [MM_LoginViewController setLoginDomain:kOAuthLoginDomain];
    [MM_LoginViewController setRemoteAccessConsumerKey:kRemoteAccessConsumerKey];
}

- (void)preventSDKErrorAlerts {
    SFAuthErrorHandler * generic = [[SFAuthenticationManager sharedManager] genericAuthErrorHandler];
    SFAuthErrorHandlerList * list = [[SFAuthenticationManager sharedManager] authErrorHandlerList];
    if ([list authErrorHandlerInList:generic]) {
        [list removeAuthErrorHandler:generic];
    }
    
    SFAuthErrorHandler * defaultHandler = [[SFAuthErrorHandler alloc] initWithName:@"DSADefaultHandler"
                                                                         evalBlock:^BOOL(NSError *error, SFOAuthInfo *authInfo) {
                                                                             NSLog(@"Caught DSADefaultHandler error: %@ %@",error,authInfo);
                                                                             return YES;
    }];
    [list addAuthErrorHandler:defaultHandler];
    
    [[SFAuthenticationManager sharedManager] setAuthErrorHandlerList:list];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) login {
    MM_LoginViewController          *controller = [MM_LoginViewController presentModallyInParent:self.baseViewController];
    
#if DEBUG
    controller.prefersTestServer = NO;
    controller.canToggleServer = YES;
#else
    controller.prefersTestServer = NO;
    controller.canToggleServer = YES;
#endif
    controller.canCancel = NO;
    //   controller.useTestServer = YES;
}


/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) logout {
    [[MMSF_User currentUser] setIsLoggedIn:NO];
    [MMSF_User setCurrentUser:nil];
    
    [MM_LoginViewController logout];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    for (UINavigationController *controller in self.baseViewController.viewControllers) {
        if ([controller respondsToSelector: @selector(popToRootViewControllerAnimated:)]) [controller popToRootViewControllerAnimated: NO];
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (IBAction) confirmLogOut: (id) sender {
    NSString                    *title = @"Are you sure you want to log out?";
    UIAlertView                 *alert = [[UIAlertView alloc] initWithTitle: title message: nil delegate: self cancelButtonTitle: @"Cancel" otherButtonTitles: @"Log Out", nil];
    
    [alert show];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
#if TIME_LIMITED_DEMO
    if (demoExpiredAlert != nil)
    {
        exit(0);
    }
#endif
    
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [self logout];
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (IBAction) refreshUserWithConfirmation {
    connection_type             connectionType = [[UIDevice currentDevice] connectionType];
    
    switch (connectionType) {
        case connection_none:
        {
            [SA_AlertView showAlertWithTitle: @"You must be connected to the internet to sync." message: @""];
        }
            break;
            
        case connection_wan:
        {
            [SA_AlertView showAlertWithTitle: @"You are attempting to sync through a non-WiFi connection which could result in additional charges. Continue?"  message: nil button: @"Continue" buttonBlock: ^(BOOL cancelHit) {
                if (cancelHit) {
                    //if (![SF_User currentUser].isLoggedIn) exit(0);
                } else
                    [self performSelector: @selector(refreshUser:) withObject: nil afterDelay: 0.1];
            }];
        }
            break;
            
            
        case connection_lan:
        {
            [self refreshUser: nil];
        }
            break;
            
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (IBAction) refreshUser: (id) sender
{
    if ([[UIDevice currentDevice] connectionType] == connection_none) {
        [SA_AlertView showAlertWithTitle: @"Sorry, you can't reload your SalesForce data while offline." message: @""];
        return;
    }
}

#pragma mark - Properties

- (UINavigationController *) topNavigationController {
    if (self.baseViewController.selectedViewController == nil) return self.introViewController.navigationController;
    
    UINavigationController      *nav = (UINavigationController *) self.baseViewController.selectedViewController;
    
    if ([nav isKindOfClass: [UINavigationController class]]) return nav;
    return nil;
}

#pragma mark - Notifications

- (void) syncCompleted: (NSNotification *) note {
	[[MM_SFObjectDefinition objectNamed: @"Contact" inContext: nil] refreshDescribeLayout];
	[[MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil] refreshDescribeLayout];
}

- (void)didAuthenticate:(NSNotification*)note {
	NSLog(@"didAuthenticate");
    
#if TIME_LIMITED_DEMO
	[self checkDemoTimeLimit];
#endif
    
    if (![MM_SyncManager sharedManager].hasSyncedOnce) {
        return;
    }
    
    // check if the DSA was upgraded, refreshing metadata if needed
    BOOL refreshing = [[DSARestClient sharedInstance] refreshMetaDataIfNeeded];
    if (!refreshing) {
        BOOL contentUpdateCheckRunning = self.contentUpdateCheckQueue.operationCount > 0;
        if (contentUpdateCheckRunning == NO) {
            MMLog(@"%@", @"Checking for interrupted sync...");
            BOOL shouldResume = [[MM_SyncManager sharedManager] shouldSyncResume];
            if (shouldResume && !contentUpdateCheckRunning ) {
                MMLog(@"%@", @"Resuming sync...");
                [[DSARestClient sharedInstance] deltaSync];
            } else {
                MMLog(@"%@", @"Checking for updated content");
                [self checkForContentUpdates];
            }
        }
    }
}

#if SHOPPING_CART_SUPPORT
- (void) updateCartBadge: (NSNotification *) note {
    UITabBarItem            *cartItem = [[self.baseViewController.viewControllers objectAtIndex: 3] tabBarItem];
    NSInteger                     count = [[SF_Store store].context numberOfObjectsOfType: [SF_ContentItem entityName]
                                                                  matchingPredicate: $P(@"currentlyInCart == YES")];
    
    cartItem.badgeValue = count ? $S(@"%d", count) : nil;
    
}
#endif

- (void) oauthCredsExpired {
    [self performSelectorOnMainThread: @selector(login) withObject: nil waitUntilDone: NO];
}

- (void) incorrectCredentials: (NSNotification *) note {
    [SA_AlertView showAlertWithTitle: @"Sorry, these credentials weren't recognized." message: note.object ? [note.object description] : @"Please double check them and try again."];
    [DSA_ProgressView hide];
}

- (ContentItemHistory*) contentItemHistory {
    if (_contentItemHistory == nil) {
        _contentItemHistory = [[ContentItemHistory alloc] init];
    }
    
    return _contentItemHistory;
}

#pragma mark - Document Tracking

//- (void) setTrackingContact:(MMSF_Contact*)contact {
//    self.currentTrackingContact = contact;
//    if (contact) {
//        self.isTrackingContact = YES;
//    }
//}

- (MMSF_Contact*)trackingContactInContext:(NSManagedObjectContext *)context {
    if (!context) {
        context = [MM_ContextManager sharedManager].threadContentContext;
    }
    // return the Contact on the Context
    MMSF_Contact *contact = [self.currentTrackingContact objectInContext:context];
    
    return contact;
}

- (void) startDocumentTrackingForContact:(MMSF_Contact*) documentTrackingContact {
    //  if (!self.enableDocumentTrackingWithoutCheckIn && !self.checkinContact) return;
    self.currentTrackingType = documentTrackingContact ? DocumentTracking_SelectedContact : DocumentTracking_DeferredContact;
    self.currentTrackingEntity = documentTrackingContact;

    self.documentTracker = [[DocumentTracker alloc] init];
}

- (void) startDocumentTrackingForLead: (MMSF_Lead *) lead {
    
    self.currentTrackingType = lead ? DocumentTracking_SelectedLead : DocumentTracking_DeferredLead;
    self.currentTrackingEntity = lead;
    self.documentTracker = [[DocumentTracker alloc] init];
}

- (void) setEnableDocumentTrackingWithoutCheckIn: (BOOL) enableDocumentTrackingWithoutCheckIn {
    _enableDocumentTrackingWithoutCheckIn = enableDocumentTrackingWithoutCheckIn;
    
    if (_enableDocumentTrackingWithoutCheckIn) {
        if (self.documentTracker == nil) {
            self.documentTracker = [[DocumentTracker alloc] init];
        }
        if (self.currentTrackingType == DocumentTracking_None) {
            self.currentTrackingType = DocumentTracking_AlwaysOn;
        }
    } else {
        if (self.currentTrackingType == DocumentTracking_AlwaysOn) {
            self.currentTrackingType = DocumentTracking_None;
            if (self.documentTracker) [self stopDocumentTrackingForEntity: nil];
        }
    }
}



/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) stopDocumentTrackingForEntity: (MMSF_Object *) entity {
    
    if (self.enableDocumentTrackingWithoutCheckIn) {
        self.currentTrackingType = DocumentTracking_AlwaysOn;
    } else {
        self.currentTrackingType = DocumentTracking_None;
    }
    self.documentTracker = nil;
    self.currentTrackingEntity = nil;
    //self.isTrackingContact = NO;
    
    if (self.currentTrackingType == DocumentTracking_AlwaysOn) {
        self.documentTracker = [[DocumentTracker alloc] init];
    }
}

- (BOOL) isTrackingDocuments {
    return (self.documentTracker != nil);
}

#pragma mark -

/////////////////////////////////////////////
//
/////////////////////////////////////////////
- (MMSF_MobileAppConfig__c*) selectedMobileAppConfig			//FIXME: should probably pass in a context
{
    MMSF_MobileAppConfig__c * mac = nil;
    
    if (![MM_LoginViewController isLoggedIn] || [MM_LoginViewController isLoggingOut]) return nil;

	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;

    NSString* configObjectId = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultKey_selectedMobileAppConfig];
    if (configObjectId != nil) {
		mac = [moc anyObjectOfType:@"MobileAppConfig__c" matchingPredicate:[NSPredicate predicateWithFormat:@"Id == %@",configObjectId]];
        [self adaptAppearanceForMac:mac];
    }
    
    return mac;
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) userLoggedOut:(NSNotification*) notification
{
    [self clearCurrentUser];
}

///////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////
- (void) syncCanceledForIncompatibleOrg: (NSNotification *) note
{
    [[SA_ConnectionQueue sharedQueue] cancelAllConnections];
    [DSA_ProgressView hide];
    [self logout];
    [SA_AlertView showAlertWithTitle: @"Salesforce.com App Package Required" message: @"Digital Sales Aid requires the Salesforce.com AppExchange package to be installed. Please contact your Salesforce.com Administrator."];
}

-(void) clearCurrentUser
{
    //[[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserDefaultKey_selectedMobileAppConfig];
    [[MMSF_User currentUser] setIsLoggedIn:NO];
    [MMSF_User setCurrentUser:nil];
}

///////////////////////////////////////////////////////
// Toggles the tintColor for the "main" toolbar
///////////////////////////////////////////////////////

- (void)updateNavBarForInternalMode {
    
    BOOL isInternalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
    
    if (isInternalMode) {
        
        self.baseViewController.view.layer.borderColor = [UIColor redColor].CGColor;
        self.baseViewController.view.layer.borderWidth = 2.0f;
        
    } else {
        
        self.baseViewController.view.layer.borderWidth = 0.0f;
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (BOOL) inInternalMode
{
    BOOL isInternalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
    return isInternalMode;
}
#pragma mark - Private Methods

- (BOOL)shouldStartContentUpdateCheck {
    BOOL shouldStart = [self shouldCheckForContentUpdates];
    NSTimeInterval timeSinceLastUpdateCheck = [[DSA_RemoteObjectStatusClient lastCheckDate] timeIntervalSinceNow];
    
   if (fabsf(timeSinceLastUpdateCheck) < 20.0) {
        // just finished checking for updates
        shouldStart = NO;
    }
    
    return shouldStart;
}

- (BOOL)shouldCheckForContentUpdates {
    BOOL shouldCheck = YES;
    NSTimeInterval timeSinceLastSync = [[MM_Config sharedManager].lastSyncDate timeIntervalSinceNow];
    
    if (![MM_SyncManager sharedManager].hasSyncedOnce) {
        shouldCheck = NO;
    } else if (![MM_LoginViewController isLoggedIn] || [MM_LoginViewController isLoggingIn]) {
        shouldCheck = NO;
    } else if ([[MM_SyncManager sharedManager] isSyncInProgress]) {
        shouldCheck = NO;
    } else if ([DSA_RemoteObjectStatusClient hasBeenNotifed]) {
        shouldCheck = NO;
    } else if (![DSA_RemoteObjectStatusClient lastCheckDate]) {
        shouldCheck = NO;
    //} else if (![[SFNetworkEngine sharedInstance] isReachable]) {
    //    shouldCheck = NO;
    } else if (fabsf(timeSinceLastSync) < 90.0) {
        // just finished sync in the last 90 seconds
        shouldCheck = NO;
    }
    
    return shouldCheck;
}

// avoid a traffic jam
- (BOOL)shouldDeferContentUpdates {
    BOOL shouldDefer = NO;
    
    if ([MM_SFChange isPushingChanges]) {
        // pushing Content Reviews
        shouldDefer = YES;
    }
    
    return shouldDefer;
}

- (void)checkForContentUpdates {
    
    /**
     * In order to make the most efficent query for updated content there has
     * to be two serial calls.
     *
     * The queries check for updated ContentVersion and Content_Cat_Junction objects,
     * which should only be applicable to content updates/creations for a given
     * library. For Hoa Kula, the library is DSA Approved.
     *
     * Because we have to query CoreData it blocks the main thread thus slowing 
     * the start of the application. I pop this off on global background queue.
     * The check for updated content is returned on the main queue.
     *
     * NOTE: This will need to be thought through for other ORGS.
     *
     * @todo
     * Would be better if this serial fetch was done instance method
     */
    
    if(![self shouldStartContentUpdateCheck]) return;
    
    if ([self shouldDeferContentUpdates]) {
        [self performSelector:@selector(checkForContentUpdates) withObject:nil afterDelay:15.0];
        return;
    }
    
    /**
     * Even though the app should check for content updates (passes check above)
     * the auth token _might_ have expired and we need to refresh that token.
     *
     * If you don't then all mobile configs become inactive.
     */
    MMLog(@"%s", __PRETTY_FUNCTION__);
    
    NSBlockOperation *contentCheckOp = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = contentCheckOp;
    MM_SyncManager *syncManager = [MM_SyncManager sharedManager];
    
    if (!syncManager.oauthValidated) {
		[syncManager validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) { [self checkForContentUpdates]; }];
		return;
	}
    
    [contentCheckOp addExecutionBlock:^{
        if (weakOperation.isCancelled) {
            return;
        }
        
        MM_SOQLQueryString *contentVersionQueryString = [MMSF_ContentVersion baseQueryIncludingData:NO];
        MM_SOQLQueryString *catJunctionQueryString    = [MMSF_Cat_Content_Junction__c baseQueryIncludingData:NO];
        
        contentVersionQueryString.lastModifiedDate = [DSA_RemoteObjectStatusClient lastCheckDate];
        catJunctionQueryString.lastModifiedDate    = [DSA_RemoteObjectStatusClient lastCheckDate];
        
        MMLog(@"contentVersionQueryString lastDate: %@", contentVersionQueryString.lastModifiedDate);
        MMLog(@"catJunctionQueryString lastDate: %@", catJunctionQueryString.lastModifiedDate);
        
        DSA_RemoteObjectStatusClient *statusClientCV = [[DSA_RemoteObjectStatusClient alloc] initWithObjectName:@"ContentVersion"];
        DSA_RemoteObjectStatusClient *statusClientCJ = [[DSA_RemoteObjectStatusClient alloc] initWithObjectName:MNSS(@"Cat_Content_Junction__c")];
        
        [statusClientCV checkForUpdatesUsingSOQL:contentVersionQueryString success:^(BOOL hasUpdate, MM_RestOperation *operation, id jsonResponse){
            
            MMVerboseLog(@"query string for content version: %@", contentVersionQueryString);
            
            if(![self shouldCheckForContentUpdates]) return;
            
            if (hasUpdate) {
                [self showStatusNofitication];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDSANewContentAvailableNotificationKey
                                                                    object:nil];
                statusClientCV.notified = YES;
                
            } else {
                MMLog(@"%@", @"no updates for ContentVersion");
               
                /**
                 * If there aren't any updated ContentVersion objects then we'll
                 * check for ContentDocument which _should_ return any new docs
                 * that have been created, but not assigned.
                 */
                
                [statusClientCJ checkForUpdatesUsingSOQL:catJunctionQueryString success:^(BOOL hasUpdate, MM_RestOperation *operation, id jsonResponse){
                    
                    MMVerboseLog(@"query string for cat junction: %@", catJunctionQueryString);
                    
                    if(![self shouldCheckForContentUpdates]) return;
                    
                    if (hasUpdate) {
                        [self showStatusNofitication];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kDSANewContentAvailableNotificationKey
                                                                            object:nil];
                        statusClientCV.notified = YES;
                    } else {
                        MMLog(@"%@", @"no updates for CatContentJunctions");

                        /**
                         * If there aren't any updated ContentVersion objects then we'll
                         * check for ContentDocument which _should_ return any new docs
                         * that have been created, but not assigned.
                         */
                    }
                } error:^(MM_RestOperation *operation, NSError *error, id jsonResponse){
                    MMLog(@"request: %@ error: %@", operation, error);
                }];
            }
            
        } error:^(MM_RestOperation *operation, NSError *error, id jsonResponse){
            MMLog(@"request: %@ error: %@", operation, error);
        }];
    }];
    
    [self.contentUpdateCheckQueue addOperation:contentCheckOp];
}

- (void)showStatusNofitication {
    CGFloat selectedViewWidth = self.baseViewController.selectedViewController.view.frame.size.width;
    CGRect statusFrame        = {0, -STATUSVIEWHEIGHT, selectedViewWidth, STATUSVIEWHEIGHT};
    
    DSA_ObjectUpdatedStatusView *statusView = [[DSA_ObjectUpdatedStatusView alloc] initWithFrame:statusFrame];
    
    __block BOOL statusViewRemoved = NO;
    
    void (^removeFromSuperViewAction)(void) = ^{
        [statusView removeFromSuperview];
        statusViewRemoved = YES;
    };
    
    [statusView setTapActionWithBlock:^{
        removeFromSuperViewAction();
    }];
    
    [self.baseViewController.selectedViewController.view addSubview:statusView];

    [UIView animateWithDuration: 0.8f animations:^{
         CGRect updatedFrame = statusFrame;
         
         updatedFrame.origin.y = 0.0f;
         
         statusView.frame = updatedFrame;
         statusView.alpha = 0.8f;
    } completion:^(BOOL finished){
         /**
          * A user can immediately remove the banner view by tapping on it. Because
          * of this you have to check and make sure that it hasn't been removed
          * before you try and finish the completion block.
          */

         if (!statusViewRemoved) {
             if (finished) {
                 [UIView animateWithDuration:0.8f delay:0.7f options:UIViewAnimationOptionCurveEaseIn animations:^{
                      CGRect updatedFrame = statusFrame;
                      
                      updatedFrame.origin.y = -STATUSVIEWHEIGHT;
                      statusView.frame = updatedFrame;
                      statusView.alpha = 0.0f;
                  }
                  completion:^(BOOL finish){
                      removeFromSuperViewAction();
                  }];
             }
         }
     }];
}

- (void)adaptAppearanceForMac:(MMSF_MobileAppConfig__c *)mac {
    if (mac) {
        //[UINavigationBar appearance].barTintColor = mac.titleBarColor;
        //[UINavigationBar appearance].tintColor = mac.titleTextColor;
        //[UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName : mac.titleTextColor};
    }
}

- (void) stylizeUIAppearance {
    
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor: [Branding blueColor]];
    [[UINavigationBar appearanceWhenContainedIn: [UIPopoverController class], nil] setTintColor: [Branding blueColor]];
}

@end
