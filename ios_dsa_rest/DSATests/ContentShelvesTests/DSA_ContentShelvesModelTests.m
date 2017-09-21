//
//  DSA_ContentShelvesModelTests.m
//  DSA
//
//  Created by Mike Close on 12/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCMock.h"
#import "DSA_ContentShelvesModel.h"

@interface DSA_ContentShelfModel (tests)
- (DSA_ContentShelfModel *)rawShelfNamed:(NSString *)shelfName;
@end

@interface DSA_ContentShelvesModel (tests)
@property (nonatomic, strong) NSMutableArray *rawShelves;
- (void)commitChanges;
@end

@interface DSA_ContentShelvesModelTests : XCTestCase
@property (strong, nonatomic) DSA_ContentShelvesModel *shelves;
@end

@implementation DSA_ContentShelvesModelTests

- (void)setUp {
    [super setUp];
    self.shelves = [[DSA_ContentShelvesModel alloc] init];
}

- (void)tearDown {
    self.shelves = nil;
    [super tearDown];
}

- (void)testCreateShelfNamedUpdateLayoutAnimated_showsAlertForEmptyShelfName
{
    // setup
    id shelvesMock = [OCMockObject partialMockForObject:self.shelves];
    [[shelvesMock expect] showAlertWithTitle:@"Shelf name cannot be empty" message:@"Please enter a shelf name."];
    
    // execution
    [self.shelves createShelfNamed:nil updateLayout:NO animated:NO];
    
    // assertion
    [shelvesMock verify];
}

- (void)testCreateShelfNamedUpdateLayoutAnimated_showsAlertForLongShelfName
{
    // setup
    id shelvesMock = [OCMockObject partialMockForObject:self.shelves];
    [[shelvesMock expect] showAlertWithTitle:@"Shelf name too long" message:@"Shelf name must be less than 80 characters"];
    NSMutableString *longShelfName = [NSMutableString new];
    int length = kShelfNameMaxLength + 1;
    while (length > 0)
    {
        [longShelfName appendString:@"a"];
        length --;
    }
    
    // execution
    [self.shelves createShelfNamed:longShelfName updateLayout:NO animated:NO];
    
    // assertion
    [shelvesMock verify];
}

- (void)testCreateShelfNamedUpdateLayoutAnimated_showsAlertForDuplicateShelfName
{
    // setup
    DSA_ContentShelfModel *existingModel = [[DSA_ContentShelfModel alloc] init];
    NSString *shelfName = @"DUPLICATE";
    existingModel.shelfName = shelfName;
    self.shelves.rawShelves = [NSMutableArray arrayWithArray:@[existingModel]];
    id shelvesMock = [OCMockObject partialMockForObject:self.shelves];
    [[shelvesMock expect] showAlertWithTitle:@"A shelf with this name already exists" message:@"Please enter a different name."];
    
    // execution
    [self.shelves createShelfNamed:shelfName updateLayout:NO animated:NO];
    
    // assertion
    [shelvesMock verify];
}

- (void)testDeleteShelf_deletesShelfAndCallsCommit
{
    // setup
    DSA_ContentShelfModel *firstShelf = [[DSA_ContentShelfModel alloc] init];
    firstShelf.shelfName = @"firstShelf";
    DSA_ContentShelfModel *secondShelf = [[DSA_ContentShelfModel alloc] init];
    secondShelf.shelfName = @"secondShelf";
    DSA_ContentShelfModel *shelfToDelete = [[DSA_ContentShelfModel alloc] init];
    shelfToDelete.shelfName = @"shelfToDelete";
    DSA_ContentShelfModel *thirdShelf = [[DSA_ContentShelfModel alloc] init];
    thirdShelf.shelfName = @"thirdShelf";
    self.shelves.rawShelves = [NSMutableArray arrayWithArray:@[firstShelf, secondShelf, shelfToDelete, thirdShelf]];
    id shelvesMock = [OCMockObject partialMockForObject:self.shelves];
    [[shelvesMock expect] commitChanges];
    
    // execution
    [self.shelves deleteShelf:shelfToDelete];
    
    // assertion
    [shelvesMock verify];
    XCTAssert(self.shelves.rawShelves.count == 3, @"We expected there to be 3 shelves, but there are %d", self.shelves.rawShelves.count);
    XCTAssertFalse([self.shelves.rawShelves containsObject:shelfToDelete], @"The shelf we tried to delete was still there.");
}

// FIXME: this test fails with Bad Access when trying to post the notification in Shelf Model deleteItemAtIndex, but only when the test is running with the other tests.
//- (void)testDeleteItemAtIndexPathUpdateLayoutAnimated_deletesTheRightItem
//{
//    // setup
//    [self setupShelfFixturesOnModel:self.shelves];
//    id shelvesMock = [OCMockObject partialMockForObject:self.shelves];
//    [[shelvesMock expect] commitChanges];
//    NSIndexPath *indexPathToDelete = [NSIndexPath indexPathForItem:3 inSection:1];
//    DSA_ContentShelfModel *modifiedShelf = [self.shelves.rawShelves objectAtIndex:indexPathToDelete.section];
//    
//    // execution
//    [self.shelves deleteItemAtIndexPath:indexPathToDelete updateLayout:NO animated:NO];
//    
//    // assertion
//    [shelvesMock verify];
//    XCTAssert(modifiedShelf.itemIds.count == 4, @"We expected 4 items on the shelf, but there were %d", modifiedShelf.itemIds.count);
//    XCTAssertFalse([modifiedShelf.itemIds containsObject:@"item3"], @"The item we tried to delete was still there.");
//}


////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
#pragma mark - Test Helpers
////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////

- (void)setupShelfFixturesOnModel:(DSA_ContentShelvesModel*)shelvesModel
{
    DSA_ContentShelfModel *shelf0 = [[DSA_ContentShelfModel alloc] init];
    shelf0.shelfName = @"shelf0";
    shelf0.itemIds = [NSMutableArray arrayWithArray:@[@"item0", @"item1", @"item2", @"item3", @"item4"]];
    DSA_ContentShelfModel *shelf1 = [[DSA_ContentShelfModel alloc] init];
    shelf1.shelfName = @"shelf1";
    shelf1.itemIds = [NSMutableArray arrayWithArray:@[@"item0", @"item1", @"item2", @"item3", @"item4"]];
    DSA_ContentShelfModel *shelf2 = [[DSA_ContentShelfModel alloc] init];
    shelf2.shelfName = @"shelf2";
    shelf2.itemIds = [NSMutableArray arrayWithArray:@[@"item0", @"item1", @"item2", @"item3", @"item4"]];
    DSA_ContentShelfModel *shelf3 = [[DSA_ContentShelfModel alloc] init];
    shelf3.shelfName = @"shelf3";
    shelf3.itemIds = [NSMutableArray arrayWithArray:@[@"item0", @"item1", @"item2", @"item3", @"item4"]];
    shelvesModel.rawShelves = [NSMutableArray arrayWithArray:@[shelf0, shelf1, shelf2, shelf3]];
}

@end
