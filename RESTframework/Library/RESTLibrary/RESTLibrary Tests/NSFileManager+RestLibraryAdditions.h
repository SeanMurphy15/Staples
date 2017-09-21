//
//  NSFileManager+RestLIbraryAdditions.h
//  RESTLibrary
//
//  Created by Cory D. Wiles on 12/11/13.
//  Copyright (c) 2013 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (RestLibraryAdditions)

+ (void)swizzle_fileAtURLNotBackedUp:(NSURL *)url;

@end
