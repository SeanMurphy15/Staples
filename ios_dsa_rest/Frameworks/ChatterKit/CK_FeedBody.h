//
//  FeedBody.h
//  chattest
//
//  Created by Guy Umbright on 4/12/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_ChatterKitObject.h"
#import "CK_MessageSegment.h"
#import "CK_CommentPage.h"

#define CK_FeedBodyKey_Text @"text"
#define CK_FeedBodyKey_MessageSegments @"messageSegments"

@interface CK_FeedBody : CK_ChatterKitObject

@property (weak, nonatomic, readonly) NSArray* messageSegments;
@property (weak, nonatomic, readonly) NSString* text;

@end
