//
//  MMSF_EntitySubscription.h
//  DSA
//
//  Created by Guy Umbright on 4/22/15.
//  Copyright (c) 2015 Salesforce. All rights reserved.
//

#import "MMSF_Object.h"

@class MMSF_DSA_Playlist__c;

@interface MMSF_EntitySubscription : MMSF_Object 

+ (NSArray*) allParentIds;
+ (NSArray*) entitySubscriptionsForPlaylist:(MMSF_DSA_Playlist__c*) playlist;
- (void) syncWithQuery: (MM_SOQLQueryString *) query;
@end
