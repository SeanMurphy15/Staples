//
//  REST_SoqlQueryStringTest.m
//  RESTLibrary
//
//  Created by Amisha Goyal on 12/19/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "REST_SoqlQueryStringTest.h"
#import "OCMock.h"
#import "MM_SOQLQueryString.h"

#import <objc/runtime.h>
#import <objc/message.h>

@implementation REST_SoqlQueryStringTest

- (NSString *)replacementForTokenMock:(NSString*)token {
    return @"1234567890";
}
- (void)setUp
{
    [super setUp];
    // Set-up code here.
    queryStringObject = [[MM_SOQLQueryString alloc] init];
}


- (void)testqueryWithObjectName
{
    id query = [MM_SOQLQueryString queryWithObjectName:@"Account"];
    NSString *querystring = [NSString  stringWithFormat:@"%@",query];
    XCTAssertEqualObjects(querystring,@"MM_SOQLQuery: SELECT  FROM Account" , @"query failed");
}

-(void)testDetokenizedSOQLString{
    NSString *predicateString = @"ModelM__IsDraft__c = false";
    NSString *returnString = [MM_SOQLQueryString detokenizedSOQLString:predicateString];
    XCTAssertEqualObjects(returnString, predicateString, @"DetokenizedSOQLString failed");
}

- (void)testDetokenizedString {
    NSString * stringWithToken = @"test//token//testtest";
    NSString * deToken = [MM_SOQLQueryString detokenizedSOQLString:stringWithToken];
    XCTAssertNotNil(deToken, @"Returned string should not be nil");
    XCTAssertTrue([deToken rangeOfString:@"token"].location == NSNotFound,@"Original token should not exist in returned string");
    
    NSString * badString = @"testtokentesttest";
    deToken = [MM_SOQLQueryString detokenizedSOQLString:badString];
    XCTAssertEqual(badString, deToken, @"Initial string should be returned");
    
    badString = nil;
    deToken = [MM_SOQLQueryString detokenizedSOQLString:badString];
    XCTAssertEqual(badString, deToken, @"Initial string should be returned");
}

- (void)testDetokenizedStringCurrentUser {
    Method origMethod = class_getClassMethod([MM_SOQLQueryString class], @selector(replacementForToken:));
	Method mockMethod = class_getInstanceMethod([self class], @selector(replacementForTokenMock:));
	method_exchangeImplementations(origMethod, mockMethod);
    NSString * stringWithToken = @"testtesttest//current_user//testtest";
    NSString * deToken = [MM_SOQLQueryString detokenizedSOQLString:stringWithToken];
    XCTAssertTrue([deToken rangeOfString:@"current_user"].location == NSNotFound,
                 @"Original token should not exist in returned string");
    XCTAssertEqualObjects(deToken, @"testtesttest1234567890testtest", @"Detokenized string is incorrect");
	method_exchangeImplementations(mockMethod, origMethod);
}

-(void)testremoveAllPredicateStrings{
	[queryStringObject addPredicateString:@"ModelM__IsDraft__c = false"];
	queryStringObject.predicate = nil;

    XCTAssertFalse(queryStringObject.predicate != nil, @"Clearing predicate failed ");
}

-(void)testAddPredicateString{
	[queryStringObject addPredicateString:@"ModelM__IsDraft__c = false"];
	
    XCTAssertTrue(queryStringObject.predicate != nil, @"AddPredicateString failed ");
    XCTAssertEqual(queryStringObject.predicate.rawPredicate, @"ModelM__IsDraft__c = false", @"Object not added successfully");
}

-(void)testQueryStringWithoutPredicate{
    queryStringObject.isCountQuery=0;
    queryStringObject.isIDOnlyQuery=0;
    queryStringObject.fields = [NSArray arrayWithObjects:@"Id",
                                @"OwnerId",
                                @"IsDeleted",
                                @"Name",
                                @"CreatedDate",
                                @"CreatedById",
                                @"LastModifiedDate",
                                @"LastModifiedById",
                                @"SystemModstamp",
                                @"ModelM__Active__c",
                                @"ModelM__ButtonDefaultAttachmentId__c",
                                @"ModelM__ButtonHighlightAttachmentId__c",
                                @"ModelM__ButtonHighlightTextColor__c",
                                @"ModelM__ButtonTextAlpha__c",
                                @"ModelM__ButtonTextColor__c",
                                @"ModelM__Check_In_Enabled__c",
                                @"ModelM__IntroTextAlpha__c",
                                @"ModelM__IntroTextColor__c",
                                @"ModelM__IntroText__c",
                                @"ModelM__LandscapeAttachmentId__c",
                                @"ModelM__LinkToEditor__c",
                                @"ModelM__LogoAttachmentId__c",
                                @"ModelM__PortraitAttachmentId__c",
                                @"ModelM__Profile_Names__c",
                                @"ModelM__Profiles__c",
                                @"ModelM__TitleBgAlpha__c",
                                @"ModelM__TitleBgColor__c",
                                @"ModelM__TitleTextAlpha__c",
                                @"ModelM__TitleTextColor__c",
                                @"ModelM__TitleText__c", nil];
    queryStringObject.objectName =@"ModelM__MobileAppConfig__c";
    
    NSString *expectedQueryString = @"SELECT Id,OwnerId,IsDeleted,Name,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,SystemModstamp,ModelM__Active__c,ModelM__ButtonDefaultAttachmentId__c,ModelM__ButtonHighlightAttachmentId__c,ModelM__ButtonHighlightTextColor__c,ModelM__ButtonTextAlpha__c,ModelM__ButtonTextColor__c,ModelM__Check_In_Enabled__c,ModelM__IntroTextAlpha__c,ModelM__IntroTextColor__c,ModelM__IntroText__c,ModelM__LandscapeAttachmentId__c,ModelM__LinkToEditor__c,ModelM__LogoAttachmentId__c,ModelM__PortraitAttachmentId__c,ModelM__Profile_Names__c,ModelM__Profiles__c,ModelM__TitleBgAlpha__c,ModelM__TitleBgColor__c,ModelM__TitleTextAlpha__c,ModelM__TitleTextColor__c,ModelM__TitleText__c FROM ModelM__MobileAppConfig__c";
    NSString *actualQueryString = [queryStringObject queryString];
    NSLog(@"actual :%@",actualQueryString);
    XCTAssertEqualObjects(actualQueryString, expectedQueryString, @"Query String failed");
}

-(void)testQueryStringWithPredicate{
    queryStringObject.isCountQuery=0;
    queryStringObject.isIDOnlyQuery=0;
    queryStringObject.fields = [NSArray arrayWithObjects:@"ProfileId",
                                @"Id",
                                @"LastModifiedDate",
                                @"CreatedDate",
                                @"Username",
                                @"Name",
                                @"FirstName",
                                @"LastName",
                                @"Email",
                                @"UserRoleId", nil];
    queryStringObject.objectName =@"User";
    [queryStringObject addPredicateString: @"Id = '005U0000000ciesIAA'"];
    
    NSString *expectedQueryString = @"SELECT ProfileId,Id,LastModifiedDate,CreatedDate,Username,Name,FirstName,LastName,Email,UserRoleId FROM User WHERE (Id = '005U0000000ciesIAA')";
    NSString *actualQueryString = [queryStringObject queryString];
    NSLog(@"actual :%@",actualQueryString);
    XCTAssertEqualObjects(actualQueryString, expectedQueryString, @"Query String failed with predicate");
}

-(void)testQueryStringForCountQuery{
    queryStringObject.isCountQuery=1;
    queryStringObject.objectName =@"User";
    [queryStringObject addPredicateString :@"Id = '005U0000000ciesIAA'"];
    NSString *expectedQueryString = @"SELECT count() FROM User WHERE (Id = '005U0000000ciesIAA')";
    NSString *actualQueryString = [queryStringObject queryString];
    NSLog(@"actual :%@",actualQueryString);
    XCTAssertEqualObjects(actualQueryString, expectedQueryString, @"Query String failed with predicate");
}


@end
