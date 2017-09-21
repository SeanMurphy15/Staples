//
//  CK_Comment.h
//  chatterkitdemo
//
//  Created by Guy Umbright on 8/27/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_ChatterKitObject.h"
#import "CK_FeedItem.h"

#define CK_CommentKey_Attachment @"attachment"
#define CK_CommentKey_Body @"body"
#define CK_CommentKey_ClientInfo @"clientInfo"
#define CK_CommentKey_CreatedDate @"createdDate"
#define CK_CommentKey_FeedItem @"feedItem"
#define CK_CommentKey_Id @"id"
#define CK_CommentKey_IsDeleteRestricted @"isDeleteRestricted"
#define CK_CommentKey_MyLike @"myLike"
#define CK_CommentKey_Parent @"parent"
#define CK_CommentKey_Type @"type"
#define CK_CommentKey_URL @"url"
#define CK_CommentKey_User @"user"

@interface CK_Comment : CK_ChatterKitObject

@end
