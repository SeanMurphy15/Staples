//
//  NSString+MM_String.m
//  Cat MCV
//
//  Created by Ben Gottlieb on 4/2/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "NSString+MM_String.h"
#import "MM_Log.h"

@implementation NSString (MM_String)

+ (NSString *) currencyStringForAmountWithoutDecimal: (float) amount {
	NSString		*result = [NSNumberFormatter localizedStringFromNumber: [NSNumber numberWithFloat: amount] numberStyle: NSNumberFormatterCurrencyStyle];
	NSString		*radix = @".";
	NSRange			decimalRange = [result rangeOfString: radix];
	
	if (decimalRange.location != NSNotFound) {
		result = [result substringToIndex: decimalRange.location];
	}
	return result;
}

- (NSString *) prettyFormattedPhone: (phonePrettyFormatStyle) style withDelimiter: (phoneDelimiterStyle) delim {
	NSString		*numbersOnly = [self stringByStrippingCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet] options: 0];
	
	if (numbersOnly.length == 11 && [numbersOnly characterAtIndex: 0] == '1') {
		numbersOnly = [numbersOnly substringFromIndex: 1];
	}
	
	//if (!hasLeading1 && numbersOnly.length == 7) style = phonePrettyFormatStyle_just7;
	if (numbersOnly.length != 10) return self;
	
	NSString		*areaCode = @"", *prefix = @"", *exchange = @"";
	
	if (numbersOnly.length > 0) areaCode = [numbersOnly substringWithRange: NSMakeRange(0, MIN(numbersOnly.length, 3))];
	numbersOnly = [numbersOnly substringFromIndex: areaCode.length];
	
	if (numbersOnly.length > 0) prefix = [numbersOnly substringWithRange: NSMakeRange(0, MIN(numbersOnly.length, 3))];
	numbersOnly = [numbersOnly substringFromIndex: prefix.length];

	exchange = numbersOnly;
	
	return $S(@"(%@) %@-%@", areaCode, prefix, exchange);
	
}

- (NSString *) longSalesforceID {
	if (self.length == 18) return self;
	if (self.length != 15) return nil;
	
	NSArray				*parts = @[ [self substringWithRange: NSMakeRange(0, 5)], [self substringWithRange: NSMakeRange(5, 5)],  [self substringWithRange: NSMakeRange(10, 5)] ];
	NSMutableString		*result = self.mutableCopy;
	NSString			*suffixes = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
	
	for (NSString *part in parts) {
		NSUInteger				charOffset = 0;
		
		for (NSInteger index = 0; index < 5; index++) {
			wchar_t				letter = [part characterAtIndex: index];
			
			if (letter >= 'A' && letter <= 'Z') charOffset += (1 << index);
		}
		
		[result appendString: suffixes[charOffset]];
	}
	
	return result;
}

- (NSString *) shortSalesforceID {
	if (self.length == 15) return self;
	if (self.length != 18) return nil;
	return [self substringToIndex: 15];
}


@end

static NSMutableDictionary			*s_stringCounts = nil;
void logCountForString(NSString *string);

void incrementCountForString(NSString *string) {
	if (s_stringCounts == nil) s_stringCounts = [NSMutableDictionary dictionary];
	
	s_stringCounts[string] = @([s_stringCounts[string] intValue] + 1);
}

void decrementCountForString(NSString *string) {
	s_stringCounts[string] = @([s_stringCounts[string] intValue] - 1);
}

void logCountForString(NSString *string) {
	MMLog(@"%@: %@", string, s_stringCounts[string]);
}
