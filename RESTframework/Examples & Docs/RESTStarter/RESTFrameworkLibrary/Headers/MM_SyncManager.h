//
//  MM_SyncManager.h
//
//  Created by Ben Gottlieb on 11/14/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MM_RestOperation.h"
#import "MM_SFObjectDefinition.h"
#import "MM_SyncStatus.h"
#import "MM_SOQLQueryString.h"

@class MMSF_Object;

typedef NS_ENUM(UInt8, syncType) {
	syncType_none,
	syncType_initial,
	syncType_continuation,
	syncType_delta,
	syncType_fullResync
};

typedef NS_ENUM(UInt8, syncFailureHandling) {
	syncFailureHandling_none,
	syncFailureHandling_autoPerformDelta,
};

@interface MM_SyncManager : NSObject

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(MM_SyncManager, sharedManager);

@property (nonatomic, readonly) dispatch_queue_t parseDispatchQueue, syncDispatchQueue;
@property (nonatomic) NSInteger maxSimultaneousConnections;
@property (nonatomic, readonly) NSArray *objectsToSync;
@property (nonatomic, strong) NSArray *lastSyncedObjectNames;
@property (nonatomic) BOOL isModelUpdateInProgress, isSyncInProgress, hasSyncedOnce, queueStopped, syncInterrupted, syncCancelled, areOperationsInFlight;
@property (nonatomic, strong) NSMutableArray *pending, *active, *cleanup, *pendingObjectNames;
@property (nonatomic, strong) NSMutableDictionary *remainingObjectDependencies;
@property (nonatomic) BOOL oauthValidated, oauthValidating, cycleOfDependencyAlertShown, autorefreshDisabled, allowIncompleteObjectSyncs, fullRelinkRequired, useAtomicSync;
@property (nonatomic) syncType currentSyncType;
@property (nonatomic, strong) NSDate *lastDependencyLock;
@property (nonatomic) NSUInteger maxAttachmentSize;
@property (nonatomic, strong) NSString *currentObjectName;
@property (nonatomic, strong) NSMutableSet *objectTypesToReLink;
@property (nonatomic) syncFailureHandling syncFailureHandling;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (nonatomic, weak) NSTimer *backgroundTerminationTimer;


- (void) performFullSyncWithCompletion: (booleanArgumentBlock) completion;
- (void) performDeltaSyncWithCompletion: (booleanArgumentBlock) completion;

//legacy sync methods
- (BOOL) fetchRequiredMetaData: (BOOL) refetch withCompletionBlock: (simpleBlock) completionBlock;			//this will automatically kick off a sync when its complete if no block is passed
- (BOOL) downloadObjectDefinitionsWithCompletionBlock: (simpleBlock) block;
- (void) syncDefaultObjectSet;
- (BOOL) synchronize: (NSArray *) objects withCompletionBlock: (booleanArgumentBlock) completionBlock;
- (BOOL) fullResync: (NSArray *) objects withCompletionBlock: (booleanArgumentBlock) completionBlock;
- (BOOL) deltaSyncWithCompletionBlock: (booleanArgumentBlock) completionBlock;
- (BOOL) resyncAllDataIncludingMetadata: (BOOL) resyncMetadata withCompletionBlock: (booleanArgumentBlock) completionBlock;

- (BOOL) cancelSync;

- (void) queueOperation: (MM_RestOperation *) op;
- (void) queueOperation: (MM_RestOperation *) op atFrontOfQueue: (BOOL) atFrontOfQueue;
- (void) dequeueOperation: (MM_RestOperation *) op completed: (BOOL) completed;
- (void) stopQueue;


+ (id) currentUserInContext: (NSManagedObjectContext *) ctx;

- (BOOL) areDependenciesMetForObject: (NSString *) objectName;
- (void) markObjectAsSynced: (MM_SFObjectDefinition *) objectDef;
- (void) queuePendingDefinitionSync: (MM_SFObjectDefinition *) objectDef;
- (void) connectMissingLinks;
- (BOOL) areOperationsPendingForObjectType: (NSString *) objectName;

- (void) validateOAuthWithCompletionBlock: (simpleBlock) block;
- (void) validateLogoutWithCallback: (booleanArgumentBlock) completion;
- (void) connectionStateChanged: (NSNotification *) note;

- (void) receivedError: (NSError *) error forQuery: (MM_SOQLQueryString *) query;

+ (void) incrementParseCount;
+ (void) decrementParseCount;
+ (BOOL) isParsing;

- (void) clearAllObjectsOfType: (NSString *) type;
- (BOOL) shouldSyncResume;

@end
