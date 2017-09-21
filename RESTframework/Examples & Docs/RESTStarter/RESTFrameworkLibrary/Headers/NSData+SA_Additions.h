//
//  NSData+SA_Additions.h
//
//  Created by Ben Gottlieb on 1/5/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NSData_SA_Additions)

+ (NSData *) dataWithString: (NSString *) string;
+ (NSData *) dataWithBase64EncodedString: (NSString *) aString;

- (NSString *) descriptionWithLineWidth: (int) lineWidth includingHex: (BOOL) includingHex includingASCII: (BOOL) includingASCII;


- (NSString *) SA_base64Encoded;
- (NSString *) SA_base64EncodingWithLineLength:(unsigned int) lineLength;
- (NSString *) stringValue;
- (NSString *) saveToTempFile;
- (NSString *) hexStringWithSpaces: (BOOL) spaces;
- (NSUInteger) offsetOfBytes: (unsigned char *) bytes length: (NSUInteger) length;
- (NSUInteger) offsetOfBytes: (unsigned char *) bytes length: (NSUInteger) length inRange: (NSRange) range;
- (BOOL) nullTerminateIfPossible;
- (BOOL) appearsToBeXML;
- (NSData *) SHA1DataWithKeyText: (NSString *) keyText;

//- (NSArray *) convertToCSVRecords;
@end
