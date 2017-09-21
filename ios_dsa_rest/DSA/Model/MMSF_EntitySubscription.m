//
//  MMSF_EntitySubscription.m
//  DSA
//
//  Created by Guy Umbright on 4/22/15.
//  Copyright (c) 2015 Salesforce. All rights reserved.
//

#import "MMSF_EntitySubscription.h"
#import "MMSF_DSA_Playlist__c.h"

@implementation MMSF_EntitySubscription

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (NSArray*) allParentIds
{
    __block NSMutableArray* result = [NSMutableArray array];
    NSManagedObjectContext  *mainContext = [MM_ContextManager sharedManager].contentContextForWriting;

    NSArray* subs = [mainContext allObjectsOfType:@"EntitySubscription" matchingPredicate:nil];
    [subs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* s = [obj valueForKey:@"ParentId"];
        [result addObject:s];
    }];
    
    return result;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (NSArray*) entitySubscriptionsForPlaylist:(MMSF_DSA_Playlist__c*) playlist
{
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"ParentId == %@",[playlist valueForKey:@"Id"]];
    NSArray* result = [[MM_ContextManager sharedManager].threadContentContext allObjectsOfType:@"EntitySubscription" matchingPredicate:pred];
    return result;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (void) willSyncWithQuery: (MM_SOQLQueryString *) query
{
    //delete all current subs
    [[MM_ContextManager sharedManager].threadContentContext deleteObjectsOfType:@"EntitySubscription" matchingPredicate:nil];
}


@end
