//
//  NSString+MD5.h
//  Stickie Reader
//
//  Created by Ben Gottlieb on 3/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SA_MD5)
- (NSString *) MD5;
- (NSUInteger) md5Hash;
@end
