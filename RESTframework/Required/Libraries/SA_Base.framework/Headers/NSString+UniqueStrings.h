//
//  NSString+UniqueStrings.h
//  Cuirl
//
//  Created by Ben Gottlieb on 12/18/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_UniqueStrings)

+ (NSString *) uuid;
+ (NSString *) guid;
+ (NSString *) tempFilename;
+ (NSString *) tempFilenameWithExtension: (NSString *) extension;

@end
