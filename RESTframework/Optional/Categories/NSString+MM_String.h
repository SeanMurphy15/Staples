//
//  NSString+MM_String.h
//  Cat MCV
//
//  Created by Ben Gottlieb on 4/2/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	phonePrettyFormatStyle_onePlus,
	phonePrettyFormatStyle_leadingOne,
	phonePrettyFormatStyle_areaCodePlus7,
	phonePrettyFormatStyle_just7
} phonePrettyFormatStyle;

typedef enum {
	phoneDelimiterStyle_dots,
	phoneDelimiterStyle_parens,
	phoneDelimiterStyle_dashes
} phoneDelimiterStyle;

@interface NSString (MM_String)

+ (NSString *) currencyStringForAmountWithoutDecimal: (float) amount;
- (NSString *) prettyFormattedPhone: (phonePrettyFormatStyle) style withDelimiter: (phoneDelimiterStyle) delim;

@property (nonatomic, readonly) NSString *shortSalesforceID, *longSalesforceID;

@end

void incrementCountForString(NSString *string);
void decrementCountForString(NSString *string);
