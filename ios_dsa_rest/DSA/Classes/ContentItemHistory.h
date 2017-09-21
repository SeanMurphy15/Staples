//
//  ContentItemHistory.h
//  ios_dsa
//
//  Created by Guy Umbright on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ContentItemHistoryItemViewedNotification @"com.modelmetrics.contentitemViewed"

@interface ContentItemHistory : NSObject
{
    NSMutableArray* history;
}

- (NSArray*) contentItemHistory;
- (void) clearHistory;
@end
