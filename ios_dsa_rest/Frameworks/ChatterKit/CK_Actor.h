//
//  Actor.h
//  chattest
//
//  Created by Guy Umbright on 4/12/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_ChatterKitObject.h"

#define CK_ActorKey_Type @"type"
#define CK_ActorKey_Name @"name"
#define CK_ActorKey_Id @"id"
#define CK_ActorKey_MySubscription @"mySubscription"
#define CK_ActorKey_URL @"url"

enum 
{
    CK_ActorType_UserSummary=0,
    CK_ActorType_RecordSummary,
    CK_ActorType_Group,
    CK_ActorType_UnauthenticatedUser,
    CK_ActorType_Unknown=-1
};

@interface CK_ChatterKitObject (CK_Actor)
- (NSInteger) actorType;
@end

@interface CK_Actor : CK_ChatterKitObject
@end
