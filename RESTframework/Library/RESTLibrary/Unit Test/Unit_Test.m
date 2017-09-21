//
//  Unit_Test.m
//  Unit Test
//
//  Created by Amisha Goyal on 12/20/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "Unit_Test.h"
#import <OCMock/OCMock.h>



@implementation Unit_Test

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
   // STFail(@"Unit tests are not implemented yet in Unit Test");
}
- (void)testOCMockPass {
    id mock = [OCMockObject mockForClass:NSString.class];
    [[[mock stub] andReturn:@"mocktest"] lowercaseString];
    NSString *returnValue = [mock lowercaseString];
    XCTAssertEqualObjects(@"mocktest", returnValue, @"Should have returned the expected string.");
}

-(void)testOfflineCheck{
    
    BOOL offline;
    int i=  [UIDevice currentDevice].connectionType;
    if(i>0){
        offline = NO;
    }else
        offline = YES;
    
    BOOL connection = [SA_ConnectionQueue sharedQueue].offline;
    XCTAssertEqual(connection,offline, @"offline");
    
}

@end
