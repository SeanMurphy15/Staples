//
//  CK_UserDetail.h
//  chatterkitdemo
//
//  Created by Guy Umbright on 8/28/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_UserSummary.h"

#define CK_UserDetailKey_AboutMe @"aboutMe"
#define CK_UserDetailKey_Address @"address"
#define CK_UserDetailKey_ChatterActivity @"chatterActivity"
#define CK_UserDetailKey_ChatterInfluence @"chatterInfluence"
//currentStatus
#define CK_UserDetailKey_Email @"email"
#define CK_UserDetailKey_FollowersCount @"followersCount"
#define CK_UserDetailKey_FollowingCounts @"followingCounts"
#define CK_UserDetailKey_GroupCount @"groupCount"
#define CK_UserDetailKey_Manager @"managerId"
#define CK_UserDetailKey_ManagerName @"managerName"
#define CK_UserDetailKey_PhoneNumbers @"phoneNumbers"
#define CK_UserDetailKey_Username @"username"

@interface CK_UserDetail : CK_UserSummary

@end
