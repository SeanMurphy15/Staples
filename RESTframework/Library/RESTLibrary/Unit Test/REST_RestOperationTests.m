//
//  REST_RestOperationTests.m
//  RESTLibrary
//
//  Created by Steve Deren on 1/28/13.
//  Copyright (c) 2013 Model Metrics, Inc. All rights reserved.
//

#import <SalesforceNativeSDK/SFRestAPI.h>
#import <SalesforceNativeSDK/SFRestRequest.h>
#import "MM_RestOperation.h"


static MM_SyncManager * _sharedManager = nil;
@implementation MM_SyncManager (UnitTests)
+(id)sharedManager {
    return _sharedManager;
}
@end

#import "REST_RestOperationTests.h"
#import <OCMock/OCMock.h>

@implementation REST_RestOperationTests


- (void)setUp
{
    [super setUp];
    // Set-up code here    
}

- (void)testOperationWithRequest
{
    id request = [SFRestRequest requestWithMethod:SFRestMethodGET path:nil queryParams:nil];
    MM_RestOperation		*op = [MM_RestOperation operationWithRequest:request groupTag:nil completionBlock:nil sourceTag: nil];
    op.isTestOnlyOperation = YES;
    XCTAssertNotNil(op, @"MM_RestOperation should not return nil");
}

- (void)testOperationStart
{
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"test":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                                groupTag:nil
                                                        completionBlock:nil sourceTag: nil];
    op.isTestOnlyOperation = YES;
    [op start];
    XCTAssertTrue(op.isRunning,@"op should be running");
}

- (void)testOperationNotRunning {
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    op.isTestOnlyOperation = YES;
	[op start];
    XCTAssertTrue(op.isRunning,@"op should be running");
    XCTAssertTrue(!op.completed,@"op should not be completed");
    [op completeWithResponse: nil andJSON: nil];
    XCTAssertTrue(!op.isRunning,@"op should not be running");
    XCTAssertTrue(op.completed,@"op should be completed");
}

- (void)testOperationCompletionBlockWithError {
    NSDictionary * segs = [NSDictionary dictionaryWithObjects:@[@"message",@"Text"] forKeys:@[@"text",@"type"]];
    NSDictionary * messageSegs = @{@"messageSegments":@[segs]};
    NSDictionary * params = [NSDictionary dictionaryWithObject:messageSegs forKey:@"body"];
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodPOST
                                                          path:@"/v23.0/chatter/feeds/record/1234567890/feed-items"
                                                   queryParams:params];
    
    restArgumentBlock block = ^(NSError * error, id jsonResponse, MM_RestOperation *completedOperation) {
        XCTAssertTrue(error != nil, @"Error should be passed into completion block");
		return NO;
    };
    
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request completionBlock:block sourceTag: nil];
    NSError * error = [NSError errorWithDomain:@"ErrorDomain" code:201 userInfo:nil];

    op.isTestOnlyOperation = YES;
    [op request:request didFailLoadWithError:error];
    
    XCTAssertFalse(op.isRunning, @"Op shouldn't be running after error.");
}

- (void)testOperationPause
{
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"test":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                          groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    op.isTestOnlyOperation = YES;
    [op start];
    XCTAssertTrue(op.isRunning,@"op should be running");
    [op pause];
    XCTAssertTrue(!op.isRunning,@"op should be paused");
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

@end
