//
//  SOQL_LoginTest.m
//  SOQLBrowser
//
//  Created by Amisha Goyal on 12/4/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "SOQL_LoginTest.h"
#import "SFAccountManager.h"

@interface SFAccountManager (fullKeychainIdentifier)
+ (NSString *) fullKeychainIdentifier: (NSString *) accountIdentifier;
@end

@implementation SOQL_LoginTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

-(void)testControllerFunction{
    /*
     Testing the + (MM_LoginViewController *) controller function to be called and executed.
     */
    
    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
    BOOL canCancel = controller.canCancel;
    STAssertTrue(canCancel, @"controller function failed");
}

-(void)testControllerCredentialFunction{
    /*
     Testing the + (MM_LoginViewController *) controller function to be called and executed.
     */
    
    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
    NSString *credentialIdentifier = controller.credentialsIdentifier;
    NSString *defaultCredIdentifier = [SFAccountManager fullKeychainIdentifier: @"Default"];
    STAssertEqualObjects(credentialIdentifier,defaultCredIdentifier,@"controller function failed");

}

-(void)testControllerDebugFunction{
    /*
     Testing the + (MM_LoginViewController *) controller function to test debug/release mode.
     */
    
    MM_LoginViewController	*controller = [MM_LoginViewController presentModallyInParent:nil];
    BOOL canToggle = controller.canToggleServer;
    STAssertTrue(canToggle, @"Testing in release mode");
}


- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

@end
