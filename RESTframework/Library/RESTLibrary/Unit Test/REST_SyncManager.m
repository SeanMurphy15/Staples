//
//  REST_SyncManager.m
//  RESTLibrary
//
//  Created by Steve Deren on 1/29/13.
//  Copyright (c) 2013 Model Metrics, Inc. All rights reserved.
//
#import <SalesforceNativeSDK/SFRestAPI.h>
#import <SalesforceNativeSDK/SFRestRequest.h>

static MM_SyncManager * _sharedManager = nil;
static MM_Log * _log = nil;

@implementation MM_SyncManager (UnitTests)
+(id)sharedManager {
    return _sharedManager;
}

@end

@implementation MM_Log (UnitTests)
+ (id) sharedLog {
	return _log;
}
@end
#import "REST_SyncManager.h"

@implementation REST_SyncManager

- (void)setUp
{
    [super setUp];
    _sharedManager = [[MM_SyncManager alloc] init];
    NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];
    NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:bundles];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    moc = [[NSManagedObjectContext alloc] init];
    moc.persistentStoreCoordinator = psc;
}

- (void)testSyncManagerNotNil {
    XCTAssertNotNil(_sharedManager, @"manager should not be nil");
}

- (void)testAddToQueue {
    dispatch_semaphore_t		sema = dispatch_semaphore_create(0);

    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                          groupTag:nil
                                                   completionBlock: nil sourceTag: nil];
    [_sharedManager queueOperation:op];
	
	dispatch_async(_sharedManager.parseDispatchQueue, ^{ dispatch_semaphore_signal(sema); });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);

    XCTAssertNotNil(_sharedManager.pending, @"pending operations array should exist after adding");
    XCTAssertTrue(_sharedManager.pending.count == 1, @"pending operations array should contain 1 item");
}

- (void)testAddToFrontOfQueue {
    dispatch_semaphore_t		sema = dispatch_semaphore_create(0);
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                          groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    SFRestRequest * request2 = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path2" queryParams:@{@"key2":@"value2"}];
    MM_RestOperation * op2 = [MM_RestOperation operationWithRequest:request2
                                                          groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    [_sharedManager queueOperation:op];
    [_sharedManager queueOperation:op2 atFrontOfQueue:YES];

	dispatch_async(_sharedManager.parseDispatchQueue, ^{ dispatch_semaphore_signal(sema); });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
	
    XCTAssertNotNil(_sharedManager.pending, @"pending operations array should exist after adding");
    XCTAssertTrue(_sharedManager.pending.count == 2, @"pending operations array should contain 2 items");
    
    MM_RestOperation * first = [_sharedManager.pending objectAtIndex:0];
    XCTAssertEqualObjects(op2, first, @"Operation added second should be in front.");
}

- (void)testQueueStartStop {
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                          groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    [_sharedManager queueOperation:op];
    XCTAssertFalse(_sharedManager.queueStopped, @"Queue should not be stopped");
    [_sharedManager stopQueue];
    XCTAssertTrue(_sharedManager.queueStopped, @"Queue should be stopped");
}

- (void)testCancelSync {			//this test will always fail now, since we no longer post this notification if we're not actually syncing
//    id mockObserver = [OCMockObject observerMock];
//    [[NSNotificationCenter defaultCenter] addMockObserver:mockObserver name:kNotification_SyncCancelled object:nil];
//    [[mockObserver expect] notificationWithName:kNotification_SyncCancelled object:[OCMArg any] userInfo:[OCMArg any]];
//    [_sharedManager cancelSync];
//    [[NSNotificationCenter defaultCenter] removeObserver:mockObserver];
//    [mockObserver verify];
}

- (void)testDequeueOperationCalledAfterResponseIsLoaded {
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                          groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    [_sharedManager queueOperation:op];
    
    id mockOp = [OCMockObject partialMockForObject:op];
    
    [[mockOp expect] dequeue];
	[op completeWithResponse: nil andJSON: nil];
    [mockOp verify];
}

- (void)testQueuePendingDefinitionSync {
    MM_SFObjectDefinition * def = [moc insertNewEntityWithName:@"SFObjectDefinition"];
    def.name = @"Account";    
    [_sharedManager queuePendingDefinitionSync:def];
    XCTAssertTrue([_sharedManager.pendingObjectNames containsObject:@"Account"], @"Account should be pending");
}

- (void)testAreObjectDefinitionSyncsPending {
    dispatch_semaphore_t		sema = dispatch_semaphore_create(0);
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
                                                          groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    op.query = [MM_SOQLQueryString queryWithObjectName:@"Account"];
    XCTAssertFalse([_sharedManager areOperationsPendingForObjectType:@"Account"], @"Account should not be pending");
    [_sharedManager queueOperation:op];

	dispatch_async(_sharedManager.parseDispatchQueue, ^{ dispatch_semaphore_signal(sema); });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);

    XCTAssertTrue([_sharedManager areOperationsPendingForObjectType:@"Account"], @"Account should be pending");
}


- (void)tearDown
{
    _sharedManager = nil;
    moc = nil;
    [super tearDown];
}
@end
