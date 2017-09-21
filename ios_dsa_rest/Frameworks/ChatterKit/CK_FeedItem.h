//
//  FeedItem.h
//  chattest
//
//  Created by Guy Umbright on 4/11/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CK_ChatterKitObject.h"
#import "CK_Reference.h"
#import "CK_ClientInfo.h"
#import "CK_Actor.h"
#import "CK_FeedBody.h"
#import "CK_Attachment.h"
#import "CK_MessageSegment.h"
#import "CK_CommentPage.h"
#import "CK_LikePage.h"

///////////////////////
#define CK_FeedItemKey_Actor @"actor"
#define CK_FeedItemKey_Body @"body"
#define CK_FeedItemKey_ClientInfo @"clientInfo"
#define CK_FeedItemKey_CreatedDate @"createdDate"
//#define CK_FeedItemKey_currentUserLike @"currentUserLike"
#define CK_FeedItemKey_Event @"event"
#define CK_FeedItemKey_Id @"id"
#define CK_FeedItemKey_IsBookmarkedByCurrentUser @"isBookmarkedByCurrentUser"
#define CK_FeedItemKey_IsLikedByCurrentUser @"isLikedByCurrentUser"
#define CK_FeedItemKey_MyLike @"myLike"
#define CK_FeedItemKey_ModifiedDate @"modifiedDate"
#define CK_FeedItemKey_OriginalFeedItemActor @"originalFeedItemActor"
#define CK_FeedItemKey_OriginalFeedItem @"originalFeedItem"
//#define CK_FeedItemKey_OriginalFeedItemActor @"originalFeedItemActor"
#define CK_FeedItemKey_Parent @"parent"
#define CK_FeedItemKey_PhotoUrl @"photoUrl"
#define CK_FeedItemKey_Type @"type"
#define CK_FeedItemKey_URL @"url"
#define CK_FeedItemKey_Comments @"comments"
#define CK_FeedItemKey_Likes @"likes"
#define CK_FeedItemKey_Attachment @"attachment"

///////////////////////
@interface CK_FeedItem : CK_ChatterKitObject



@end
