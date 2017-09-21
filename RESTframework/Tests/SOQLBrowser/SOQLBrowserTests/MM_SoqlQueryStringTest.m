//
//  MM_SoqlQueryStringTest.m
//  SOQLBrowser
//
//  Created by Ajay Hegde on 10/26/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "MM_SoqlQueryStringTest.h"
#import <objc/runtime.h>
#import <objc/message.h>
@implementation MM_SoqlQueryStringTest

- (void)setUp
{
    [super setUp];
    queryStringObject = [[MM_SOQLQueryString alloc] init];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testqueryWithObjectName
{
    
    id query = [MM_SOQLQueryString queryWithObjectName:@"Account"];
    NSString *querystring = [NSString  stringWithFormat:@"%@",query];
    STAssertEqualObjects(querystring,@"MM_SOQLQuery: SELECT  FROM Account" , @"query failed");
}

- (void)testDetokenizedString {
    NSString * stringWithToken = @"test//token//testtest";
    NSString * deToken = [MM_SOQLQueryString detokenizedSOQLString:stringWithToken];
    STAssertNotNil(deToken, @"Returned string should not be nil");
    STAssertTrue([deToken rangeOfString:@"token"].location == NSNotFound,@"Original token should not exist in returned string");
    
    NSString * badString = @"testtokentesttest";
    deToken = [MM_SOQLQueryString detokenizedSOQLString:badString];
    STAssertEquals(badString, deToken, @"Initial string should be returned");
    
    badString = nil;
    deToken = [MM_SOQLQueryString detokenizedSOQLString:badString];
    STAssertEquals(badString, deToken, @"Initial string should be returned");
}

- (void)testDetokenizedStringCurrentUser {
    Method origMethod = class_getClassMethod([MM_SOQLQueryString class], @selector(replacementForToken:));
	Method mockMethod = class_getInstanceMethod([self class], @selector(replacementForTokenMock:));
	method_exchangeImplementations(origMethod, mockMethod);
    NSString * stringWithToken = @"testtesttest//curent_user//testtest";
    NSString * deToken = [MM_SOQLQueryString detokenizedSOQLString:stringWithToken];
    STAssertTrue([deToken rangeOfString:@"current_user"].location == NSNotFound,
                 @"Original token should not exist in returned string");
    STAssertEqualObjects(deToken, @"testtesttest1234567890testtest", @"Detokenized string is incorrect");
	method_exchangeImplementations(mockMethod, origMethod);
}

- (NSString *)replacementForTokenMock:(NSString*)token {
    return @"1234567890";
}

@end
