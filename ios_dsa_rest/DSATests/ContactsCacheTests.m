//
//  ContactsCacheTests.m
//  ios_dsa
//
//  Created by Guy Umbright on 2/11/13.
//
//

#import "ContactsCacheTests.h"
#import "OCMockObject.h"
#import "OCMArg.h"
#import "OCMRecorder.h"
#import "ContactsCache.h"
#import "MM_ContextManager+UnitTesting.h"

@interface ContactsCacheTests ()
@property (nonatomic, assign) BOOL contactsLoaded;
@property (nonatomic, strong) ContactsCache *cache;
@property (nonatomic, assign) BOOL searchTestsDone;
@end

@implementation ContactsCacheTests

- (void)setUp
{
    [super setUp];
    
    self.contactsLoaded = NO;
}

- (void)tearDown
{
    // Tear-down code here.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.cache = nil;
    [super tearDown];
}

/////////////////////////////////////////////////////
// 0 contacts
/////////////////////////////////////////////////////
- (void) testNoContacts
{
    [self setUpCacheForContacts:@[]];
    NSUInteger count = self.cache.contactCount;
    
    XCTAssertTrue((count == 0), @"contact count not zero");
    XCTAssertEqualObjects([self.cache contactAtIndex:10], nil, @"out of range contact request did not return nil");
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noContactsSearchComplete:) name:ContactsCacheNotification_SearchComplete object:self.cache];
    [[NSNotificationCenter defaultCenter] addObserverForName:ContactsCacheNotification_SearchComplete
                                                      object:self.cache
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSNotificationCenter defaultCenter] removeObserver:self];
                                                      
                                                      NSUInteger count = self.cache.searchContactCount;
                                                      
                                                      XCTAssertTrue((count == 0), @"search count not zero");
                                                      XCTAssertEqualObjects([self.cache contactAtIndex:10], nil, @"out of range search request did not return nil");
                                                      
                                                      self.searchTestsDone = YES;
                                                  }];
    self.searchTestsDone = NO;
    [self.cache search:@"nothing"];
    
    NSTimeInterval timeout = 2.0;   // Number of seconds before giving up
    NSTimeInterval idle = 0.01;     // Number of seconds to pause within loop
    BOOL timedOut = NO;
    
    NSDate *timeoutDate = [[NSDate alloc] initWithTimeIntervalSinceNow:timeout];
    while (!timedOut && !self.searchTestsDone)
    {
        NSDate *tick = [[NSDate alloc] initWithTimeIntervalSinceNow:idle];
        [[NSRunLoop currentRunLoop] runUntilDate:tick];
        timedOut = ([tick compare:timeoutDate] == NSOrderedDescending);
    }

    XCTAssertFalse(timedOut, @"search took longer than timeout");
}

/////////////////////////////////////////////////////
// 1 contact
/////////////////////////////////////////////////////
- (void) testOneContact
{
    NSDictionary* dict = @{ContactsCacheKey_LastName:@"Umbright",ContactsCacheKey_FirstName:@"Guy",ContactsCacheKey_Email:@"gumbright@modelmetrics.com",
                           ContactsCacheKey_HasEmail:[NSNumber numberWithBool:YES],ContactsCacheKey_AccountName:@"Model Metrics",ContactsCacheKey_SalesforceId:@"1234567890"};
    
    [self setUpCacheForContacts:@[dict]];
    
    NSUInteger count = self.cache.contactCount;
    
    XCTAssertTrue((count == 1), @"contact count not one");
    
    NSDictionary* contact = [self.cache contactAtIndex:0];
    XCTAssertNotNil(contact, @"contact was nil");
    
    XCTAssertEqualObjects(dict, contact, @"contact did not equal original");
    
    XCTAssertEqualObjects([self.cache contactAtIndex:10], nil, @"out of range contact request did not return nil");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:ContactsCacheNotification_SearchComplete
                                                      object:self.cache
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSNotificationCenter defaultCenter] removeObserver:self];
                                                      
                                                      NSUInteger count = self.cache.searchContactCount;
                                                      
                                                      XCTAssertTrue((count == 1), @"search count wrong");
                                                      XCTAssertEqualObjects([self.cache contactAtIndex:10], nil, @"out of range search request did not return nil");
                                                      
                                                      self.searchTestsDone = YES;
                                                  }];
    self.searchTestsDone = NO;
    [self.cache search:@"guy"];
    
    NSTimeInterval timeout = 2.0;   // Number of seconds before giving up
    NSTimeInterval idle = 0.01;     // Number of seconds to pause within loop
    BOOL timedOut = NO;
    
    NSDate *timeoutDate = [[NSDate alloc] initWithTimeIntervalSinceNow:timeout];
    while (!timedOut && !self.searchTestsDone)
    {
        NSDate *tick = [[NSDate alloc] initWithTimeIntervalSinceNow:idle];
        [[NSRunLoop currentRunLoop] runUntilDate:tick];
        timedOut = ([tick compare:timeoutDate] == NSOrderedDescending);
    }
    
    XCTAssertFalse(timedOut, @"search took longer than timeout");
}

/////////////////////////////////////////////////////
// 100,000 contacts
/////////////////////////////////////////////////////
- (void) testLotsOfContacts
{
    NSError* error=nil;
    NSString *path = [[NSBundle bundleForClass:[ContactsCacheTests class]] pathForResource:@"contacts_100000" ofType:@"json"];
    NSData *contactsData = [NSData dataWithContentsOfFile:path];
    NSDictionary *parsedContacts = [NSJSONSerialization JSONObjectWithData:contactsData options:0 error:&error];
    NSArray* allContacts = [parsedContacts objectForKey:@"result"];
    
    NSUInteger numberOfBrookes = [[parsedContacts objectForKey:@"numberOfBrookes"] integerValue];
    
    [self setUpCacheForContacts:allContacts];
    
    NSUInteger count = self.cache.contactCount;
		
    XCTAssertTrue((count == allContacts.count), @"contact count wrong");
    
    NSDictionary* contact = [self.cache contactAtIndex:0];
    XCTAssertNotNil(contact, @"contact was nil");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:ContactsCacheNotification_SearchComplete
                                                      object:self.cache
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSNotificationCenter defaultCenter] removeObserver:self];
                                                      
                                                      NSUInteger count = self.cache.searchContactCount;
													  
                                                      XCTAssertTrue((count == numberOfBrookes), @"search count not correct");
                                                      
                                                      self.searchTestsDone = YES;
                                                  }];
    self.searchTestsDone = NO;
    [self.cache search:@"Brooke"];
    
    NSTimeInterval timeout = 5.0;   // Number of seconds before giving up
    NSTimeInterval idle = 0.01;     // Number of seconds to pause within loop
    BOOL timedOut = NO;
    
    NSDate *timeoutDate = [[NSDate alloc] initWithTimeIntervalSinceNow:timeout];
    while (!timedOut && !self.searchTestsDone)
    {
        NSDate *tick = [[NSDate alloc] initWithTimeIntervalSinceNow:idle];
        [[NSRunLoop currentRunLoop] runUntilDate:tick];
        timedOut = ([tick compare:timeoutDate] == NSOrderedDescending);
    }
    
    XCTAssertFalse(timedOut, @"search took longer than timeout");
}

/////////////////////////////////////////////////////
// 2 contacts, 1 matching by first and last name
/////////////////////////////////////////////////////
- (void) testSearch_matchesFirstAndLastName
{
    NSArray *contacts = @[@{ContactsCacheKey_LastName:@"Umbright",ContactsCacheKey_FirstName:@"Guy",ContactsCacheKey_Email:@"gumbright@modelmetrics.com",
                           ContactsCacheKey_HasEmail:[NSNumber numberWithBool:YES],ContactsCacheKey_AccountName:@"Model Metrics",ContactsCacheKey_SalesforceId:@"1234567890"},
                          @{ContactsCacheKey_LastName:@"McKinley",ContactsCacheKey_FirstName:@"Mike",ContactsCacheKey_Email:@"mmckinley@salesforce.com",
                          ContactsCacheKey_HasEmail:[NSNumber numberWithBool:YES],ContactsCacheKey_AccountName:@"Model Metrics",ContactsCacheKey_SalesforceId:@"0123456789"}];
    
    [self setUpCacheForContacts:contacts];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:ContactsCacheNotification_SearchComplete
                                                      object:self.cache
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSNotificationCenter defaultCenter] removeObserver:self];
                                                      
                                                      NSUInteger count = self.cache.searchContactCount;
                                                      
                                                      XCTAssertTrue((count == 1), @"search count wrong");
                                                      
                                                      self.searchTestsDone = YES;
                                                  }];
    self.searchTestsDone = NO;
    [self.cache search:@"Mike McKinley"];
    
    NSTimeInterval timeout = 2.0;   // Number of seconds before giving up
    NSTimeInterval idle = 0.01;     // Number of seconds to pause within loop
    BOOL timedOut = NO;
    
    NSDate *timeoutDate = [[NSDate alloc] initWithTimeIntervalSinceNow:timeout];
    while (!timedOut && !self.searchTestsDone)
    {
        NSDate *tick = [[NSDate alloc] initWithTimeIntervalSinceNow:idle];
        [[NSRunLoop currentRunLoop] runUntilDate:tick];
        timedOut = ([tick compare:timeoutDate] == NSOrderedDescending);
    }
    
    XCTAssertFalse(timedOut, @"search took longer than timeout");
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
#pragma mark - Test Helpers
/////////////////////////////////////////////////////
// Mock the loader and setup the cache
/////////////////////////////////////////////////////

- (ContactsCache *)setUpCacheForContacts:(NSArray *)contacts
{
    id loaderMock = [OCMockObject mockForClass:[ContactsCacheLoader class]];
    
    [[loaderMock stub] startLoad];
    self.cache = [[ContactsCache alloc] init];
    
    [self.cache loadCacheWithLoader:(ContactsCacheLoader*)loaderMock];
    
    //now we can fake the load with the delegate methods
    [self.cache contactsCacheLoader:(ContactsCacheLoader*)loaderMock contactCount:[contacts count]];
    
    [self.cache contactsCacheLoader:loaderMock contactsLoaded:contacts];
    [self.cache contactsCacheLoaderLoadComplete:loaderMock];
    return self.cache;
}
@end
