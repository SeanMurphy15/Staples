//
//  ContentItemHistory.m
//  ios_dsa
//
//  Created by Guy Umbright on 9/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentItemHistory.h"

#import "MMSF_ContentVersion.h"
#import "DSA_AppDelegate.h"

#define MAX_HISTORY_SIZE 30
#define ITEM_HISTORY_DEFAULTS_KEY @"contentItemHistory"
#define COMPATIBILITY_CHECK_DONE  @"compatibilityCheckDone"

@implementation ContentItemHistory

////////////////////////////////////////////
//
////////////////////////////////////////////
- (id)init
{
    self = [super init];
    if (self) 
    {
        NSArray* arr = [[NSUserDefaults standardUserDefaults] objectForKey:ITEM_HISTORY_DEFAULTS_KEY];
        if (arr == nil)
        {
            history = [[NSMutableArray alloc] init];
        }
        else
        {
            history = [[NSMutableArray alloc] initWithArray:arr];
        }
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:COMPATIBILITY_CHECK_DONE] == NO)
        [self ensureBackwardCompatibility];

        
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(contentitemViewed:) 
                                                     name:ContentItemHistoryItemViewedNotification 
                                                   object:nil];
    }
    
    return self;
}

- (void) clearHistory {
	[history removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: ITEM_HISTORY_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

////////////////////////////////////////////
//
////////////////////////////////////////////
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) ensureBackwardCompatibility
{
    
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    
      for(id item in history)
      {
          if([item isKindOfClass:[NSString class]])
          {
              NSDictionary *dict = [NSDictionary   dictionaryWithObjects:[NSArray arrayWithObjects:item,@"",nil]
                                                                 forKeys:[NSArray arrayWithObjects:@"contentVersionID",@"configName",nil]];
              [newArray addObject:dict];
          }
          
      }
    
      [history removeAllObjects];
       history = newArray;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:COMPATIBILITY_CHECK_DONE];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void) addItem: (MMSF_ContentVersion*) item {
    NSString* contentVersionSFID = item.Id;
    NSString* configName = [g_appDelegate.selectedMobileAppConfig TitleText__c];
    NSDictionary *historyItemInfo = @{@"contentVersionID" : contentVersionSFID, @"configName" : configName};
    
    // if the item is already in the history remove it
    if ([history containsObject:historyItemInfo]) {
        [history removeObject:historyItemInfo];
    }

    // add the item at the top of the list
    [history insertObject:historyItemInfo atIndex:0];
    
    // truncate the history
    if (history.count > MAX_HISTORY_SIZE) {
        [history removeLastObject];
    }
    
    NSArray* arr = [NSArray arrayWithArray:history];
    [[NSUserDefaults standardUserDefaults] setObject: arr forKey:ITEM_HISTORY_DEFAULTS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

////////////////////////////////////////////
//
////////////////////////////////////////////
- (void) contentitemViewed: (NSNotification*) notification {
    NSString *itemId = notification.object;
    MMSF_ContentVersion* item = [MMSF_ContentVersion contentItemBySalesforceId:itemId];
    if (item) {
        [self addItem:item];
    }
}

////////////////////////////////////////////
//
////////////////////////////////////////////
- (void) scrubHistory		//FIXME: pass in a context 
{
    NSMutableArray* scrubbedItems = [NSMutableArray array];
    
	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;

    for (NSDictionary *dict in history)
    {
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"Id = %@",[dict objectForKey:@"contentVersionID"]];
        if ([moc numberOfObjectsOfType: @"ContentVersion" matchingPredicate: pred] == 0){
            [scrubbedItems addObject:dict];
        }
    }
    
    if (scrubbedItems.count)
    {
        [history removeObjectsInArray:scrubbedItems];
        NSArray* arr = [NSArray arrayWithArray:history];
        [[NSUserDefaults standardUserDefaults] setObject: arr forKey:ITEM_HISTORY_DEFAULTS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

////////////////////////////////////////////
//
////////////////////////////////////////////
- (NSArray*) contentItemHistory
{
    [self scrubHistory];
    return [NSArray arrayWithArray:history];
}
@end
