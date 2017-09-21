//
//  NSData+SA_AdditionsTests.m
//  RESTLibrary
//
//  Created by Jayaprakash Manchu on 12/27/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <SA_Base/NSData+SA_Additions.h>

@interface NSData_SA_AdditionsTests : XCTestCase {
    
}

@end

@implementation NSData_SA_AdditionsTests

/* The setUp method is called automatically before each test-case method (methods whose name starts with 'test').
 */
- (void) setUp {
    // uncaught and the app crashes upon a failed STAssert (oh well).
    // [self raiseAfterFailure];
    self.continueAfterFailure = NO;
}

/* The tearDown method is called automatically after each test-case method (methods whose name starts with 'test').
 */
- (void) tearDown {
    NSLog(@"%@ tearDown", self.name);
}

- (void)testDataWithNil {
    NSData *data =[NSData dataWithString:nil];
    XCTAssertNil(data, @"Data object should be Nil");
}

- (void)testDataNotNil {
    NSData *data =[NSData dataWithString:@"xyz"];
    XCTAssertNotNil(data, @"Data object should not be Nil");
}

- (void)testDataStringRendering {
    NSData *data =[NSData dataWithString:@"xyz"];
    XCTAssertTrue([[data stringValue] isEqualToString:@"xyz"], @"Failed to get back the string.!");
}

- (void)testDataWithBase64Encoding {
    NSString *dataString = @"xyz";
    NSData *data = [NSData dataWithString:dataString];
    NSString *base64EncString = [data SA_base64Encoded];
    XCTAssertNotNil(base64EncString, @"Base64Encoded string should not be nil");
    NSData *dataWithEncodedData = [NSData dataWithBase64EncodedString:base64EncString];
    XCTAssertEqualObjects(data, dataWithEncodedData, @"Data objects should be equal!");
    XCTAssertTrue([[dataWithEncodedData stringValue] isEqualToString:dataString], @"Base64 Encoding & decoding are not functioning!");
    XCTAssertEqualObjects([dataWithEncodedData SA_base64Encoded], base64EncString, @"Base64Encoded strings should be equal!");
}

- (void)testIsXml {
    NSString *testXMLstring = @"<?xml version=\"<root><sub><physics></sub><sub>maths</sub></root>";
    NSData *data = [NSData dataWithString:testXMLstring];
    XCTAssertTrue([data appearsToBeXML], @"Failed to detect xml input");
    
    testXMLstring = @"<root><sub><physics></sub><sub>maths</sub></root>";
    data = [NSData dataWithString:testXMLstring];
    XCTAssertFalse([data appearsToBeXML], @"Failed to detect non-xml input");
}

@end
