//
//  REST_LoginTest.m
//  RESTLibrary
//
//  Created by Amisha Goyal on 12/18/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "REST_LoginTest.h"
#import <SalesforceSDKCore/SFUserAccountManager.h>
//#import <SalesforceOAuth/SFOAuthCoordinator.h>
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import <SalesforceSDKCore/SFAuthenticationManager.h>
#import <SalesforceSDKCore/SFAuthenticationViewHandler.h>
#import "MM_Notifications.h"

#import <objc/runtime.h>
#import <objc/message.h>

@interface MM_SFObjectDefinition (unittests)
+ (void) setupSOAPURL;
@end
@implementation MM_SFObjectDefinition (unittests)
+ (void) setupSOAPURL {
}
@end

@implementation MM_SyncManager (unittests)
+ (void)initialize {}
@end

//FIXME
//@interface SFAccountManager (fullKeychainIdentifier)
//+ (NSString *) fullKeychainIdentifier: (NSString *) accountIdentifier;
//@end

@interface MM_LoginViewController ()
+ (MM_LoginViewController *) controller;

@property (nonatomic, strong) SFOAuthCoordinator *coordinator;
@property (nonatomic, weak) UIViewController *presentingParentViewController;
@property (nonatomic, weak) UIBarButtonItem *presentingBarButtonItem;
@property (nonatomic, weak) UIWebView *authWebView;
@property (nonatomic, weak) id <UIWebViewDelegate> authWebViewDelegate;
@property (nonatomic) BOOL togglingServer, newUserLoggedIn;

- (IBAction) cancel: (id) sender;
- (IBAction) toggleServer: (id) sender;

- (void) logout;
- (void) login;
- (void) setupBarButtonItems;
@end


@implementation REST_LoginTest {
    Method origButtonSetup;
    Method mockButtonSetup;
}

- (void)mockButtonSetup {
    //NSLog(@"Doing nothing instead of adding buttons to the screen.");
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    origButtonSetup = class_getInstanceMethod([MM_LoginViewController class], @selector(setupBarButtonItems));
	mockButtonSetup = class_getInstanceMethod([self class], @selector(mockButtonSetup));
	method_exchangeImplementations(origButtonSetup, mockButtonSetup);
    loginViewController = [MM_LoginViewController presentModallyInParent:nil];
}

-(void)testControllerFunction{
    /*
     Testing the + (MM_LoginViewController *) controller function to be called and executed.
     */
    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
    BOOL canCancel = controller.canCancel;
    XCTAssertTrue(canCancel, @"controller function failed");
}


-(void)testControllerCredentialFunction{
    /*
     Testing the + (MM_LoginViewController *) controller function to be called and executed.
     */

//FIXME
//    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
//    NSString *credentialIdentifier = controller.credentialsIdentifier;
//    NSString *defaultCredIdentifier = [SFAccountManager fullKeychainIdentifier: @"Default"];
//    STAssertEqualObjects(credentialIdentifier,defaultCredIdentifier,@"Mismatch in credentialIdentifier");
    
}

-(void)testControllerDebugFunction{
	//FIXME this functionality has been temporarily removed, so cannot be tested
    /*
     Testing the + (MM_LoginViewController *) controller function to test debug/release mode.
     */
//    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
//    BOOL canToggle = controller.canToggleServer;
//    STAssertTrue(canToggle, @"Release mode"); //Expecting this to be true if in DEBUG
}


-(void)testPresentModallyInParentControllerClass{
    UIViewController *controller = [MM_LoginViewController presentModallyInParent:nil];
    BOOL isOfLoginClass = [controller isKindOfClass:[MM_LoginViewController class]];
    XCTAssertTrue(isOfLoginClass, @"Returning lofinView controller of a different class");
}

-(void)testpresentFromBarButtonItemControllerClass{
    UIViewController *controller = [MM_LoginViewController presentFromBarButtonItem:nil];
    BOOL isOfLoginClass = [controller isKindOfClass:[MM_LoginViewController class]];
    XCTAssertTrue(isOfLoginClass, @"Returning loginViewController of a different class");
}

-(void)testCurrentControllerFunction{
    UIViewController *controller = [MM_LoginViewController currentController];
    BOOL isOfLoginClass = [controller isKindOfClass:[MM_LoginViewController class]];
    XCTAssertTrue(isOfLoginClass, @"Current Controller Function Failed");
}

 -(void)testOAuthDidAuthenticateDelegateFunction{
     MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
	 [controller authManagerDidAuthenticate: nil credentials: nil authInfo: nil];
 //    [controller oauthCoordinatorDidAuthenticate:nil authInfo:nil];
     BOOL isLoggedInTest = [MM_LoginViewController isLoggedIn];
     XCTAssertTrue(isLoggedInTest, @"OAuthDidAuthenticate Failed to set s_loggedIn to TRUE");
 }

-(void)testClassLogout{
    BOOL isLoggingOut = [MM_LoginViewController isLoggingOut];
    XCTAssertFalse(isLoggingOut, @"Shouldn't be logging out if not already logged in.");

	[loginViewController authManagerDidAuthenticate: nil credentials: nil authInfo: nil];
 //   [loginViewController oauthCoordinatorDidAuthenticate:nil authInfo:nil];
    [MM_LoginViewController logout];
    
    isLoggingOut = [MM_LoginViewController isLoggingOut];
    XCTAssertTrue(isLoggingOut, @"Should be logging out");
}

/*
-(void)testpopoverControllerDidDismissPopover{
    
    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
    [controller performSelector:@selector(popoverControllerDidDismissPopover:) withObject:@"dummyObject"];
    UIViewController *loginController = [MM_LoginViewController currentController];
    STAssertNil(loginController, @"PopoverControllerDidDismissPopover delegate failed");
}
*/

- (void)testWillLogoutNotification {
    [loginViewController authManagerDidAuthenticate: nil credentials: nil authInfo: nil];
    id mock = [OCMockObject observerMock];
    // OCMock adds a custom methods to NSNotificationCenter via a category
    [[NSNotificationCenter defaultCenter] addMockObserver:mock
                                                     name:kNotification_WillLogOut
                                                   object:nil];
    [[mock expect] notificationWithName:kNotification_WillLogOut object:[OCMArg any]];
    [MM_LoginViewController logout];    
    [mock verify];
}

-(void)testToggleserver{
	//FIXME functionality currently disabled
//    SFOAuthCredentials * testCreds = [[SFOAuthCredentials alloc] initWithIdentifier:@"test" clientId:@"test" encrypted:NO];
//    SFOAuthCoordinator * coord = [[SFOAuthCoordinator alloc] initWithCredentials:testCreds];
//    id mockCoordinator = [OCMockObject partialMockForObject:coord];
//    [[mockCoordinator expect] authenticate];
//    [[mockCoordinator expect] stopAuthentication];
//    
//    id mock = [OCMockObject partialMockForObject:loginViewController];
//    [[[mock stub] andReturn:coord] coordinator];
//    
//    [loginViewController performSelector:@selector(toggleServer:) withObject:@"sender"];
//    [mockCoordinator verify];
}

-(void)testCanCancel{
    id mock = [OCMockObject partialMockForObject:loginViewController];
    [[mock expect] setupBarButtonItems];
   // [loginViewController performSelector:@selector(setCanCancel:)];
    loginViewController.canCancel=YES;
    [mock verify];
}

-(void)testCanToggleServer{
    id mock = [OCMockObject partialMockForObject:loginViewController];
    [[mock expect] setupBarButtonItems];
    // [loginViewController performSelector:@selector(setCanCancel:)];
    loginViewController.canToggleServer=YES;
    [mock verify];
}

-(void)testViewWillAppear{
    id mock = [OCMockObject partialMockForObject:loginViewController];
    [[mock expect] setupBarButtonItems];
    [loginViewController performSelector:@selector(viewWillAppear:)];
    [mock verify];
}
/*
 -(void)testCoordinatorDidFailWithError{
 id mock = [OCMockObject partialMockForObject:loginViewController];
 loginViewController.coordinator = [[SFOAuthCoordinator alloc] init];
 [[mock expect] login];
 // [loginViewController performSelector:@selector(setCanCancel:)];
 [loginViewController performSelector:@selector(oauthCoordinator:didFailWithError:) withObject:nil withObject:[NSError errorWithDomain:@"Domain" code:100 userInfo:nil]];
 [mock verify];
 
 }
 */

-(void)testTitleForSandbox{
    loginViewController.canToggleServer=0;
    loginViewController.useTestServer=1;
    NSString *titleString = loginViewController.title;
    NSLog(@"title string :%@",titleString);
    XCTAssertEqualObjects(titleString, @"Login [Sandbox]", @"Title returning wrong value for sandbox mode");
}

-(void)testTitle{
    loginViewController.canToggleServer=0;
    loginViewController.useTestServer=0;
    NSString *titleString = loginViewController.title;
    NSLog(@"title string :%@",titleString);
    XCTAssertEqualObjects(titleString, @"Login", @"Title returning wrong value for normal mode");
}


- (void)tearDown
{
    // Tear-down code here.
    method_exchangeImplementations(mockButtonSetup, origButtonSetup);

    [super tearDown];
}
@end
