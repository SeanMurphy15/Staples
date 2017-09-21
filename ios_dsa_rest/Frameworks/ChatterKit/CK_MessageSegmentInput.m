//
//  MessageSegmentInput.m
//  chattest
//
//  Created by Guy Umbright on 8/23/12.
//
//

#import "CK_MessageSegmentInput.h"

@interface CK_MessageSegmentInput ()

- (void) addKeys:(NSMutableDictionary*) dict;

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_MessageSegmentInput

////////////////////////////
//
////////////////////////////
- (NSString*) messageSegmentInputType
{
    NSAssert(NO, @"messageSegmentInputType must be overridden by subclass");
    return nil;
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:[self messageSegmentInputType] forKey:@"type"];
}

////////////////////////////
//
////////////////////////////
- (NSDictionary*) asDictionary
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [self addKeys:dict];
    
    return dict;
}

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_MessageSegmentInputHashtag

////////////////////////////
//
////////////////////////////
+ (CK_MessageSegmentInputHashtag*) messageSegmentWithHashtag:(NSString*) s
{
    CK_MessageSegmentInputHashtag* segment = [[CK_MessageSegmentInputHashtag alloc] init];
    segment.hashtag = s;
#if !__has_feature(objc_arc)
    return [segment autorelease];
#else
    return segment;
#endif
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:self.hashtag forKey:@"tag"];
    [super addKeys:dict];
}

////////////////////////////
//
////////////////////////////
- (NSString*) messageSegmentInputType
{
    return @"Hashtag";
}

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_MessageSegmentInputLink

////////////////////////////
//
////////////////////////////
+ (CK_MessageSegmentInputLink*) messageSegmentWithLink:(NSURL*) u
{
    CK_MessageSegmentInputLink* segment = [[CK_MessageSegmentInputLink alloc] init];
    segment.url = u;
#if !__has_feature(objc_arc)
    return [segment autorelease];
#else
    return segment;
#endif
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:[self.url absoluteString] forKey:@"url"];
    [super addKeys:dict];
}

////////////////////////////
//
////////////////////////////
- (NSString*) messageSegmentInputType
{
    return @"Link";
}

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_MessageSegmentInputMention

////////////////////////////
//
////////////////////////////
+ (CK_MessageSegmentInputMention*) messageSegmentWithMention:(NSString*) s
{
    CK_MessageSegmentInputMention* segment = [[CK_MessageSegmentInputMention alloc] init];
    segment.mentionId = s;
#if !__has_feature(objc_arc)
    return [segment autorelease];
#else
    return segment;
#endif
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:self.mentionId forKey:@"id"];
    [super addKeys:dict];
}

////////////////////////////
//
////////////////////////////
- (NSString*) messageSegmentInputType
{
    return @"Mention";
}

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_MessageSegmentInputText

////////////////////////////
//
////////////////////////////
+ (CK_MessageSegmentInputText*) messageSegmentWithText:(NSString*) s
{
    CK_MessageSegmentInputText* segment = [[CK_MessageSegmentInputText alloc] init];
    segment.text = s;
#if !__has_feature(objc_arc)
    return [segment autorelease];
#else
    return segment;
#endif
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:self.text forKey:@"text"];
    [super addKeys:dict];
}

////////////////////////////
//
////////////////////////////
- (NSString*) messageSegmentInputType
{
    return @"Text";
}

@end