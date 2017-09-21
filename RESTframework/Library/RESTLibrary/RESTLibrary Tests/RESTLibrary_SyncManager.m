//
//  RESTLibrary_SyncManager.m
//  RESTLibrary
//
//  Created by Cory D. Wiles on 12/9/13.
//  Copyright (c) 2013 Stand Alone, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MM_SyncManager.h"

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

@interface RESTLibrary_SyncManager : XCTestCase

@property (nonatomic, strong) NSManagedObjectContext *moc;

@end

@implementation RESTLibrary_SyncManager

- (void)setUp
{
  [super setUp];
  _sharedManager = [[MM_SyncManager alloc] init];
  NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];
  NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:bundles];
  NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
  _moc = [[NSManagedObjectContext alloc] init];
  _moc.persistentStoreCoordinator = psc;
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

//- (void)testAddToFrontOfQueue {
//  dispatch_semaphore_t		sema = dispatch_semaphore_create(0);
//  SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
//  MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
//                                                        groupTag:nil
//                                                 completionBlock:nil sourceTag: nil];
//  SFRestRequest * request2 = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path2" queryParams:@{@"key2":@"value2"}];
//  MM_RestOperation * op2 = [MM_RestOperation operationWithRequest:request2
//                                                         groupTag:nil
//                                                  completionBlock:nil sourceTag: nil];
//  [_sharedManager queueOperation:op];
//  [_sharedManager queueOperation:op2 atFrontOfQueue:YES];
//  
//	dispatch_async(_sharedManager.parseDispatchQueue, ^{ dispatch_semaphore_signal(sema); });
//  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//  dispatch_release(sema);
//	
//  XCTAssertNotNil(_sharedManager.pending, @"pending operations array should exist after adding");
//  XCTAssertTrue(_sharedManager.pending.count == 2, @"pending operations array should contain 2 items");
//  
//  MM_RestOperation * first = [_sharedManager.pending objectAtIndex:0];
//  XCTAssertEqualObjects(op2, first, @"Operation added second should be in front.");
//}

//- (void)testQueueStartStop {
//  SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
//  MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
//                                                        groupTag:nil
//                                                 completionBlock:nil sourceTag: nil];
//  [_sharedManager queueOperation:op];
//  XCTAssertFalse(_sharedManager.queueStopped, @"Queue should not be stopped");
//  [_sharedManager stopQueue];
//  XCTAssertTrue(_sharedManager.queueStopped, @"Queue should be stopped");
//}
//
//- (void)testCancelSync {
//  id mockObserver = [OCMockObject observerMock];
//  [[NSNotificationCenter defaultCenter] addMockObserver:mockObserver name:kNotification_SyncCancelled object:nil];
//  [[mockObserver expect] notificationWithName:kNotification_SyncCancelled object:[OCMArg any] userInfo:[OCMArg any]];
//  [_sharedManager cancelSync];
//  [[NSNotificationCenter defaultCenter] removeObserver:mockObserver];
//  [mockObserver verify];
//}
//
//- (void)testDequeueOperationCalledAfterResponseIsLoaded {
//  SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
//  MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
//                                                        groupTag:nil
//                                                 completionBlock:nil sourceTag: nil];
//  [_sharedManager queueOperation:op];
//  
//  id mockManager = [OCMockObject partialMockForObject:_sharedManager];
//  
//  [[mockManager expect] dequeueOperation:op completed:YES];
//  
//  //    [op request:request didLoadResponse:nil];
//	[op completeWithResponse: nil];
//  [mockManager verify];
//}
//
//- (void)testQueuePendingDefinitionSync {
//  MM_SFObjectDefinition * def = [_moc insertNewEntityWithName:@"SFObjectDefinition"];
//  def.name = @"Account";
//  [_sharedManager queuePendingDefinitionSync:def];
//  XCTAssertTrue([_sharedManager.pendingObjectNames containsObject:@"Account"], @"Account should be pending");
//}
//
//- (void)testAreObjectDefinitionSyncsPending {
//  dispatch_semaphore_t		sema = dispatch_semaphore_create(0);
//  SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
//  MM_RestOperation * op = [MM_RestOperation operationWithRequest:request
//                                                        groupTag:nil
//                                                 completionBlock:nil sourceTag: nil];
//  op.query = [MM_SOQLQueryString queryWithObjectName:@"Account"];
//  XCTAssertFalse([_sharedManager areOperationsPendingForObjectType:@"Account"], @"Account should not be pending");
//  [_sharedManager queueOperation:op];
//  
//	dispatch_async(_sharedManager.parseDispatchQueue, ^{ dispatch_semaphore_signal(sema); });
//  dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//  dispatch_release(sema);
//  
//  XCTAssertTrue([_sharedManager areOperationsPendingForObjectType:@"Account"], @"Account should be pending");
//}


- (void)tearDown
{
  _sharedManager = nil;
  _moc = nil;
  [super tearDown];
}

@end
