//
//  MM_SyncStatus.m
//
//  Created by Ben Gottlieb on 9/4/13.
//
//

#import "MM_SyncStatus.h"
#import "MM_Headers.h"

#define SYNC_STATUS_KEY			@"SYNC_STATUS_mm"

@interface MM_SyncStatus ()
@property (nonatomic, strong) NSMutableArray *pendingObjects;
@property (nonatomic, strong) NSMutableSet *completedObjects, *inProgressObjects;
@end

@implementation MM_SyncStatus
SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(MM_SyncStatus, status);

- (id) init {
	if (self = [super init]) {
		NSDictionary			*lastSyncInfo = [[MM_ContextManager sharedManager].mainContentContext objectInPrimaryStoreMetadataForKey: SYNC_STATUS_KEY];
		
		if (lastSyncInfo) {
			self.pendingObjects = [lastSyncInfo[@"pending"] mutableCopy];
			self.inProgressObjects = [NSMutableSet setWithArray: lastSyncInfo[@"inProgress"] ?: @[]];
			self.completedObjects = [NSMutableSet setWithArray: lastSyncInfo[@"completed"] ?: @[]];
		}
	}
	return self;
}

- (BOOL) isSyncInProgress {
	return self.inProgressObjects.count || self.pendingObjects.count;
}

- (void) beginSyncWithObjectNames: (NSArray *) names {
	self.pendingObjects = names.mutableCopy;
	self.completedObjects = [NSMutableSet set];
	self.inProgressObjects = [NSMutableSet set];
}

- (void) markSyncComplete {
    MMLog(@"%s", __PRETTY_FUNCTION__);
	[[MM_ContextManager sharedManager].mainContentContext setObjectInPrimaryStoreMetadata: nil forKey: SYNC_STATUS_KEY];
	[[MM_ContextManager sharedManager] saveContentContext];
    
    // clean up when a successful delta sync fails to clear pending and in progress
    [self.inProgressObjects removeAllObjects];
    [self.pendingObjects removeAllObjects];
}

- (void) markObjectNameStarted: (NSString *) objectName {
	if (![MM_SyncManager sharedManager].isSyncInProgress) return;
	[self.pendingObjects removeObject: objectName];
	if (![self.inProgressObjects containsObject: objectName]) {
		[self.inProgressObjects addObject: objectName];
		[self storeInDatabase];
	}
}

- (void) markObjectNameComplete: (NSString *) objectName {
	if (![MM_SyncManager sharedManager].isSyncInProgress) return;
	if (![self.completedObjects containsObject: objectName]) {
		[self.completedObjects addObject: objectName];
		[self.inProgressObjects removeObject: objectName];
	}
}

- (void) storeInDatabase {
	NSDictionary		*info = @{
								  @"pending": self.pendingObjects ?: @[],
								  @"inProgress": self.inProgressObjects.allObjects ?: @[],
								  @"completed": self.completedObjects.allObjects ?: @[],
								  };
	[[MM_ContextManager sharedManager].mainContentContext setObjectInPrimaryStoreMetadata: info forKey: SYNC_STATUS_KEY];
	[[MM_ContextManager sharedManager] saveContentContext];
}

@end
