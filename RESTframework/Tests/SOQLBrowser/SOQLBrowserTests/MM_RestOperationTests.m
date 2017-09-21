//
//  MM_RestOperationTests.m
//  SOQLBrowser
//
//  Created by Steve Deren on 1/7/13.
//  Copyright (c) 2013 Model Metrics, Inc. All rights reserved.
//

#import "MM_RestOperationTests.h"
#import "MM_RestOperation.h"
#import <OCMock/OCMock.h>

@implementation MM_RestOperationTests

@synthesize moc;

- (void)setUp
{
    [super setUp];
    NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];
    NSManagedObjectModel *mom = [NSManagedObjectModel mergedModelFromBundles:bundles];
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    self.moc = [[NSManagedObjectContext alloc] init];
    self.moc.persistentStoreCoordinator = psc;
    
    MM_SFObjectDefinition * def = [self.moc insertNewEntityWithName:@"SFObjectDefinition"];
    def.name = @"Account";
    def.syncInfo_mm = @{@"dependencies":@"User", @"write-only":@YES};
    [def save];
}

-(void)tearDown {
    STAssertNotNil(self.moc, @"any test involving managed object context was likely cut short");
    self.moc = nil;
    [super tearDown];
}

- (void)testOperationWithRequest
{
    id request = [SFRestRequest requestWithMethod:SFRestMethodGET path:nil queryParams:nil];
    id op = [MM_RestOperation operationWithRequest:request groupTag:nil completionBlock:nil sourceTag: nil];
    STAssertNotNil(op, @"MM_RestOperation should not return nil");
}

- (void)testOperationWithRequestCompletionBlockParam
{
    id request = [SFRestRequest requestWithMethod:SFRestMethodGET path:nil queryParams:nil];
    __block int k = 0;
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request groupTag:nil completionBlock:^(NSError * error, id response, MM_RestOperation *completedOperation) {
        k++;
		return NO;
    } sourceTag: nil];
    
    STAssertNotNil(op.completionBlock, @"Completion block should not be nil after set");
}

- (void)testOperationWithRequestRequestParam
{
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:nil queryParams:@{@"test":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request groupTag:nil completionBlock:nil sourceTag: nil];
    
    STAssertEquals([op.request.queryParams.allKeys containsObject:@"test"], YES, @"Query params missing a given parameter");
}

- (void)testCoreDataSetup {
    STAssertNotNil(self.moc, @"moc shouldn't be nil");
}

- (void)testQueuePendingDefSync {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SFObjectDefinition" inManagedObjectContext:self.moc];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.moc executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        NSLog(@"TrialSelectionVC: executeFetchRequest error: %@", [error localizedDescription]);
    }
    
    int resultsCount = [mutableFetchResults count];
    
    STAssertEquals(resultsCount, 1, @"saved definition doesnt exist");
    
    MM_SFObjectDefinition * def = [mutableFetchResults objectAtIndex:0];
    STAssertNotNil(def, @"def is nil");
    
    [MM_RestOperation queueSyncOperationsForObjectDefintion:def];
    
    STAssertTrue(![[MM_SyncManager sharedManager].pendingObjectNames containsObject:@"Account"],
                 @"Account should have been added to pending");
}

- (void)testOperationStart {
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"test":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request groupTag:nil completionBlock:^(NSError * error, id resp, MM_RestOperation *completedOperation) {
        //do nothing
		return NO;
    } sourceTag: nil];
    [op start];
    STAssertTrue(op.isRunning,@"op should be running");
}

-(void)testOperationReturn {
    SFRestRequest * request = [SFRestRequest requestWithMethod:SFRestMethodGET path:@"path" queryParams:@{@"key":@"value"}];
    MM_RestOperation * op = [MM_RestOperation operationWithRequest:request groupTag:nil
                                                   completionBlock:nil sourceTag: nil];
    [op start];
    STAssertTrue(op.isRunning,@"op should be running");
    STAssertTrue(!op.completed,@"op should not be completed");
    [op completeWithResponse: nil andJSON: nil];
    STAssertTrue(!op.isRunning,@"op should not be running");
    STAssertTrue(op.completed,@"op should be completed");
}

@end