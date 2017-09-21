//
//  NSDate+SA_AdditionsTests.m
//  RESTLibrary
//
//  Created by Jayaprakash Manchu on 12/28/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <SA_Base/NSDate+SA_Additions.h>

@interface NSDate_SA_AdditionsTests : XCTestCase

@end


@implementation NSDate_SA_AdditionsTests

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

- (void)testDateNotNil {
    NSDate *date = [NSDate dateWithUNIXString:@"2012-12-27T22:22:22 zzzz"];//@"YYYY-mm-ddTHH:mm:ss zzzz"
    XCTAssertNotNil(date, @"Date shouldn't be nil");
}

- (void)testDateToNil {
    NSDate *date = [NSDate dateWithUNIXString:@""];//@"YYYY-mm-ddTHH:mm:ss zzzz"
    XCTAssertNil(date, @"Date should be nil");
}

- (void)testDateShortValue {
    NSDate *date = [NSDate dateWithUNIXString:@"2012-12-27T02:22:22 zzzz"];//@"YYYY-mm-ddTHH:mm:ss zzzz"
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    XCTAssertTrue([[date shortDateString] isEqualToString:[dateFormatter stringFromDate:date]], @"shortDateString is not functioning properly!");
}

- (void)testDateMediumValue {
    NSDate *date = [NSDate dateWithUNIXString:@"2012-12-27T22:22:22 zzzz"];//@"YYYY-mm-ddTHH:mm:ss zzzz"
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    XCTAssertTrue([[date mediumDateString] isEqualToString:[dateFormatter stringFromDate:date]], @"mediumDateString is not functioning properly!");
}

- (void)testTimeShortValue {
    NSDate *date = [NSDate dateWithUNIXString:@"2012-12-27T22:22:22 zzzz"];//@"YYYY-mm-ddTHH:mm:ss zzzz"
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]  init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    XCTAssertTrue([[date shortTimeString] isEqualToString:[dateFormatter stringFromDate:date]], @"shortTimeString is not functioning properly!");
}

- (void)testTimeMediumValue {
    NSDate *date = [NSDate dateWithUNIXString:@"2012-12-27T22:22:22 zzzz"];//@"YYYY-mm-ddTHH:mm:ss zzzz"
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]  init];
    //[dateFormatter setTimeStyle:NSDateFormatterMediumStyle]; //this includes seconds whereas mediumTimeString doesnt so this would always fail
    dateFormatter.dateFormat = @"hh:mm a";
    NSLog(@"%@ vs %@",[dateFormatter stringFromDate:date], [date mediumTimeString]);
    //remove leading zeros during check
    NSUInteger location = [[dateFormatter stringFromDate:date] rangeOfString:[date mediumTimeString]].location;
    XCTAssertTrue(location != NSNotFound,@"mediumTimeString is not functioning properly!");
}


@end
