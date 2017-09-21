#import "MM_SFChange.h"
#import "MM_ContextManager.h"
#import "MM_SyncManager.h"
#import <SalesforceNativeSDK/SFRestRequest.h>
#import "MM_RestOperation.h"
#import "MM_Log.h"
#import <SalesforceNativeSDK/SFRestAPI.h>
#import "MMSF_Object.h"
#import "MM_Notifications.h"
#import "MM_SFObjectDefinition.h"
#import "MM_LoginViewController.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_Constants.h"

static BOOL						s_changesHaveBeenPushed = NO, s_queueStoppedDueToOffline = NO, s_changeSyncingInProgress = NO;
static NSMutableArray			*s_pushingCompletedBlocks = nil;
static NSUInteger				s_queueStopped = 0;
static NSTimeInterval			s_pendingObjectInterval = 1.0;
static dispatch_queue_t			s_changeProcessingQueue = nil;
static NSManagedObjectContext	*s_changesContentMoc = nil, *s_changesMetaMoc = nil;

inline BOOL s_IsQueueActive();
BOOL s_IsQueueActive() { return !s_queueStoppedDueToOffline && s_queueStopped == 0; }

#define SYNC_CHANGE_OP_TAG		@"MMSF_SYNC_CHANGE_OP_TAG"

@implementation MM_SFChange
+ (void) setPendingObjectInterval: (NSTimeInterval) interval { s_pendingObjectInterval = interval; }

+ (void) load {
	@autoreleasepool {
		s_changeProcessingQueue = dispatch_queue_create("com.modelmetrics.rframework.changeProcessingQueue", 0);
		s_pushingCompletedBlocks = [NSMutableArray array];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(connectionStateChanged:) name: kNotification_ConnectionStatusChanged object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didAuthenticate:) name: kNotification_DidAuthenticate object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cleanupChangesMoc) name: kNotification_DidLogOut object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cleanupChangesMoc) name: kNotification_DidLogIn object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cleanupChangesMoc) name: kNotification_SyncComplete object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cleanupChangesMoc) name: kNotification_SyncCancelled object: nil];
		
		[self performSelector: @selector(resetInProgressFlags) withObject: nil afterDelay: 0.1];
	}
}

+ (void) didAuthenticate: (NSNotification *) note {
    if ([[MM_SyncManager sharedManager] hasSyncedOnce]) {
        [self pushPendingChangesDeferred: 10.0];
    };
}

+ (BOOL) isChangeSyncingInProgress {
	return s_changeSyncingInProgress;
}

+ (NSUInteger) numberOfPendingChanges {
	return [[MM_ContextManager sharedManager].metaContextForWriting numberOfObjectsOfType: [self entityName] matchingPredicate: nil];
//	__block NSUInteger			count = 0;
//	dispatch_sync(s_changeProcessingQueue, ^{
//		[MM_SFChange setupChangesMoc];
	return [[MM_ContextManager sharedManager].threadMetaContext numberOfObjectsOfType: [self entityName] matchingPredicate: nil];
//	});
//	return count;
}

+ (void) setupChangesMoc {
	@synchronized(self) {
		if (s_changesContentMoc == nil) {
			s_changesContentMoc = [MM_ContextManager sharedManager].contentContextForWriting;
			s_changesContentMoc.saveThread = nil;
		}
		
		if (s_changesMetaMoc == nil) {
			s_changesMetaMoc = [MM_ContextManager sharedManager].metaContextForWriting;
			s_changesMetaMoc.saveThread = nil;
		}
	}
}

+ (void) cleanupChangesMoc {
	if (s_changesContentMoc || s_changesMetaMoc) @synchronized(self) {
		s_changesContentMoc = nil;
		s_changesMetaMoc = nil;
	}
}

+ (void) clearAllPendingChangesForUserID: (NSString *) sfID {
	dispatch_async(s_changeProcessingQueue, ^{
		[MM_SFChange setupChangesMoc];
		[s_changesMetaMoc deleteObjectsOfType: [self entityName] matchingPredicate: sfID ? $P(@"ownerSFID == %@", sfID) : nil];
		[s_changesMetaMoc save];
		[MM_ContextManager saveContentContext];
	});
}

+ (void) pushPendingChangesDeferred: (float) delay {    
	[NSObject performBlock: ^{
		dispatch_async(s_changeProcessingQueue, ^{
			//[self cleanupChangesMoc];
			if ([self numberOfPendingChanges] == 0) {
				[self completedPushingChanged: YES];
			} else {
				if ([self areChangesInFlight] || [self isPushingChangesStopped]) return;
				[[MM_SyncManager sharedManager] validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: ^(BOOL succeeded) {
					[self pushPendingChanges];
				}];
			}
		});
	} afterDelay: delay];
}

+ (void) connectionStateChanged: (NSNotification *) note {
	if (![SA_ConnectionQueue sharedQueue].offline) {
		s_queueStoppedDueToOffline = NO;
		if (s_IsQueueActive()) [self pushPendingChangesDeferred: 5.0];
	}
}

+ (void) completedPushingChanged: (BOOL) completed {
	for (booleanArgumentBlock block in s_pushingCompletedBlocks) {
		if (block) block(completed);
	}
	if (completed) @synchronized(s_pushingCompletedBlocks) {
		[NSManagedObject clearRobustObjectIDs];
		[s_pushingCompletedBlocks removeAllObjects];
	}
	@synchronized(s_pushingCompletedBlocks) {
		if (s_changeSyncingInProgress) {
			s_changeSyncingInProgress = NO;
			[NSNotificationCenter postNotificationNamed: kNotification_PushingChangesCompleted];
		}
	}
	[NSManagedObject cleanUpRobustObjectIDCache];
	[MM_SyncManager sharedManager].oauthValidated = NO;

}

+ (void) stopPushingChanges { 
	s_queueStopped++;
	[self completedPushingChanged: NO];
	
}

+ (BOOL) isPushingChanges {
    return s_changeSyncingInProgress;
}

+ (BOOL) isPushingChangesStopped { return s_queueStopped > 0; }

+ (void) startPushingChanges {
	if (s_queueStopped > 0) s_queueStopped--;
	if (s_IsQueueActive()) [self pushPendingChanges];
}

+ (void) forcePushRestart {
	s_queueStopped = 0;
	[self startPushingChanges];
}

MMSF_Change_Error_Behavior		s_changeErrorBehavior = MMSF_Change_Error_Behavior_Retain;
+ (MMSF_Change_Error_Behavior) changeErrorBehavior {
	return s_changeErrorBehavior;
}

+ (void) setChangeErrorBehavior: (MMSF_Change_Error_Behavior) behavior {
	s_changeErrorBehavior = behavior;
}

+ (void) queueChangeForObject: (MMSF_Object *) exteriorTarget withOriginalValues: (NSDictionary *) original changedValues: (NSDictionary *) changedValues atTime: (NSDate *) date andPush: (BOOL) andPush {
	[self queueChangeForObject: exteriorTarget withOriginalValues: original changedValues: changedValues retryCount: 0 atTime: date andPush: andPush];
}

+ (void) queueChangeForObject: (MMSF_Object *) exteriorTarget withOriginalValues: (NSDictionary *) original changedValues: (NSDictionary *) changedValues retryCount: (NSInteger) retryCount atTime: (NSDate *) date andPush: (BOOL) andPush {
	if (changedValues.count == 0) return;		//nothing to save
	if (exteriorTarget.moc.hasChanges) [exteriorTarget.moc save];
	if (![exteriorTarget shouldQueueChangeForOriginal: original toNewValues: changedValues atDate: date]) return;
	
	NSManagedObjectID			*targetID = exteriorTarget.objectID;
	NSString					*targetIDString = exteriorTarget.robustIDString;
	NSString					*sfID = exteriorTarget.Id;
	NSString					*entityName = exteriorTarget.entity.name;
	static NSArray				*queuedAtSort = nil;
	
	if (original == nil) original = exteriorTarget.snapshot;
	NSDictionary				*convertedOriginal = original.dictionaryByConvertingObjectsToIDs;
	

	[[MM_ContextManager sharedManager] saveContentContextWithBlock: ^{
		dispatch_async(s_changeProcessingQueue, ^{
			NSError								*error = nil;

			[MM_SFChange setupChangesMoc];
			//[s_changesContentMoc reset];
			

			__block MMSF_Object			*target = (id) [s_changesContentMoc objectWithID: targetID];
			[target.moc obtainPermanentIDsForObjects: @[ target ] error: &error];
			
			@try {
				MM_SFChange							*change = nil;

				target = (id) [target objectInContext: s_changesContentMoc];					//copy of the target from that. This should be what we actually work with
				
				if (target.isInserted) {			//should have been saved by now.
					if (retryCount > 5) {
						NSLog(@"Failed to save object %@ after %d attempts.", target, (UInt16) retryCount);
						return;
					}
					[NSObject performBlock: ^{
						[self queueChangeForObject: exteriorTarget withOriginalValues: original changedValues: changedValues retryCount: retryCount + 1 atTime: date andPush: andPush];
					} afterDelay: 3.0];
					return;
				}
				
				if (queuedAtSort == nil) queuedAtSort = [NSSortDescriptor SA_arrayWithDescWithKey: @"queuedAt" ascending: YES];
				change = [s_changesMetaMoc firstObjectOfType: [self entityName] matchingPredicate: $P(@"targetObjectID == %@", targetIDString) sortedBy: queuedAtSort];
				if (change && [change modifiedValuesInContext: s_changesContentMoc] == nil) {		//a delete change. remove it
					[change deleteFromContext];
					change = nil;
				}
				if (change == nil) {			//no pending change, create one
					change = [s_changesMetaMoc insertNewEntityWithName: [self entityName]];
					change.ownerSFID = [[MM_SyncManager currentUserInContext: s_changesContentMoc] Id];
					change.targetObjectID = targetIDString;
					change.targetEntity = entityName;
					change.targetSalesforceID = sfID;
					change.queuedAt = date;
					change.originalValuesData = [NSKeyedArchiver archivedDataWithRootObject: convertedOriginal];

					[change setModifiedValues: changedValues];
					change.isNewObjectValue = (sfID.length == 0);
				} else {						//we've already created (but not yet sent to the server) a list of changes. Here we'll take care of any overlap
					NSMutableDictionary					*newModifications = [change modifiedValuesInContext: s_changesContentMoc].mutableCopy;
					
					for (NSString *key in changedValues) {
						id				originalValue = [[change originalValuesInContext: s_changesContentMoc] valueForKey: key];
						id				newValue = [changedValues valueForKey: key];
						
						if ([newValue isEqual: [NSNull null]]) newValue = nil;
						
						if ([newValue isEqual: originalValue]) {		//they changed it back to what it was; remove the change
							[newModifications removeObjectForKey: key];
						} else {
							[newModifications setValue: newValue forKey: key];
						}
					}
					[change setModifiedValues: newModifications];
				}
				if (change.modifiedAt == nil || !change.isNewObjectValue) change.modifiedAt = [NSDate date];
				[change save];
				[[MM_ContextManager sharedManager] saveMetaContextWithBlock:^{
					if (andPush) [MM_SFChange pushPendingChangesWithCompletionBlock: nil];
				}];
			} @catch (id exception) {
				[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_QueueSaveError object: targetID userInfo: $D(exception, @"exception")];
			}
		});
	}];
	
	if (!s_IsQueueActive()) {
		[NSObject performBlock:^{
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_PendingChangeQueued object: nil];
		} afterDelay: 0.5];
	}
}

+ (void) queueDeleteForObject: (MMSF_Object *) object atTime: (NSDate *) date {
 //   if (!object.Id) return;				//no SFID, also done
   
    //copy those values before deleting an object
    NSString *salesforceId = object.Id;
    NSString *targetObjectID = object.robustIDString;
	
	if (salesforceId == nil) {
		LOG(@"No Salesforce ID found for %@, not deleting from SFDC.", object);
		return;
	}
	
    NSString *targetEntityName = object.entity.name;
    NSString *ownerSFID = [[MM_SyncManager currentUserInContext:object.moc] Id];
    
	dispatch_async(s_changeProcessingQueue, ^{
		MM_SFChange					*change = nil;
		NSPredicate					*pred = $P(@"targetObjectID == %@", targetObjectID);
		
		[MM_SFChange setupChangesMoc];

		change = [s_changesMetaMoc anyObjectOfType: [self entityName] matchingPredicate: pred];
		if (change.inProgressValue && salesforceId == nil) {
			change.targetEntity = nil;
			[change save];
			change = nil;
		}
		
		[change deleteFromContext];			//remove any pending changes. 
		
		if (salesforceId != nil) {
			change = [s_changesMetaMoc insertNewEntityWithName: [self entityName]];
			change.targetSalesforceID = salesforceId;
			change.queuedAt = date;
			change.ownerSFID = ownerSFID;//[MM_SyncManager currentUserInContext: objectCopy.moc].Id;
			change.targetEntity = targetEntityName;
			change.targetObjectID = targetObjectID;
			change.modifiedAt = [NSDate date];
			[change save];
		}
		[[MM_ContextManager sharedManager] saveMetaContextWithBlock:^{
			[MM_SFChange pushPendingChanges];
		}];

		if (!s_IsQueueActive()) {
			[NSObject performBlock:^{
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_PendingChangeQueued object: nil];
			} afterDelay: 0.5];
		}
	});
}

+ (void) resetInProgressFlags {
	dispatch_async(s_changeProcessingQueue, ^{
		BOOL			save = NO;
		[MM_SFChange setupChangesMoc];
		
		for (MM_SFChange *change in [s_changesMetaMoc allObjectsOfType: [self entityName] matchingPredicate: $P(@"inProgress == 1")]) {
			change.inProgressValue = NO;
			save = YES;
		}
		if (save) {
			[s_changesMetaMoc save];
			[MM_ContextManager saveMetaContext];
		}
	});
}

+ (void) resetErrors {
	dispatch_async(s_changeProcessingQueue, ^{
		[MM_SFChange setupChangesMoc];
		
		for (MM_SFChange *change in [s_changesMetaMoc allObjectsOfType: [self entityName] matchingPredicate: $P(@"error != nil")]) {
			change.error = nil;
		}
		[s_changesMetaMoc save];
		[MM_ContextManager saveMetaContext];
	});
}

- (void) rollback {
	dispatch_async(s_changeProcessingQueue, ^{
		[MM_SFChange setupChangesMoc];
		
		NSManagedObjectContext				*metaMoc = s_changesMetaMoc, *contentMoc = s_changesContentMoc;
		MM_SFChange							*change = [self objectInContext: metaMoc];
		MMSF_Object							*target = [contentMoc objectWithRobustIDString: change.targetObjectID];
		NSDictionary						*originalValues = (NSDictionary *) [change originalValuesInContext: contentMoc];
		NSString							*objectID = target.robustIDString;
		
		if (change.modifiedValuesData == nil) {
			MMLog(@"Restoring object: %@", change.ownerSFID);
			if (target) {
				[target reloadFromServer];
			} else {
				target = [contentMoc insertNewEntityWithName: change.targetEntity];
				
				target.Id = change.targetObjectID;
				[target save];
				[target reloadFromServer];
			}
		} else {
			[target rollbackToSnapshot: originalValues];
		}
		[contentMoc save];
		[change deleteFromContext];
		[metaMoc save];
		
		MMLog(@"Deleted change, %d remaining", [metaMoc numberOfObjectsOfType: [MM_SFChange entityName] matchingPredicate: nil]);
		
		dispatch_async(dispatch_get_main_queue(), ^{ 
			[[MM_ContextManager sharedManager] saveContentContext];
			[[MM_ContextManager sharedManager] saveMetaContext];
			[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectChangesRolledBack object: objectID];
		});
	});
}

- (NSDictionary *) modifiedValuesWithIDsInContext: (NSManagedObjectContext *) ctx {
	NSMutableDictionary			*modifiedValues = [NSMutableDictionary dictionary];
	NSEntityDescription			*entity = [NSEntityDescription entityForName: self.targetEntity inManagedObjectContext: ctx];
	NSDictionary				*properties = entity.propertiesByName;
	NSString					*shadowSuffix = @"_objectid_shadow_mm";
	NSDictionary				*existing = (id) [self modifiedValuesInContext: ctx];
	MM_SFObjectDefinition		*def = [MM_SFObjectDefinition objectNamed: self.targetEntity inContext: nil];
	
	for (NSString *field in existing) {
		if ([field isEqual: MMID_FIELD]) continue;			//make sure the MM_ID is not passed up
		
		NSDictionary		*info = [def infoForField: field];
		if (self.targetSalesforceID && ![[info objectForKey: @"updateable"] boolValue]) continue;
		if (!self.targetSalesforceID && ![[info objectForKey: @"createable"] boolValue]) continue;

		BOOL				isShadow = [field hasSuffix: shadowSuffix];
		id					value = [existing objectForKey: field];
		
		if ([field isEqual: @"WhatId"]) value = [value Id];
		if ([field hasSuffix: SNAPSHOT_OBJECT_SUFFIX] || [field hasSuffix: SNAPSHOT_SFID_SUFFIX] || (!isShadow && [field hasSuffix: @"_mm"])) continue;
		if (isShadow) {
			MMSF_Object			*destination = [ctx objectWithRobustIDString: value];
			
			if (destination && destination.Id) {
				[modifiedValues setObject: destination.Id forKey: [field substringToIndex: field.length - shadowSuffix.length]];
			}
		} else if ([value isKindOfClass: [NSData class]]) {
			[modifiedValues setValue: [value SA_base64Encoded] forKey: field];
		} else  if ([[properties objectForKey: field] isKindOfClass: [NSAttributeDescription class]]) {
			if ([value isKindOfClass: [NSDate class]]) {
				[modifiedValues setValue: [value salesforceStringRepresentation] forKey: field];
			} else
				[modifiedValues setValue: value forKey: field];
		} else if ([value isKindOfClass: [NSSet class]]) {
			//MMLog(@"Modified values: %@", value);
		} else if ([value isKindOfClass: [NSManagedObject class]]) {
			[modifiedValues setValue: [value Id] forKey: field];
		} else if (![value isKindOfClass:[NSNull class]]) {
			MMSF_Object			*object = [ctx objectWithRobustIDString: value];
			
			if (object.Id) [modifiedValues setValue: object.Id forKey: field];
		} else {
			[modifiedValues setValue: value forKey: field];
		}
	}
	return modifiedValues;
}

+ (void) pushPendingChangesWithCompletionBlock: (booleanArgumentBlock) completion {
	if ([self numberOfPendingChanges] == 0 && s_pushingCompletedBlocks.count == 0) {
		if (completion) completion(YES);
		return;
	}
	@synchronized(s_pushingCompletedBlocks) {
		if (completion) [s_pushingCompletedBlocks addObject: completion];
	}
	
	[MM_SFChange pushPendingChangesDeferred: 1.0];
}

+ (BOOL) doesChangeExistForObject: (MMSF_Object *) object {
	NSManagedObjectContext		*ctx = s_changesMetaMoc;
	NSInteger							count = [ctx numberOfObjectsOfType: [self entityName] matchingPredicate: $P(@"targetObjectID == %@", object.robustIDString)];
	
	return (count > 0);
}

+ (BOOL) doesChangeExistForRobustIDString:(NSString*)robustID {
    NSManagedObjectContext		*ctx = s_changesMetaMoc;
	NSInteger							count = [ctx numberOfObjectsOfType: [self entityName] matchingPredicate: $P(@"targetObjectID == %@", robustID)];
	
	return (count > 0);
}

+ (void) removePendingChangesForObject: (MMSF_Object *) object {
	if (object == nil) return;
	
	NSString				*robustID = object.robustIDString;
	NSPredicate				*predicate = $P(@"targetObjectID == %@ && inProgress == NO", robustID);

	dispatch_async(s_changeProcessingQueue, ^{
		[self setupChangesMoc];
		NSManagedObjectContext		*ctx = s_changesMetaMoc;
		
		//[s_changesContentMoc obtainPermanentIDsForObjects: @[ local ] error: &error];
		NSArray						*changes = [ctx allObjectsOfType: [self entityName] matchingPredicate: predicate];
		
		MMLog(@"Removing %d pending changes for %@", changes.count, robustID);
		for (MM_SFChange *change in changes) {
			if (!change.inProgressValue) [change deleteFromContext];
		}
		[ctx save];
		[[MM_ContextManager sharedManager] saveMetaContext];
	});
}

+ (BOOL) areChangesInFlight {
	for (MM_RestOperation *op in [MM_SyncManager sharedManager].active) {
		if ([op.tag isEqual: SYNC_CHANGE_OP_TAG]) return YES;
	}

	for (MM_RestOperation *op in [MM_SyncManager sharedManager].pending) {
		if ([op.tag isEqual: SYNC_CHANGE_OP_TAG]) return YES;
	}
	return NO;
}


#pragma mark - Priority change selection

// Return first missing object from a change's target object
+ (MMSF_Object*) firstMissingDestinationFromChange:(MM_SFChange *)change {
    
    NSManagedObjectContext	* contentMoc = s_changesContentMoc;
    
    NSString            * objectIDString = change.targetObjectID;
    MMSF_Object         * target = [contentMoc objectWithRobustIDString: objectIDString];
    
    if(!target)         return nil;
    
    NSEntityDescription * entity = [target entity];
    NSDictionary        * relationships = [entity relationshipsByName];
    
    // Inspect relationships
    for (NSString       * relation in relationships) {
        
        id value = [target valueForKey: relation];
        
        // Only look at other MMSF_Objects
        if(value != nil && [value isKindOfClass:[MMSF_Object class]]) {
            
            MMSF_Object * destination = [contentMoc objectWithRobustIDString:
                                         [(MMSF_Object*)value objectIDString]];
            
            // Check for an Id
            if(![destination valueForKey:@"Id"]) {
                //NSLog(@"missing relationship: %@",relation);
                
                return destination; // This object has no SFID, so it would be bad to try and send a change related to it
            }
        }
    }
    
    return nil;
}


// Find a change record that is ready to be pushed, ie, it's related objects have Salesforce Ids
+ (MM_SFChange*) nextConnectedChange {
    
    NSManagedObjectContext	* contentMoc = s_changesContentMoc, * metaMoc = s_changesMetaMoc;
    NSArray                 * sortBy = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedAt" ascending:YES]];
    
    // Get all non-inProgress changes
    NSArray * allChanges = [metaMoc allObjectsOfType:[self entityName]
                                   matchingPredicate:$P(@"inProgress == 0")
                                            sortedBy:sortBy];
    
    // Find a change in which the target has SFIDs for any related MMSF_Objects
    for (MM_SFChange * aChange in allChanges) {
        
        NSString            * objectIDString = aChange.targetObjectID;
        MMSF_Object         * target = [contentMoc objectWithRobustIDString: objectIDString];
        
        if(!target)         {
            continue;
        }
        
        MMSF_Object * objectMissingID = [self firstMissingDestinationFromChange:aChange];
        
        if(objectMissingID == nil) return aChange; // This change is ready to be pushed
    }
    
    // Default change
    return [metaMoc firstObjectOfType: [self entityName]
                    matchingPredicate: $P(@"inProgress == 0")
                             sortedBy: sortBy];
}

#pragma mark -


+ (void) pushPendingChanges {
	if (![MM_LoginViewController isLoggedIn] || ![MM_LoginViewController isAuthenticated]) return;
	
	@synchronized(s_pushingCompletedBlocks) {
		if (!s_changeSyncingInProgress) {
			s_changeSyncingInProgress = YES;
			[NSNotificationCenter postNotificationNamed: kNotification_PushingChangesBegan];
		}
	}
	
	if (!s_IsQueueActive()) {
		dispatch_async(s_changeProcessingQueue, ^{
			[self completedPushingChanged: ([s_changesMetaMoc numberOfObjectsOfType: [self entityName] matchingPredicate: nil] == 0)];
		});
		return;
	}
	
	if ([SA_ConnectionQueue sharedQueue].offline || ![[SFNetworkEngine sharedInstance] isReachable]) {
		[self completedPushingChanged: NO];
		s_queueStoppedDueToOffline = YES;
		return;
	}
	
	
	NSManagedObjectContext		*contentMoc = s_changesContentMoc, *metaMoc = s_changesMetaMoc;
	if (contentMoc == nil || s_changesMetaMoc == nil) @synchronized(self) {
		[self setupChangesMoc];
		contentMoc = s_changesContentMoc;
		metaMoc = s_changesMetaMoc;
		if (contentMoc == nil || metaMoc == nil) {
			MMLog(@"***********************MISSING CONTEXTS*********************** %@", @"");
			[self completedPushingChanged: YES];
			return;
		}
	}
	
	STATIC_CONSTANT(NSArray, sortBy, [NSSortDescriptor SA_arrayWithDescWithKey: @"modifiedAt" ascending: YES]);
	
	if ([self areChangesInFlight]) {
		MMLog(@"Changes alreayd in flight, will try again later %@", @"");
		[MM_SFChange pushPendingChangesDeferred: 1.0];
		return;
	}
	
	MM_SFChange					*change = [MM_SFChange nextConnectedChange];
	NSManagedObjectID			*changeID = (id) change.objectID;
	NSString					*salesforceIDString = change.targetSalesforceID;
	NSString					*objectIDString = change.targetObjectID;
	BOOL						isDelete = NO;
	
	if (change) @synchronized(self) {
		SFRestRequest				*request;
		MM_RestOperation			*op;
		NSString					*entityName = change.targetEntity;
		#if ALLOW_OBJECT_REMAPPING
			MM_SFObjectDefinition		*def = [MM_SFObjectDefinition objectNamed: entityName inContext: nil];
			NSString					*serverName = def.serverObjectName_mm.length ? def.serverObjectName_mm : def.name;
		#else
			NSString					*serverName = entityName;
		#endif
		NSDictionary				*fields = (id) [change modifiedValuesWithIDsInContext: contentMoc];
		BOOL						isNewObject = change.isNewObjectValue;
		
		#if ALLOW_FIELD_REMAPPING
			serverName = [MM_SFObjectDefinition serverObjectNameForLocalName: entityName];
		#endif
		
		if (entityName == nil) {
			[change deleteFromContext];
			[metaMoc save];
			[MM_SFChange pushPendingChangesDeferred: 0.5];
			return;
		}
		[[MM_Log sharedLog] logFields: fields savedForObjectName: entityName];
		s_changesHaveBeenPushed = YES;
		if ([change modifiedValuesInContext: contentMoc] == nil) {		//deleting the object
			request = [[SFRestAPI sharedInstance] requestForDeleteWithObjectType: serverName objectId: change.targetSalesforceID];
			isDelete = YES;
		} else if (isNewObject) {
			request = [[SFRestAPI sharedInstance] requestForCreateWithObjectType: serverName fields: fields];
		} else {
			request = [[SFRestAPI sharedInstance] requestForUpdateWithObjectType: serverName objectId: salesforceIDString fields: fields];
		}
		//MMLog(@"Pushing change in %@: \n%@\n\n\n%@", serverName, fields, change.error ? $S(@"Prev Error: %@", change.error) : @"");
		if (fields.count || isDelete) {
			op = [MM_RestOperation operationWithRequest: request groupTag: nil completionBlock: ^(NSError *inError, id json, MM_RestOperation *completedOp) {
				dispatch_async(s_changeProcessingQueue, ^{
					MM_SFChange					*localChange = (id) [metaMoc objectWithID: changeID];
					MMSF_Object					*target = (isDelete || localChange.targetEntity == nil) ? nil : [contentMoc objectWithRobustIDString: objectIDString];
					NSError						*error = inError;
					BOOL						deleteChange = (s_changeErrorBehavior == MMSF_Change_Error_Behavior_Discard);
					
					MMLog(@"Pushed change to %@ (%@)", objectIDString, error ? error : @"");
					if (error && isDelete) {
						NSString					*errorCode = [error.userInfo objectForKey: @"errorCode"];
						
						if ([errorCode isEqual: @"ENTITY_IS_DELETED"] || [errorCode isEqual: @"NOT_FOUND"]) error = nil;
					}
					if (error) {
						if (!isDelete && [target shouldRollbackFailedSaves]) {
							deleteChange = YES;
							[localChange rollback];
						}
						BOOL						isNewError = ![error isEqual: localChange.error];
						
						localChange.error = error;
						//localChange.inProgressValue = NO;
						[[MM_Log sharedLog] logUploadError: error forChange: localChange];
						
						if (!isDelete) [target didFailToSaveToServerWithError: error];
						
						NSDictionary	*info = $D(error, @"error", fields, @"fields", change, @"change", target.robustIDString, @"targetId", @(isDelete), @"isDelete");
						
						if (isNewError) [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectSaveError object: target.robustIDString userInfo: info];

						if (deleteChange)
							[localChange deleteFromContext];
						else if (s_changeErrorBehavior == MMSF_Change_Error_Behavior_Alert) {
							NSString				*title = $S(@"An Error Occurred When %@ a %@", isDelete ? @"deleting" : @"saving", entityName);
							NSString				*message = error.localizedDescription;
							
							if (error.userInfo[@"message"]) message = error.userInfo[@"message"];
							if (!isNewObject) title = $S(@"%@ (id: %@", title, salesforceIDString);
							
							dispatch_async(dispatch_get_main_queue(), ^{
								[SA_AlertView showAlertWithTitle: title message: message buttons: @[ @"Discard", @"Re-Try"] buttonBlock: ^(NSInteger index) {
									if (index == 0) {
										dispatch_async(s_changeProcessingQueue, ^{ [localChange deleteFromContext]; [metaMoc save]; [[MM_ContextManager sharedManager] saveMetaContext]; });
									}
								}];
							});
						}
						[metaMoc save];
						[[MM_ContextManager sharedManager] saveMetaContext];
						[MM_SFChange pushPendingChangesDeferred: 0.5];
					} else if (!isDelete) {
						[localChange deleteFromContext];
						[metaMoc save];
						
						BOOL				isNew = target.Id.length == 0;
						
						if (isNew) target.Id = [json objectForKey: @"id"];
						[target didSaveToServer: isNew];
						[contentMoc save];
						MMLog(@"Saved %@ to %@, new ID: %@", serverName, contentMoc, target.Id);

						dispatch_async(dispatch_get_main_queue(), ^{ 
							[[MM_ContextManager sharedManager] saveMetaContext];
							[[MM_ContextManager sharedManager] saveContentContext];
							if (isNewObject && target.robustIDString && target.Id && entityName) [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectCreated object: objectIDString userInfo: @{ @"robustID": target.robustIDString, @"type": entityName, @"Id": target.Id }];
							[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectChangesSaved object: objectIDString];
							[MM_SFChange pushPendingChangesDeferred: 0.5];
						});
						MMLog(@"Pushed change for %@", objectIDString);
					} else if (isDelete) {
						[localChange deleteFromContext];
						[metaMoc save];
						[[MM_ContextManager sharedManager] saveMetaContext];
						[MM_SFChange pushPendingChangesDeferred: 0.5];
					}
					[completedOp dequeue];
				});
				
				return YES;
			} sourceTag: CURRENT_FILE_TAG];
			
			op.tag = SYNC_CHANGE_OP_TAG;
			op.createOrUpdateObjectID = objectIDString;
			change.inProgressValue = YES;
			[metaMoc save];
			
			MMLog(@"Pushing change for %@", objectIDString);
			[[MM_SyncManager sharedManager] queueOperation: op];
		} else {
			[change deleteFromContext];
			[metaMoc save];
			[self pushPendingChangesDeferred: 1.0];
		}
	} else if ([metaMoc firstObjectOfType: [self entityName] matchingPredicate: $P(@"error == nil") sortedBy: sortBy] == nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_AllObjectChangesSaved object: nil];
		s_changesHaveBeenPushed = NO;
		[s_changesContentMoc reset];
		[self completedPushingChanged: YES];
		[self resetInProgressFlags];
	}
}

//=============================================================================================================================
#pragma mark Properties

- (NSDictionary *) originalValuesInContext: (NSManagedObjectContext *) moc {
	NSDictionary				*values = [NSKeyedUnarchiver unarchiveObjectWithData: self.originalValuesData];
	return [values dictionaryByConvertingIDsToObjectsInContext: moc];
}

- (NSDictionary *) modifiedValuesInContext: (NSManagedObjectContext *) moc {
	if (self.modifiedValuesData == nil) return nil;
	
	TRY(
		NSDictionary				*values = [NSKeyedUnarchiver unarchiveObjectWithData: self.modifiedValuesData];
		return [values dictionaryByConvertingIDsToObjectsInContext: moc];
	)
	return nil;
}

- (void) setOriginalValues: (NSDictionary *) originalValues {
	NSDictionary			*newValues = originalValues.dictionaryByConvertingObjectsToIDs;
	self.originalValuesData = [NSKeyedArchiver archivedDataWithRootObject: newValues];
}

- (void) setModifiedValues: (NSDictionary *) modifiedValues {
	NSDictionary			*newValues = modifiedValues.dictionaryByConvertingObjectsToIDs;
	self.modifiedValuesData = [NSKeyedArchiver archivedDataWithRootObject: newValues];
}

- (NSDictionary *) modifiedValuesForServer {
	NSDictionary			*values = [NSKeyedUnarchiver unarchiveObjectWithData: self.modifiedValuesData];
	NSMutableDictionary		*converted = [NSMutableDictionary dictionaryWithCapacity: values.count];
	
	for (NSString *key in values) {
		NSString			*newKey = key;
		
		if ([key hasSuffix: SNAPSHOT_SFID_SUFFIX]) newKey = [key substringToIndex: key.length - SNAPSHOT_SFID_SUFFIX.length];
		if ([key hasSuffix: SNAPSHOT_OBJECT_SUFFIX]) continue;
		[converted setObject: [values objectForKey: key] forKey: newKey];
	}
	
	return converted;
}
@end

@implementation NSDictionary (MMSF_Snapshots)
- (NSDictionary *) dictionaryByConvertingObjectsToIDs {
	NSMutableDictionary			*converted = [NSMutableDictionary dictionary];
	
	for (NSString *key in self) {
		id			value = [self objectForKey: key];
		NSString	*newKey = key;
		
		if ([value isKindOfClass: [NSManagedObject class]]) {
			NSString				*idString = [value robustIDString];
			
//			if ([value isInserted] || [[value objectID] isTemporaryID]) {
//				NSError				*error = nil;
//				if (![[value moc] obtainPermanentIDsForObjects: $A(value) error: &error]) {
//					NSLog(@"Error (%@) while obtaining a permanent ID for %@", error, value);
//					idString = nil;
//				} else 
//					idString = [value robustIDString];
//			}
			if (idString) [converted setObject: idString forKey: FIELD_BY_ADDING_OBJET_SUFFIX(key)];
			if ([value Id]) [converted setObject: [value Id] forKey: [key stringByAppendingString: SNAPSHOT_SFID_SUFFIX]];
			continue;
		} else if ([value isKindOfClass: [NSSet class]]) {
			[converted setObject: [value valueForKey: @"objectIDString"] forKey: FIELD_BY_ADDING_OBJET_SUFFIX(key)];
			[converted setObject: [value valueForKey: @"Id"] forKey: [key stringByAppendingString: SNAPSHOT_SFID_SUFFIX]];
			continue;
		}
		[converted setObject: value forKey: newKey];
	}
	
	return converted;
}

- (NSDictionary *) dictionaryByConvertingIDsToObjectsInContext: (NSManagedObjectContext *) moc {
	NSMutableDictionary			*converted = [NSMutableDictionary dictionary];
	
	for (NSString *key in self) {
		id			value = [self objectForKey: key];
		NSString	*newKey = key;
		
		if ([key hasSuffix: SNAPSHOT_SFID_SUFFIX]) continue;		//skip salesforce ID keys
		if ([key isEqual: @"WhatId"]) continue;
		
		if ([key isEqual: @"WhatId_objectid_shadow_mm"]) {
			newKey = @"WhatId";
			value = [moc objectWithRobustIDString: value];
		}
//		if ([key hasSuffix: @"objectid_shadow_mm"]) continue;		//skip salesforce ID keys
		if ([key hasSuffix: SNAPSHOT_OBJECT_SUFFIX]) {
			if (moc == nil) moc = [[MM_ContextManager sharedManager] contentContextForWriting];
			
			if ([value isKindOfClass: [NSSet class]]) {
				NSMutableSet				*records = [NSMutableSet set];
				
				for (NSString *objectID in value) {
					if (![objectID isKindOfClass: [NSString class]]) continue;
					id			newObject = [moc objectWithRobustIDString: objectID];
					
					if (newObject) [records addObject: newObject];
				}
				value = records;
			} else {
				value = [moc objectWithRobustIDString: value];
			}
			newKey = FIELD_BY_REMOVING_OBJECT_SUFFIX(key);
		}
		if (value) 
			[converted setObject: value forKey: newKey];
		else {
			MMLog(@"Trying to store a nil value: %@", newKey);
		}
	}
	
	return converted;

}
@end
