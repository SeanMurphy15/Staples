//
//  Group.h
//  chattest
//
//  Created by Guy Umbright on 4/12/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_Actor.h"

#define CK_UserSummaryKey_IsChatterGuest @"isChatterGuest"
#define CK_UserSummaryKey_Description @"description"
#define CK_UserSummaryKey_FileCount @"fileCount"
#define CK_UserSummaryKey_LastFeedItemPostDate @"lastFeedItemPostDate"
#define CK_UserSummaryKey_memberCount @"memberCount"
#define CK_UserSummaryKey_myRole @"myRole"
#define CK_UserSummaryKey_Owner @"owner"
#define CK_UserSummaryKey_Photo @"photo"
#define CK_UserSummaryKey_Visibility @"visibility"

@interface CK_Group : CK_Actor

@end
