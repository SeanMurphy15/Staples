//
//  NSString+SA_Additions.h
//
//  Created by Ben Gottlieb on 7/28/06.
//  Copyright 2006 Stand Alone, Inc.. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#endif

#define		CHAR_IS_NUMERIC(c)				(c >= '0' && c <= '9')
#define		CHAR_IS_NONNUMERIC(c)			(c < '0' || c > '9')
#define		CHAR_IS_ALPHA(c)				((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))
#define		CHAR_IS_NONALPHA(c)				(!CHAR_IS_ALPHA(c))
#define		CHAR_IS_ALPHANUMERIC(c)			(CHAR_IS_ALPHA(c) || CHAR_IS_NUMERIC(c))
#define		CHAR_IS_NONALPHANUMERIC(c)		(!CHAR_IS_ALPHA(c) && !CHAR_IS_NUMERIC(c))


@interface NSString (SA_Additions)
@property (nonatomic, readonly) NSArray *characters;

+ (NSString *) tempFileNameWithSeed: (NSString *) seed ofType: (NSString *) type;
+ (NSString *) stringWithDuration: (float) seconds showingHours: (BOOL) showHours;
+ (NSString *) stringWithDuration: (float) fullSeconds showingHours: (BOOL) showHours showMinutes: (BOOL) showMinutes andSeconds: (BOOL) showSeconds;
+ (NSString *) stringWithData: (NSData *) data;
//+ (NSString *) stringWithFormat: (NSString *) format array: (NSArray *) arguments;

- (NSString *) stringByStrippingCharactersInSet: (NSCharacterSet *) set options: (int) options;

+ (NSString *) stringWithCGSize: (CGSize) size;
- (CGSize) CGSizeValue;

- (NSArray *) URLsContainedWithin;

- (NSArray *) componentsSeparatedByStringHeedingQuotes: (NSString *) string;
- (NSArray *) componentsSeparatedByCharactersInSetHeedingQuotes: (NSCharacterSet *) set;
- (BOOL) ensurePathExists;
- (BOOL) endsWith: (NSString *) suffix;
- (BOOL) endsWith: (NSString *) suffix options: (int) options;
- (NSString *) stringByPrettyingForURL;
- (NSString *) stringByPrettyingForPOSTBody;
- (NSRange) fullRange;
- (NSString *) stringByStrippingFirstNWords: (int) n;
- (NSString *) truncateToLength: (int) length;
- (NSInteger) numberOfOccurrencesOfString: (NSString *) string;
- (char *) UTF8StringCopy;
- (BOOL) isValidEmail;
- (BOOL) boolValue;

#if TARGET_OS_IPHONE
	- (NSString *) stringTruncatedToWidth: (float) width usingFont: (UIFont *) font addingElipsis: (BOOL) addingElipsis;
	- (CGSize) SA_sizeWithFont: (UIFont *) font;
	- (CGSize) SA_sizeWithFont: (UIFont *)font constrainedToSize: (CGSize) size lineBreakMode: (NSLineBreakMode) lineBreakMode;

#else
	- (CGSize) sizeWithFont: (NSFont *) font;
#endif

- (NSString *) stringByConvertingXMLToUTF8;
- (NSString *) stringByConvertingUTF8ToXML;

- (BOOL) isEqualToName: (NSString *) name;
- (BOOL) containsCString: (const char *) string;
- (BOOL) startsWithCString: (const char *) string;
- (BOOL) containsNumber: (int) number;
- (BOOL) containsWord: (const char *) word;

- (NSString *) rot13;
- (NSString *) stringByStrippingTags;
- (NSString *) stringByStrippingHTMLTags;

@end

@interface NSAttributedString (SA_Additions)			//NSFontAttributeName
#if TARGET_OS_IPHONE
+ (id) stringWithString: (NSString *) string;
+ (id) stringWithString: (NSString *) string attributes: (NSDictionary *) attr;
#endif
@end

@interface NSMutableAttributedString (SA_Additions)
#if TARGET_OS_IPHONE
- (void) setFont: (UIFont *) font;
- (void) setColor: (UIColor *) color;
#endif
@end

