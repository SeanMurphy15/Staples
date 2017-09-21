//
//  ChatterKitObject.m
//  chattest
//
//  Created by Guy Umbright on 4/11/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_ChatterKitObject.h"
#import "CK_Reference.h"

static NSDateFormatter *dateFormatter = nil;

@interface CK_ChatterKitObject ()
@property (nonatomic, strong, readwrite) NSDictionary* contents;
@end

@implementation CK_ChatterKitObject

@synthesize contents = _contents;

/////////////////////////////////////////
//
/////////////////////////////////////////
+(void) initialize
{
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss.SSS'Z'"];
    }
//2012-04-27T01:10:28.000Z
}

/////////////////////////////////////////
//
/////////////////////////////////////////
+ (id) withDictionary:(NSDictionary*) dict
{
#if !__has_feature(objc_arc)
    return [[[CK_ChatterKitObject alloc] initWithContents:dict] autorelease];
#else
    return [[CK_ChatterKitObject alloc] initWithContents:dict];
#endif
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (id) initWithContents:(NSDictionary*) dict
{
    if (self = [super init])
    {
        self.contents = dict;
    }

    return self;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSString*) stringForKey:(NSString*) key
{
    NSString* s = [self.contents objectForKey:key];
    
    if (s == (NSString*) [NSNull null])
    {
        return nil;
    }
    else
    {
        return s;
    }
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSURL*) URLForKey:(NSString*) key
{
    NSURL* url = nil;
    NSString* s = [self stringForKey:key];
    if (s != nil && (s != (NSString*)[NSNull null]))
    {
        url = [NSURL URLWithString:s];
    }
    
    return url;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSDate*) dateForKey:(NSString*) key
{
    NSString* s = [self stringForKey:key];
    
    if (s != nil)
    {
        NSDate* date = [dateFormatter dateFromString:s];
        return date;
    }
    
    return nil;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSNumber*) numberForKey:(NSString*) key
{
    NSNumber* n = [self.contents objectForKey:key];
    
    if (n != nil && ([n isKindOfClass: [NSNumber class]]))
    {
        return n;
    }

    return nil;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (BOOL) boolForKey:(NSString*) key
{
    BOOL result = NO;
    NSNumber* n = [self numberForKey:key];
    
    if (n != nil)
    {
        result = [n boolValue];
    }
    
    return result;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSInteger) integerForKey:(NSString*) key;
{
    NSInteger result = 0;
    NSNumber* n = [self numberForKey:key];
    
    if (n != nil)
    {
        result = [n integerValue];
    }
    
    return result;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
//- (CK_Reference*) referenceForKey:(NSString*) key
//{
//    NSDictionary* refDict = [self.contents objectForKey:key];
//    if (refDict != nil)
//    {
//        return [CK_Reference referenceWithDictonary:refDict];
//    }
//    return nil;
//}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (id) objectForKey:(NSString*) key
{
    NSDictionary* dict = [self.contents objectForKey:key];
    if (dict != nil && dict != (NSDictionary*)[NSNull null])
    {
#if !__has_feature(objc_arc)
        return [[[CK_ChatterKitObject alloc] initWithContents:dict] autorelease];
#else
        return [[CK_ChatterKitObject alloc] initWithContents:dict];
#endif
    }
    return nil;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSArray*) arrayForKey:(NSString*) key
{
    //object must point to array or dict
    
    id object = [self.contents objectForKey:key];
    
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray* arr = [self.contents objectForKey:key];
        NSMutableArray* result = nil;
        
        if (arr != nil && arr.count > 0)
        {
            result = [NSMutableArray arrayWithCapacity:arr.count];
            
            for (NSDictionary* dict in arr)
            {
#if !__has_feature(objc_arc)
                [result addObject:[[[CK_ChatterKitObject alloc] initWithContents:dict] autorelease] ];
#else
                [result addObject:[[CK_ChatterKitObject alloc] initWithContents:dict]];
#endif
            }
        }
        
        return result;
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        return [NSArray arrayWithObject:object];
    }
    else
    {
        return nil;  //???assert
    }
    
    
//    NSArray* arr = [self.contents objectForKey:key];
//    NSMutableArray* result = nil;
//    
//    if (arr != nil && arr.count > 0)
//    {
//        result = [NSMutableArray arrayWithCapacity:arr.count];
//        
//        for (NSDictionary* dict in arr)
//        {
//            [result addObject:[CK_MessageSegment messageSegmentWithDictionary:dict]];
//        }
//    }
//    return result;
}

@end
