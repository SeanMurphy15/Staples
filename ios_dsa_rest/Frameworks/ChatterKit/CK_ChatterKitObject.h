//
//  ChatterKitObject.h
//  chattest
//
//  Created by Guy Umbright on 4/11/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CK_Reference;

@interface CK_ChatterKitObject : NSObject

@property (nonatomic, strong, readonly) NSDictionary* contents;

+ (id) withDictionary:(NSDictionary*) dict;

- (id) initWithContents:(NSDictionary*) dict;

- (NSString*) stringForKey:(NSString*) key;
- (NSURL*) URLForKey:(NSString*) key;
- (NSDate*) dateForKey:(NSString*) key;
- (BOOL) boolForKey:(NSString*) key;
- (NSInteger) integerForKey:(NSString*) key;
- (NSNumber*) numberForKey:(NSString*) key;
- (id) objectForKey:(NSString*) key;
- (NSArray*) arrayForKey:(NSString*) key;

@end
