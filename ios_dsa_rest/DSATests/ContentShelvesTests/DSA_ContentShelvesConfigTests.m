//
//  DSA_ContentShelvesConfigTests.m
//  DSA
//
//  Created by Mike Close on 12/1/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCMock.h"
#import "OCMockObject.h"
#import "DSA_ContentShelvesConfig.h"

// expose non-public methods for the tests
@interface DSA_ContentShelvesConfig (test)
+ (NSString *)setterSelectorStringForConfigKey:(NSString *)key;
@end

@interface DSA_ContentShelfConfig (test)
- (CGSize)screenSize;
- (NSInteger)interfaceOrientation;
- (NSArray *)parseColorsObject:(NSArray *)colors forKey:(NSString *)key;
@end


@interface DSA_ContentShelvesConfigTests : XCTestCase
@property (strong, nonatomic) DSA_ContentShelvesConfig *config;
@end

@implementation DSA_ContentShelvesConfigTests

- (void)setUp {
    [super setUp];
    NSString *configPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testConfig" ofType:@"json"];
    self.config = [[DSA_ContentShelvesConfig alloc] initWithConfigPath:configPath];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitWithConfigPath_returnsAConfig {
    XCTAssert((self.config != nil), @"The test config was nil");
}

- (void)testSetterSelectorStringForConfigKey_properlyFormatsSelectors
{
    // setup
    NSString *propertyName = @"propertyName";
    NSString *expectedString = @"setPropertyName:";
    
    NSString *propertyName2 = @"PropertyName";
    NSString *expectedString2 = @"setPropertyName:";
    
    // execution
    NSString *actualSelectorString = [DSA_ContentShelvesConfig setterSelectorStringForConfigKey:propertyName];
    NSString *actualSelectorString2 = [DSA_ContentShelvesConfig setterSelectorStringForConfigKey:propertyName2];
    
    // assertion
    XCTAssert([expectedString isEqualToString:actualSelectorString], @"The selector string was not created properly\n %@ should be %@", actualSelectorString, expectedString);
    XCTAssert([expectedString2 isEqualToString:actualSelectorString2], @"The selector string was not created properly\n %@ should be %@", actualSelectorString2, expectedString2);
}

- (void)testShelfConfigForSection_returnsCorrectShelfConfig
{
    // setup
    int personalLibrarySection = 0;
    int defaultConfigSection = 1;
    
    // execution
    DSA_ContentShelfConfig *defaultConfig = [self.config shelfConfigForSection:defaultConfigSection];
    DSA_ContentShelfConfig *personalLibraryConfig = [self.config shelfConfigForSection:personalLibrarySection];
    
    // assertion
    XCTAssert([defaultConfig isKindOfClass:[DSA_ContentShelfConfig class]]);
    XCTAssert([personalLibraryConfig isKindOfClass:[DSA_ContentShelfConfig class]]);
    XCTAssert([defaultConfig.configurationId isEqualToString:@"default"]);
    XCTAssert([personalLibraryConfig.configurationId isEqualToString:@"personalLibrary"]);
}

- (void)testSetSectionPadding_setsSectionInset
{
    // setup
    NSArray *paddingValues = @[@1, @2, @3, @4];
    DSA_ContentShelfConfig *shelfConfig = [self.config shelfConfigForSection:0];
    
    // execution
    [shelfConfig setSectionPadding:paddingValues];
    UIEdgeInsets sectionInsets = [shelfConfig sectionInset];
    
    // assertion
    XCTAssertEqual(sectionInsets.top, [paddingValues[0] integerValue], @"The first element in the section padding array corresponds to the top of the section insets.  We didn't get the value we expected.");
    XCTAssertEqual(sectionInsets.right, [paddingValues[1] integerValue], @"The second element in the section padding array corresponds to the right of the section insets.  We didn't get the value we expected.");
    XCTAssertEqual(sectionInsets.bottom, [paddingValues[2] integerValue], @"The third element in the section padding array corresponds to the bottom of the section insets.  We didn't get the value we expected.");
    XCTAssertEqual(sectionInsets.left, [paddingValues[3] integerValue], @"The fourt element in the section padding array corresponds to the left of the section insets.  We didn't get the value we expected.");
}

- (void)testSetThumbnailBorderThickness_setsThumbnailBorderOutsets
{
    // setup
    NSArray *borderThicknessValues = @[@1, @2, @3, @4];
    DSA_ContentShelfConfig *shelfConfig = [self.config shelfConfigForSection:0];
    
    // execution
    [shelfConfig setThumbnailBorderThickness:borderThicknessValues];
    UIEdgeInsets borderOutsets = [shelfConfig thumbnailBorderOutsets];
    
    // assertion
    XCTAssertEqual(borderOutsets.top, [borderThicknessValues[0] integerValue], @"The first element in the thumbnail border thickness array corresponds to the top of the border outsets.  We didn't get the value we expected.");
    XCTAssertEqual(borderOutsets.right, [borderThicknessValues[1] integerValue], @"The second element in the thumbnail border thickness array corresponds to the right of the border outsets.  We didn't get the value we expected.");
    XCTAssertEqual(borderOutsets.bottom, [borderThicknessValues[2] integerValue], @"The third element in the thumbnail border thickness array corresponds to the bottom of the border outsets.  We didn't get the value we expected.");
    XCTAssertEqual(borderOutsets.left, [borderThicknessValues[3] integerValue], @"The fourt element in the thumbnail border thickness array corresponds to the left of the border outsets.  We didn't get the value we expected.");
}

- (void)testSetThumbnailSize_makesThumbnailCGSizeAvailable
{
    // setup
    NSArray *thumbnailSize = @[@10, @20];
    DSA_ContentShelfConfig *shelfConfig = [self.config shelfConfigForSection:0];
    
    // execution
    [shelfConfig setThumbnailSize:thumbnailSize];
    CGSize thumbnailCGSize = [shelfConfig thumbnailCGSize];
    
    // assertion
    XCTAssertEqual(thumbnailCGSize.width, [thumbnailSize[0] integerValue], @"The first element in the thumbnailSize array corresponds to the width of the CGSize.  We didn't get the value we expected.");
    XCTAssertEqual(thumbnailCGSize.height, [thumbnailSize[1] integerValue], @"The first element in the thumbnailSize array corresponds to the width of the CGSize.  We didn't get the value we expected.");
}

- (void)testCellCGSize_isProperlyRelativeToScreenBoundsInPortrait
{
    // setup
    DSA_ContentShelfConfig *shelfConfig = [self.config shelfConfigForSection:0];
    int itemsPerRow = 5;
    int screenWidth = 55;
    int expectedCellWidth = 11;
    shelfConfig.itemsPerRowPortrait = itemsPerRow;
    CGSize mockScreenSize = CGSizeMake(screenWidth, 1);
    id screenBoundsMock = [OCMockObject partialMockForObject:shelfConfig];
    [[[screenBoundsMock stub] andReturnValue:OCMOCK_VALUE(mockScreenSize)] screenSize];
    [[[screenBoundsMock stub] andReturnValue:@1] interfaceOrientation];
    
    // execution
    CGSize cellSize = [shelfConfig cellCGSize];
    
    // assertion
    XCTAssertEqual(cellSize.width, expectedCellWidth, @"%f wasn't %d", cellSize.width, expectedCellWidth);
}

- (void)testCellCGSize_isProperlyRelativeToScreenBoundsInLandscape
{
    // setup
    DSA_ContentShelfConfig *shelfConfig = [self.config shelfConfigForSection:0];
    int itemsPerRow = 11;
    int expectedCellWidth = 5;
    int screenWidth = 55;
    shelfConfig.itemsPerRowLandscape = itemsPerRow;
    CGSize screenSizeMock = CGSizeMake(screenWidth, 1);
    id screenBoundsMock = [OCMockObject partialMockForObject:shelfConfig];
    [[[screenBoundsMock stub] andReturnValue:OCMOCK_VALUE(screenSizeMock)] screenSize];
    [[[screenBoundsMock stub] andReturnValue:@4] interfaceOrientation];
    
    // execution
    CGSize cellSize = [shelfConfig cellCGSize];
    
    // assertion
    XCTAssertEqual(cellSize.width, expectedCellWidth, @"%f wasn't %d", cellSize.width, expectedCellWidth);
}

- (void)testParseColorsObject_returnsArrayOfColors
{
    // setup
    NSArray *gradientColors = @[@{@"r":@5,@"g":@5,@"b":@5,@"a":@1},
                                @{@"r":@2,@"g":@2,@"b":@2,@"a":@1},
                                @{@"r":@3,@"g":@3,@"b":@3,@"a":@1},
                                @{@"r":@4,@"g":@4,@"b":@4,@"a":@1}];
    DSA_ContentShelfConfig *shelfConfig = [self.config shelfConfigForSection:0];
    
    // execution
    NSArray *UIColors = [shelfConfig parseColorsObject:gradientColors forKey:@"sectionBackgroundColors"];
    
    // assertion
    [UIColors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *expectedColors = (NSDictionary*)gradientColors[idx];
        CGFloat expectedRed = [expectedColors[@"r"] floatValue] / 255;
        CGFloat expectedGreen = [expectedColors[@"g"] floatValue] / 255;
        CGFloat expectedBlue = [expectedColors[@"b"] floatValue] / 255;
        CGFloat expectedAlpha = [expectedColors[@"a"] floatValue];
        CGFloat actualRed,actualGreen,actualBlue,actualAlpha;
        [(UIColor*)obj getRed:&actualRed green:&actualGreen blue:&actualBlue alpha:&actualAlpha];
        
        
        XCTAssert([obj isKindOfClass:[UIColor class]], @"We expected a UIColor instance, but got a %@", [obj class]);
        XCTAssertEqual(expectedRed, actualRed, @"We expected %f but got %f.", expectedRed, actualRed);
        XCTAssertEqual(expectedGreen, actualGreen, @"We expected %f but got %f.", expectedGreen, actualGreen);
        XCTAssertEqual(expectedBlue, actualBlue, @"We expected %f but got %f.", expectedBlue, actualBlue);
        XCTAssertEqual(expectedAlpha, actualAlpha, @"We expected %f but got %f.", expectedAlpha, actualAlpha);
    }];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
