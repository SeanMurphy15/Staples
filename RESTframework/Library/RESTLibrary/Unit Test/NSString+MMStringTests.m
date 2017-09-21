//
//  NSString+MMStringTests.m
//  RESTLibrary
//
//  Created by Jayaprakash Manchu on 12/27/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+MM_String.h"

@interface NSString_MMStringTests : XCTestCase {
    
}

@end

@implementation NSString_MMStringTests
/* The setUp method is called automatically before each test-case method (methods whose name starts with 'test').
 */
- (void) setUp {
    // uncaught and the app crashes upon a failed STAssert (oh well).
    // [self raiseAfterFailure];
    self.continueAfterFailure = NO;
}

- (void)testCurrencyStringDecimalTruncationWithFloat {
    NSString *currencyString = [NSString currencyStringForAmountWithoutDecimal:5.2];
    NSLocale *theLocale = [NSLocale currentLocale];
    NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
    XCTAssertTrue([currencyString isEqualToString:([NSString stringWithFormat:@"%@5",symbol])], @"Failed to work with float!");
}

- (void)testCurrencyStringDecimalTruncationWithInt {
    NSString *currencyString = [NSString currencyStringForAmountWithoutDecimal:5];
    NSLocale *theLocale = [NSLocale currentLocale];
    NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
    XCTAssertTrue([currencyString isEqualToString:([NSString stringWithFormat:@"%@5",symbol])], @"Failed to work with Int!");
}

- (void)testCurrencyStringDecimalTruncationWithLong {
    NSString *currencyString = [NSString currencyStringForAmountWithoutDecimal:5555555555.555555555];
    NSLocale *theLocale = [NSLocale currentLocale];
    NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
    //  This should probably assert to false because currencyStringForAmountWithoutDecimal
    //  doesn't expect longs and also because NSNumberformatter will include ','s
    XCTAssertFalse([currencyString isEqualToString:([NSString stringWithFormat:@"%@5555555555",symbol])], @"Failed to work with Long!");
}


- (void)testCurrencyStringDecimalTruncationWithdouble {
    NSString *currencyString = [NSString currencyStringForAmountWithoutDecimal:01.0000000000000555555555];
    NSLocale *theLocale = [NSLocale currentLocale];
    NSString *symbol = [theLocale objectForKey:NSLocaleCurrencySymbol];
    XCTAssertTrue([currencyString isEqualToString:([NSString stringWithFormat:@"%@1",symbol])], @"Failed to remove decimal!");
}

/* The tearDown method is called automatically after each test-case method (methods whose name starts with 'test').
 */
- (void) tearDown {
    NSLog(@"%@ tearDown", self.name);
}


@end
