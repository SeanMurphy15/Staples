//
//  NSFileManager+RestLIbraryAdditions.m
//  RESTLibrary
//
//  Created by Cory D. Wiles on 12/11/13.
//  Copyright (c) 2013 Stand Alone, Inc. All rights reserved.
//

#import "NSFileManager+RestLibraryAdditions.h"
#import <objc/runtime.h>

@implementation NSFileManager (RestLibraryAdditions)

+ (void)initialize {

  Method original, swizzle;
  
  original = class_getClassMethod(self, @selector(setFileAtURLNotBackedUp:));

  swizzle = class_getClassMethod(self, @selector(swizzle_fileAtURLNotBackedUp:));

  method_exchangeImplementations(original, swizzle);
}

+ (void)swizzle_fileAtURLNotBackedUp:(NSURL *)url {
  NSLog(@"empty method implementation");
}

@end
