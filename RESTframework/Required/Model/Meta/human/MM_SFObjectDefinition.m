#import "MM_SFObjectDefinition.h"
#import "MM_ContextManager.h"
#import "MM_RestOperation.h"
#import "MM_SyncManager.h"
#import "MM_Notifications.h"
#import "MMSF_Object.h"
#import "MM_Constants.h"
#import <SalesforceNativeSDK/SFRestAPI.h>
#import "MM_Log.h"
#import "MM_SOQLQueryString.h"
#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"

static NSUInteger s_fixedFetchLimit = 0;
static float g_parsingMemoryFactor = 1.0;
static NSMutableDictionary			*s_cachedDefinitions = nil, *s_cachedServerNameDefinitions = nil;
static NSUInteger					s_definitionCachingDisabled = 0;
static BOOL							s_fallBackOnDefinitionPicklistLabels = NO;

static NSMutableDictionary			*s_idsToDelete = nil;
static NSOperationQueue				*s_deleteObjectsQueue = nil;

@interface MM_SFObjectDefinition ()

- (NSString *) convertServerFieldToModelKey: (NSString *) field;
- (void) syncWithQuery: (MM_SOQLQueryString *) query;
- (BOOL) didImportRecordInsertANewRecord: (NSDictionary *) record inContext: (NSManagedObjectContext *) context withFetchRequest: (NSFetchRequest *) idFetchRequest includingDataBlobs: (BOOL) includingDataBlobs;
- (void) importSObject: (NSDictionary *) sobject;
- (NSArray *) fieldListForType: (NSString *) type;

@property (nonatomic, strong) NSDate *serverSyncStartTime;
@end

static NSMutableDictionary				*s_objectsThatAreNewlyVisibleOnTheServer, *s_objectsThatNoLongerAreVisibleOnTheServer;
static NSInteger						s_removedObjectWarningThreshold = -1;

@implementation MM_SFObjectDefinition
@synthesize serverSyncStartTime = _serverSyncStartTime;

+ (void) setParsingMemoryFactor: (float) factor { g_parsingMemoryFactor = factor; }

+ (void) setFixedFetchLimit: (NSUInteger) limit {
	IF_NOT_PRODUCTION(s_fixedFetchLimit = limit;)
	IF_PRODUCTION(MMLog(@"Setting a fixed fetch limit in a production build. It will be ignored.", @""));
}

+ (NSUInteger) fixedFetchLimit { IF_PRODUCTION(return 0); return s_fixedFetchLimit; }
+ (void) setFallBackOnDefinitionPicklistLabels: (BOOL) fallBack { s_fallBackOnDefinitionPicklistLabels = fallBack; }

+ (void) load {
	@autoreleasepool {
		s_deleteObjectsQueue = [NSOperationQueue new];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(clearCachedObjectDefinitions) name: kNotification_MetaDataDownloadsComplete object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(clearCachedObjectDefinitions) name: kNotification_ModelUpdateComplete object: nil];
	}
}

+ (void) clearCachedObjectDefinitions {
	s_cachedDefinitions = nil;
	s_cachedServerNameDefinitions = nil;
}

+ (void) setCachingEnabled: (BOOL) enabled {
	if (enabled) {
		if (s_definitionCachingDisabled) s_definitionCachingDisabled--;
	} else {
		s_definitionCachingDisabled++;
	}
}

+ (void) setRemovedObjectWarningThreshold: (NSInteger) threshold { s_removedObjectWarningThreshold = threshold; }

//import the list of all objects after download
+ (void) importGlobalObjectList: (NSArray *) sobjects withCompletion: (booleanArgumentBlock) completion {
	dispatch_sync([MM_ContextManager sharedManager].importDispatchQueue, ^{
		[MM_SFObjectDefinition clearCachedObjectDefinitions];

		NSManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadMetaContext;
		for (NSDictionary *sobject in sobjects) {
			NSString				*name = [sobject objectForKey: @"name"];
			MM_SFObjectDefinition				*obj = [self objectNamed: name inContext: moc];
			
			if (obj == nil) {
				obj = [moc insertNewEntityWithName: [self entityName]];
				obj.linkRequiredTag = @2;
			}
			[obj importSObject: sobject];
			
		}
		[moc save];
		dispatch_on_main_queue(^{
			[[MM_ContextManager sharedManager] saveMetaContext];
			if (completion) completion(YES);
		});
	});
}

//Have we downloaded the base object list yet?
+ (BOOL) orgObjectsHaveBeenInitialized {
	NSManagedObjectContext			*ctx = [MM_ContextManager sharedManager].threadMetaContext;
	NSInteger						count = [ctx numberOfObjectsOfType: [self entityName] matchingPredicate: nil];
	
	return count > 0;
}


//find the record for object "name" in the context
+ (MM_SFObjectDefinition *) objectNamed: (NSString *) name inContext: (NSManagedObjectContext *) ctx {
	if (name == nil) return nil;
	BOOL					useCached = (!s_definitionCachingDisabled && ctx == nil && [NSThread isMainThread]);
	
	if (useCached && s_cachedDefinitions[name]) return s_cachedDefinitions[name];
	
	if (ctx == nil) ctx = [MM_ContextManager sharedManager].threadMetaContext;
	
	MM_SFObjectDefinition			*def = [ctx anyObjectOfType: [self entityName] matchingPredicate: $P(@"name == %@", name)];
	
	if (useCached && def) {
		if (s_cachedDefinitions == nil) s_cachedDefinitions = [NSMutableDictionary dictionary];
		s_cachedDefinitions[name] = def;
	}
	return def;
}

+ (MM_SFObjectDefinition *) objectWithServerName: (NSString *) name inContext: (NSManagedObjectContext *) ctx {
	if (name == nil) return nil;
	
	BOOL					useCached = (!s_definitionCachingDisabled && ctx == nil && [NSThread isMainThread]);

	if (useCached && s_cachedServerNameDefinitions[name]) return s_cachedServerNameDefinitions[name];
	
	if (ctx == nil) ctx = [MM_ContextManager sharedManager].threadMetaContext;
	
	MM_SFObjectDefinition			*def = [ctx anyObjectOfType: [self entityName] matchingPredicate: $P(@"serverObjectName_mm == %@", name)];
	
	if (useCached && def) {
		if (s_cachedServerNameDefinitions == nil) s_cachedServerNameDefinitions = [NSMutableDictionary dictionary];
		s_cachedServerNameDefinitions[name] = def;
	}
	return def;
}

#if ALLOW_OBJECT_REMAPPING
	static NSMutableDictionary				*s_serverObjectNames = nil;
    + (void) clearServerObjectNames
    {
        s_serverObjectNames = nil;
    }

	+ (NSString *) serverObjectNameForLocalName: (NSString *) name {
		if (s_serverObjectNames == nil) s_serverObjectNames = [NSMutableDictionary dictionary];
		
		NSString					*cached = s_serverObjectNames[name];
		
		if (cached) return cached;
		
		NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].threadMetaContext;
		MM_SFObjectDefinition				*def = [self objectNamed: name inContext: moc];
		
		s_serverObjectNames[name] = def.serverObjectName_mm.length ? def.serverObjectName_mm : name;
		
		return s_serverObjectNames[name];
	}

	+ (NSString *) localObjectNameForServerName: (NSString *) name {
		if (s_serverObjectNames == nil) s_serverObjectNames = [NSMutableDictionary dictionary];
		
		for (NSString *key in s_serverObjectNames.allKeys) {
			NSString			*serverName = s_serverObjectNames[key];
			
			if ([serverName isEqual: name]) return key;
		}
		
		NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].threadMetaContext;
		MM_SFObjectDefinition				*def = [moc anyObjectOfType: [self entityName] matchingPredicate: $P(@"serverObjectName_mm == %@", name)];
		
		if (def == nil) return name;
		s_serverObjectNames[def.name] = name;
		
		return def.name;
	}
#else
	+ (NSString *) serverObjectNameForLocalName: (NSString *) name { return name; }
	+ (NSString *) localObjectNameForServerName: (NSString *) name { return name; }
	+ (void) clearServerObjectNames {}
#endif

#if ALLOW_FIELD_REMAPPING
	static NSMutableDictionary				*s_localFieldToServerReplacements = nil, *s_serverFieldToLocalReplacements = nil;

	- (NSString *) serverFieldNameForLocalName: (NSString *) name {
		if (s_localFieldToServerReplacements == nil) {
			s_localFieldToServerReplacements = [NSMutableDictionary dictionary];
			s_serverFieldToLocalReplacements = [NSMutableDictionary dictionary];
		}
		if (s_localFieldToServerReplacements[self.name] == nil) {
			s_localFieldToServerReplacements[self.name] = [NSMutableDictionary dictionary];
			s_serverFieldToLocalReplacements[self.name] = [NSMutableDictionary dictionary];
		}
		
		NSMutableDictionary		*dict = s_localFieldToServerReplacements[self.name];
		NSString				*field = dict[name];
		if (field) return field;
		
		NSDictionary			*replacements = [self metadataValueForKey: @"field-name-substitutions"];			//sync_objects.plist key
		NSString				*replacement = replacements[name] ?: name;
		
		dict[name] = replacement;
		s_serverFieldToLocalReplacements[self.name][replacement] = name;
		
		return replacement;
	}

	- (NSString *) localNameForServerFieldName: (NSString *) name {
		//SA_Assert(s_serverFieldToLocalReplacements != nil, @"Trying to access s_serverFieldToLocalReplacements before they've been set up.");
		return s_serverFieldToLocalReplacements[self.name][name] ?: name;
	}
#else
	- (NSString *) serverFieldNameForLocalName: (NSString *) name { return name; }
	- (NSString *) localNameForServerFieldName: (NSString *) name { return name; }
#endif

//filter out an conflicts in naming. Right now, just -description
- (NSString *) convertServerFieldToModelKey: (NSString *) field {
	if ([field isEqualToString: @"description"]) return @"desc";
	return field;
}

//read a single object's info form the global object list in +importGlobalObjectList
- (void) importSObject: (NSDictionary *) sobject {
	for (NSString *field in sobject) {
		NSString		*key = [self convertServerFieldToModelKey: field];
		id				value = [sobject valueForKey: field];
		
		if ([value isEqual: [NSNull null]]) value = nil;
		
		[self setValue: value forKey: key];
	}
	self.serverObjectName_mm = sobject[@"name"];
}

//fetch the metadata for the object
- (MM_RestOperation *) fetchMetaData: (BOOL) refetch {
	if (!refetch && self.metaDescription_mm != nil) return nil;
	
	[MM_SFObjectDefinition clearCachedObjectDefinitions];
	NSString				*name = [MM_SFObjectDefinition serverObjectNameForLocalName: self.name];

	return [MM_RestOperation operationWithRequest: [[SFRestAPI sharedInstance] requestForDescribeWithObjectType: name] completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		NSManagedObjectContext			*ctx = [MM_ContextManager sharedManager].threadMetaContext;
		MM_SFObjectDefinition			*obj = [MM_SFObjectDefinition objectNamed: self.name inContext: ctx];

		if (error) [[MM_Log sharedLog] logMetadataError: error forObjectNamed: obj.name];
		if (json == nil) {
			[[MM_SyncManager sharedManager] queueOperation: [self fetchMetaData: refetch] atFrontOfQueue: YES];
			return NO;
		}
		
		obj.canFilterOnLastModifiedValue = NO;
		obj.layout_mm = nil;
		obj.metaDescription_mm = json;
		//MMLog(@"Fetched metadata for %@", name);
		for (NSDictionary *field in json[@"fields"]) {
			if ([field[@"name"] isEqual: @"LastModifiedDate"]) {
				obj.canFilterOnLastModifiedValue = YES;
				break;
			}
		}
		[ctx save];
		return NO;
	} sourceTag: CURRENT_FILE_TAG];
}

- (NSString *) labelForField: (NSString *) field {
	NSDictionary			*meta = (id) self.metaDescription_mm;
	
	for (NSDictionary *dict in [meta objectForKey: @"fields"]) {
		if ([[dict objectForKey: @"name"] isEqual: field]) return [dict objectForKey: @"label"];
	}
	
	return nil;
}

//=============================================================================================================================
#pragma mark Sync
- (NSArray *) filters {
	NSArray				*filters = [self metadataValueForKey: @"filters"];
	
	if (filters.count) return filters;
	
	return @[ ([self metadataValueForKey: @"filter"] ?: @"") ];
}

- (NSString *) syncDependencies { 
	NSString							*depends = [self metadataValueForKey: @"dependencies"];
	
	if (depends.length || [self.name isEqual: @"User"]) return depends;
	
	for (NSString *filter in self.filters) {
		if ([filter containsCString: "current_user."]) return @"User";
	}
	return nil;
}

- (BOOL) isUpToDate: (NSDate *) date {
	if (self.lastSyncedAt_mm == nil) return NO;										//this object has never been synced
	if ([self.lastSyncedAt_mm isEqualToDate: [NSDate distantPast]]) return NO;		//this object is queued for a full re-sync
	
	return [self.lastSyncedAt_mm earlierDate: date] != self.lastSyncedAt_mm;
}

- (BOOL) didImportRecordInsertANewRecord: (NSDictionary *) record inContext: (NSManagedObjectContext *) ctx withFetchRequest: (NSFetchRequest *) idFetchRequest includingDataBlobs: (BOOL) includingDataBlobs {
	
	MMSF_Object				*existing = nil;
	NSError					*error = nil;
	BOOL					inserted = YES;
	
	if (idFetchRequest) {
		NSString				*recordID = [record objectForKey: @"Id"];
		
		idFetchRequest.predicate = $P(@"Id == %@", recordID);
		NSArray					*results = [ctx executeFetchRequest: idFetchRequest error: &error];
		
		if (results.count > 0) existing = [results objectAtIndex: 0];
	}

	inserted = (existing == nil);
	if (existing == nil) existing = (id) [ctx insertNewEntityWithName: self.name];
	
	existing = [existing importRecord: record includingDataBlobs: NO];
	if (!existing) {
		IF_SIM(if (![self metadataValueForKey: @"skip-server-count-checks"]) {
			MMLog(@"-[MMSF_%@ importRecord:includingDataBlobs: is returning nil; please set 'skip-server-count-checks' in the sync_objects_plist to prevent endless sync loops.", self.name);
		});
	}
	return inserted;
}

- (void) preflightSync {
	NSManagedObjectContext			*contentMoc = [[MM_ContextManager sharedManager] threadContentContext];

	if ((self.lastSyncedAt_mm == nil || [self.lastSyncedAt_mm isEqualToDate: [NSDate distantPast]]) || [contentMoc numberOfObjectsOfType: self.name matchingPredicate: nil] == 0) {
		self.fullSyncInProgress_mmValue = YES;
		//if (self.lastSyncedAt_mm) [[MM_SyncManager sharedManager] clearAllObjectsOfType: self.name];
	} else
		self.fullSyncInProgress_mmValue = NO;
}

- (void) incrementLinkRequiredTagInContext: (NSManagedObjectContext *) moc {
	MMSF_Object				*object = [moc firstObjectOfType: self.name matchingPredicate: nil sortedBy: [NSSortDescriptor SA_arrayWithDescWithKey: MISSING_LINK_ATTRIBUTE_NAME ascending: NO]];
	NSUInteger				tag = [object[MISSING_LINK_ATTRIBUTE_NAME] intValue] + 1;
	
	self.linkRequiredTag = @(tag);
}

- (void) queueSyncOperationsForQuery: (MM_SOQLQueryString *) query retrying: (BOOL) retrying {
	BOOL							skipData = !self.shouldSyncServerData;
	Class							objectClass = self.objectClass;
	
	if ([objectClass respondsToSelector: @selector(baseQueryIncludingData:)]) {
		query = [(id) objectClass baseQueryIncludingData: !skipData];
		if (query.isEmptyQuery) return;
	}
	if (query == nil) query = [self baseQueryIncludingData: !skipData];
	
	//preflight use to go here.
    if ([objectClass respondsToSelector: @selector(willSyncWithQuery:)])
    {
        [objectClass willSyncWithQuery: query];
    }
    
	query.isRetryQuery = retrying;
	if ([objectClass respondsToSelector: @selector(syncWithQuery:)])
		[objectClass syncWithQuery: query];
	else
		[self syncWithQuery: query];
}

- (NSArray *) salesforceIDsMatchingPredicate: (NSPredicate *) pred {
	NSManagedObjectContext	*moc = [[MM_ContextManager sharedManager] contentContextForWriting];
	NSFetchRequest			*request = [moc fetchRequestWithEntityName: self.name predicate: pred sortBy: nil fetchLimit: 0];
	NSError					*error = nil;
	request.resultType = NSDictionaryResultType;
	request.propertiesToFetch = @[ @"Id" ];
	NSArray					*results = [moc executeFetchRequest: request error: &error];
	return [results valueForKey: @"Id"];

}

- (BOOL) isFieldReadOnly: (NSString *) field {
	NSDictionary		*info = [self infoForField: field];
	
	return ![info[@"updateable"] boolValue];
}

- (void) downloadAndCompareSalesforceIDs {
	Class                       objectClass = self.objectClass;
	MM_SOQLQueryString          *query;
//	if ([objectClass respondsToSelector: @selector(baseQueryIncludingData:)]) {
//		query = [(id) objectClass baseQueryIncludingData: NO];
    if ([objectClass respondsToSelector: @selector(idOnlyQueryIncludingData:)])
    {
        query = [(id) objectClass idOnlyQueryIncludingData: NO];
	}
    else if ([objectClass respondsToSelector: @selector(baseQueryIncludingData:)])
    {
        query = [(id) objectClass baseQueryIncludingData: NO];
    }
    else
    {
		query = [self baseQueryIncludingData: NO]; //[MM_SOQLQueryString queryWithObjectName: self.name];
	}
	
	query.lastModifiedDate = nil;
	
	NSArray				*ids = [self salesforceIDsMatchingPredicate: nil];
	dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
		if (s_objectsThatNoLongerAreVisibleOnTheServer == nil) s_objectsThatNoLongerAreVisibleOnTheServer = [NSMutableDictionary dictionary];
		s_objectsThatNoLongerAreVisibleOnTheServer[self.name] = [NSMutableSet setWithArray: ids];
	});
			
	query.isIDOnlyQuery = YES;
	query.moreURLString = self.moreResultsURL_mm;

	[self queueQuery: query withCompletionBlock: nil];
}


- (void) queueQuery: (MM_SOQLQueryString *) query withCompletionBlock: (simpleBlock) completion {
	MM_RestOperation		*op = [MM_RestOperation operationWithQuery: query
														groupTag: self.objectIDString
												 completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
													 [MM_SyncManager incrementParseCount];
													 if (error && [error.userInfo[@"errorCode"] isEqual: @"INVALID_QUERY_LOCATOR"]) {
														 [completedOp dequeue];
														 dispatch_on_main_queue(^{
															 MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: self.name inContext: nil];
															 
															 [def resetLastSyncDate];
															 [def save];
															 
															 [NSObject performBlock: ^{
																 query.moreURLString = nil;
																 dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{ [def pullMoreDataWithQuery: query completion: completion]; });
			
																 [MM_SyncManager decrementParseCount];
															 } afterDelay: 0.0];
														 });
														 return YES;
													 }
													 dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
														 if (![MM_SyncManager sharedManager].syncCancelled) @autoreleasepool {
															 NSManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadMetaContext;
															 MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: self.name inContext: moc];
															 
															 [def parseJSONResponse: json forQuery: query headerDate: completedOp.sfdcHeaderDate withError: error completion: completion];
															 [MM_SyncManager decrementParseCount];
														 }
														 [completedOp dequeue];
													 });
													 return YES;
												 } sourceTag: CURRENT_FILE_TAG];
	
	[[MM_SyncManager sharedManager] queueOperation: op atFrontOfQueue: query.isIDOnlyQuery || query.isRetryQuery || query.isContinuationQuery];
}

- (void) syncWithQuery: (MM_SOQLQueryString *) query {
	if (self.moreResultsURL_mm.length)
		query.moreURLString = self.moreResultsURL_mm;

	[self queueQuery: query withCompletionBlock: nil];
}

- (void) pullMoreDataWithQuery: (MM_SOQLQueryString *) query completion: (simpleBlock) completion {
	[self queueQuery: query withCompletionBlock: completion];
}


- (void) queueLocalRecordsForDeletionWithSFIDS: (NSSet *) recordIDs {
	NSString				*name = self.name;
	if (recordIDs.count) [s_deleteObjectsQueue addOperationWithBlock: ^{
		if (s_idsToDelete == nil) s_idsToDelete = [NSMutableDictionary new];

		if (s_idsToDelete[name] == nil) {
			s_idsToDelete[name] = recordIDs.allObjects.mutableCopy;
		} else {
			[s_idsToDelete[name] addObjectsFromArray: recordIDs.allObjects];
		}
	}];
}

+ (void) removeDeletedRecords: (simpleBlock) completion {
	[s_deleteObjectsQueue addOperationWithBlock: ^{
		NSManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
		
		if (s_idsToDelete.count) {
			for (NSString *key in s_idsToDelete.copy) {
				NSMutableArray				*ids = s_idsToDelete[key];
				NSPredicate					*pred = $P(@"Id in %@", ids);
				NSFetchRequest				*request = [moc fetchRequestWithEntityName: key predicate: pred sortBy: nil fetchLimit: 0];
				NSError						*error = nil;
				
				request.includesPropertyValues = NO;
				NSArray						*found = nil;
				TRY(found = [moc executeFetchRequest: request error: &error]);
				if (error) {MMLog(@"Problem clearing out removed records: %@", error); }
				MMLog(@"------------- Will remove %d %@ records", found.count, key);
				
				NSMutableArray * deleted = [NSMutableArray new];
				for (MMSF_Object *object in found) {
					[deleted addObject:object.Id];
					[object deleteFromContext];
				}
				
				// remove ids from s_idsToDelete after deletion
				[ids removeObjectsInArray:deleted];
				if (ids.count) {
					s_idsToDelete[key] = ids;
				} else {
					[s_idsToDelete removeObjectForKey:key];
				}
				
				[moc save];
			}
			[[MM_ContextManager sharedManager] saveContentContext];
		}
		
		if (completion != nil) {
			completion();
		}
	}];
}

- (void) updateRecordsWithSFIDS: (NSSet *) sfIDs {
	if (sfIDs.count == 0) return;
	MM_SOQLQueryString				*query = [self baseQueryIncludingData: NO];
	
	query.lastModifiedDate = nil;
	query.predicate = nil;
	[query filterForIDs: sfIDs.allObjects inField: @"Id"];
	MMLog(@"Attempting to add %d %@ records", sfIDs.count, self.name);
	[self syncWithQuery: query];
}

- (void) parseJSONResponse: (id) json forQuery: (MM_SOQLQueryString	*) query headerDate: (NSDate *) headerDate withError: (NSError *) error completion: (simpleBlock) completion {
	if (json == nil) return;

	[MM_SyncManager incrementParseCount];
	//	TRY(
	//float							availableMemory = [UIDevice availableMemory];
	
	if (!query.isIDOnlyQuery && self.serverSyncStartTime == nil) self.serverSyncStartTime = headerDate;
	@autoreleasepool {
		NSManagedObjectContext			*metaCtx = [MM_ContextManager sharedManager].threadMetaContext;
		MM_SFObjectDefinition			*localDefinition = [self objectInContext: metaCtx];
		NSUInteger						objCount = [[json objectForKey: @"totalSize"] integerValue];
		NSString						*postNotificationForObjectName = nil;
		
		if (query.moreURLString) {
			NSArray						*last = [query.moreURLString.lastPathComponent componentsSeparatedByString: @"-"];
			
			if (last.count) {
				[MM_SyncManager sharedManager].currentObjectName = localDefinition.name;
				if (!query.isIDOnlyQuery) [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ObjectSyncContinued
																				object: localDefinition.name
																				  info: @{ @"total": @(objCount), @"count": @([[last lastObject] intValue])}];
			}
		}

//		if (!query.isIDOnlyQuery) {
//			if (self.canFilterOnLastModifiedValue && self.fullSyncInProgress_mmValue != query.shouldSearchForExistingRecordsWhenImporting)
//				MMLog(@"Finishing a sync of %@ wtih a full-sync mismatch (%d / %d / %d", self.name, [json[@"records"] count], [json[@"totalSize"] intValue], [[MM_ContextManager sharedManager].threadContentContext numberOfObjectsOfType: self.name matchingPredicate: nil]);
//		
//			MMLog(@"parseJSONResponse: %@ for %@ (%d / %d)", query.shouldSearchForExistingRecordsWhenImporting ? @"Full Sync" : @"Partial Sync", localDefinition.name, [json[@"records"] count], [json[@"totalSize"] intValue]);
//		}
		localDefinition.serverObjectCountValue = (UInt32) objCount;		//we don't want to read this here; it's only valid when doing a full query.

		if (error) [[MM_Log sharedLog] logSyncError: error forObjectNamed: localDefinition.name];
		
		NSManagedObjectContext			*ctx = [[MM_ContextManager sharedManager] contentContextForWriting];
		if (ctx == nil) {		//no data context, bad scene
			MMLog(@"**************************************** Parse failed due to no context %@", @"");
			[MM_SyncManager decrementParseCount];
			return;
		}

		NSString						*url = [json objectForKey: @"nextRecordsUrl"];
		MM_SOQLQueryString				*nextQuery = [query nextQueryTakingMoreStringIntoAccount: url];
		NSFetchRequest					*idFetchRequest = nil;
			

		[MM_SyncManager incrementParseCount];
		dispatch_after_main_queue(0.01, ^{
			[MM_SyncManager incrementParseCount];
			if (nextQuery) dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{ [localDefinition pullMoreDataWithQuery: nextQuery completion: completion]; });
			[MM_SyncManager decrementParseCount];
		});
		[MM_SyncManager decrementParseCount];
		
		localDefinition.lastSyncError_mm = error;
		localDefinition.moreResultsURL_mm = nextQuery.moreURLString;

		if (query.isIDOnlyQuery) {
			localDefinition.serverObjectCountValue = (UInt32) objCount;
			[localDefinition save];
			
			NSFetchRequest			*idCheckRequest = [ctx fetchRequestWithEntityName: self.name predicate: nil sortBy: nil fetchLimit: 1];
			NSString				*name = localDefinition.name;
			
			for (NSString *sfID in [json[@"records"] valueForKey: @"Id"]) {
				if ([s_objectsThatNoLongerAreVisibleOnTheServer[name] containsObject: sfID])
					[s_objectsThatNoLongerAreVisibleOnTheServer[name] removeObject: sfID];
				else {
					idCheckRequest.predicate = $P(@"Id == %@", sfID);
					if ([ctx countForFetchRequest: idCheckRequest error: &error]) continue;
					if (s_objectsThatAreNewlyVisibleOnTheServer == nil) s_objectsThatAreNewlyVisibleOnTheServer = [NSMutableDictionary dictionary];
					if (s_objectsThatAreNewlyVisibleOnTheServer[localDefinition.name] == nil) s_objectsThatAreNewlyVisibleOnTheServer[localDefinition.name] = [NSMutableSet set];
					[s_objectsThatAreNewlyVisibleOnTheServer[localDefinition.name] addObject: sfID];
				}
			}
			
			if (nextQuery == nil && error == nil) {
				NSInteger				totalCount = [ctx numberOfObjectsOfType: localDefinition.name matchingPredicate: nil];
				NSInteger				threshold = s_removedObjectWarningThreshold;
				
				if (threshold == 0) switch ([MM_Log sharedLog].currentLogLevel) {
					case MM_LOG_LEVEL_VERBOSE: threshold = 3; break;
					case MM_LOG_LEVEL_LOW: threshold = totalCount * 0.25; break;
					default: threshold = -1; break;
				}

				NSUInteger missingCount = [s_objectsThatNoLongerAreVisibleOnTheServer[name] count];
				MMLog(@"Have %d too many %@ (%@) records, missing: %@", [s_objectsThatNoLongerAreVisibleOnTheServer[name] count], name, s_objectsThatNoLongerAreVisibleOnTheServer[name], s_objectsThatAreNewlyVisibleOnTheServer[name]);

				
				if (threshold && missingCount >= threshold) {
					NSSet					*noLongerVisible = [s_objectsThatNoLongerAreVisibleOnTheServer[name] copy];
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[SA_AlertView showAlertWithTitle: $S(@"There are %d %@ No Longer Visible", (UInt16) missingCount, localDefinition.name)
												 message: $S(@"Would you like to remove %d (out of %d) %@ records from the local database?", (UInt16) missingCount, (UInt16) totalCount, localDefinition.name)
												 buttons: @[ @"Ignore", @"Remove" ] buttonBlock: ^(NSInteger buttonIndex) {
													 if (buttonIndex == 1) 	dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
														 NSManagedObjectContext			*dispatchCtx = [MM_ContextManager sharedManager].threadMetaContext;
														 MM_SFObjectDefinition			*dispatchDefinition = [self objectInContext: dispatchCtx];
														 [dispatchDefinition queueLocalRecordsForDeletionWithSFIDS: noLongerVisible];
													 });
												  }];
					});
				} else {
					[localDefinition queueLocalRecordsForDeletionWithSFIDS: s_objectsThatNoLongerAreVisibleOnTheServer[name]];
				}
				[s_objectsThatNoLongerAreVisibleOnTheServer removeObjectForKey: name];
				[localDefinition updateRecordsWithSFIDS: s_objectsThatAreNewlyVisibleOnTheServer[name]];
				[s_objectsThatAreNewlyVisibleOnTheServer removeObjectForKey: name];
			}
		} else {
			if (query.shouldSearchForExistingRecordsWhenImporting || query.isContinuationQuery) {
				idFetchRequest = [[NSFetchRequest alloc] init];
				idFetchRequest.entity = [NSEntityDescription entityForName: localDefinition.name inManagedObjectContext: ctx];
				idFetchRequest.fetchLimit = 1;
			}
			
			NSMutableArray					*addedRecordIDs = [NSMutableArray array];
			NSInteger						count = 0, blockSize = 500;
			BOOL							includeDataBlobs = YES;
			//NSTimeInterval					startTime = [NSDate timeIntervalSinceReferenceDate];
			
			if ([[localDefinition metadataValueForKey: @"disable-initial-blob-download"] boolValue]) includeDataBlobs = NO;		//sync_objects.plist key
			
			//if ([UIDevice availableMemory] < (25000 * 1024)) blockSize = 200;				//this seems to work well as far down as 27Mb free. Below that, we'll reudce the chunk size.
			blockSize *= g_parsingMemoryFactor;
			
			NSArray				*records = [json objectForKey: @"records"];
			
			TRY(for (NSDictionary *record in records) {
				if ([localDefinition didImportRecordInsertANewRecord: record inContext: ctx withFetchRequest: idFetchRequest includingDataBlobs: includeDataBlobs]) {
					[addedRecordIDs addObject: [record valueForKey: @"Id"]];
				}
				count++;
				
				if (count % blockSize == 0) dispatch_sync(dispatch_get_main_queue(), ^{ [[MM_ContextManager sharedManager] saveAndClearContentContext]; });
			});
			
			[ctx save];
			[ctx reset];
			
			if (!query.isIDOnlyQuery) [NSNotificationCenter postNotificationNamed: kNotification_SyncBatchReceived object: localDefinition.name];
			NSString			*name = localDefinition.name;
			
			if (nextQuery == nil && error == nil) {			//all done
				Class				class = [localDefinition objectClass];
				NSDate				*lastSync = localDefinition.lastSyncedAt_mm;
				BOOL				markAsSynced = YES;
								
				if ([class respondsToSelector: @selector(downloadAndImportComplete)]) {
					[class downloadAndImportComplete];
					[[MM_SyncStatus status] markObjectNameComplete: name];
				}
				if (query.isFullSyncOperation) {
//					NSUInteger			foundCount = [ctx numberOfObjectsOfType: name matchingPredicate: nil];
					
//					if (0 && localDefinition.serverObjectCountValue > foundCount && ![localDefinition metadataValueForKey: @"skip-server-count-checks"]) {		//sync_objects.plist key
//						[localDefinition resetSyncAndDeleteAllData];
//						[localDefinition queueSyncOperationsForQuery: nil retrying: YES];
//						[MM_SyncManager decrementParseCount];
//						markAsSynced = NO;
//					} else {
						//MMLog(@"parseJSONResponse: Marking object complete: %@ (Mem: %dk)", localDefinition.name, (UInt16) [UIDevice availableMemory] / 1024);
                    localDefinition.fullSyncInProgress_mmValue = NO;
                    localDefinition.fullSyncCompleted_mmValue = YES;
                } else if (localDefinition.fullSyncCompleted_mmValue &&
                           !localDefinition.fullSyncInProgress_mmValue &&
					localDefinition.shouldPerformServerIDCheck &&
                           !query.isIDOnlyQuery) {
					[localDefinition downloadAndCompareSalesforceIDs];
				} else if (lastSync) {
					[localDefinition checkForDeletedRecordsSince: lastSync];
				}
				
				if (markAsSynced) {
					if (localDefinition.hasDataBlobs) {     //Dont mark as sync'd until datablobs are done
						dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
							NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadMetaContext;
							MM_SFObjectDefinition		*def = [localDefinition objectInContext: moc];
							
							[def refreshAllDataBlobs: YES markingComplete:YES];
						});
                    }
                    else {
                        if (!query.isIDOnlyQuery) localDefinition.lastSyncedAt_mm = self.serverSyncStartTime;//this will mark the object as having been synced successfully at least once
						
						self.serverSyncStartTime = nil;
                        [[MM_SyncManager sharedManager] markObjectAsSynced: localDefinition];
						postNotificationForObjectName = localDefinition.name;
                    }
					if (completion) completion();
				}
			}
			[localDefinition save];
			[MM_SFObjectDefinition clearCachedObjectDefinitions];
			dispatch_async(dispatch_get_main_queue(), ^{
				[[MM_ContextManager sharedManager] saveMetaContext];
				[[MM_ContextManager sharedManager] saveAndClearContentContext];
				[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectsImported object: addedRecordIDs userInfo: $D(name, @"name")];
				if (postNotificationForObjectName) [NSNotificationCenter postNotificationNamed: kNotification_ObjectSyncCompleted object: postNotificationForObjectName];
			});
			
		}
	};
    
//	MMLog(@"parseJSONResponse: Parse complete for %d %@ records (Memory Delta: %dk)", [[MM_ContextManager sharedManager].contentContextForReading numberOfObjectsOfType: self.name matchingPredicate: nil], self.name, (int) ([UIDevice availableMemory] - availableMemory) / 1024);
	[MM_SyncManager decrementParseCount];
	//);
}

- (BOOL) shouldPerformServerIDCheck {
#if DISABLE_SERVER_ID_CHECKS
	return NO;
#endif
	return [[self metadataValueForKey: @"always-check-ids-with-server"] boolValue];
}

- (void) resetSyncAndDeleteAllData {
	[[MM_SyncManager sharedManager] clearAllObjectsOfType: self.name];
	
	[self resetLastSyncDate];
}

- (void) resetLastSyncDate {
	if (self.lastSyncedAt_mm) self.lastSyncedAt_mm = [NSDate distantPast];
	self.fullSyncCompleted_mmValue = NO;
	[self save];
}
 
- (NSArray *) fieldListForType: (NSString *) type {
	NSArray				*list = [self metadataValueForKey: type];
	
	if (list) {
		if ([list isKindOfClass: [NSArray class]]) return list;
		if (list) return [(NSString *) list componentsSeparatedByString: @","];
	}
	
	list = [self metadataValueForKey: [type stringByAppendingString: @"-list"]];
	
	if ([list isKindOfClass: [NSArray class]]) return list;
	if (list) return [(NSString *) list componentsSeparatedByString: @","];
	return nil;
}

- (NSArray *) dataFieldNames {
	NSMutableArray			*fields = [NSMutableArray array];
	NSArray					*fieldDefs = [(id) [self metaDescription_mm] objectForKey: @"fields"];
	
	for (NSDictionary *field in fieldDefs) {
		if ([[field objectForKey: @"type"] convertToAttributeType] == NSBinaryDataAttributeType) [fields addObject: [field objectForKey: @"name"]];
	}
	return fields;
}

- (NSArray *) queriedFields {
	NSDictionary						*description = (id) self.metaDescription_mm;
	NSMutableArray						*fields = [NSMutableArray array];
	NSArray								*ignoreThese = [self fieldListForType: @"ignore"];								//sync_objects.plist key
	NSArray								*onlyThese = [self fieldListForType: @"only"];									//sync_objects.plist key
	NSArray								*extra = [self fieldListForType: @"extra-query"];								//sync_objects.plist key
	
	extra = (onlyThese && extra) ? [onlyThese arrayByAddingObjectsFromArray: extra] : (onlyThese ?: extra);
	for (NSString *field in extra) {
		if ([field containsCString: "."]) [fields addObject: field];
	}

	for (NSDictionary *field in [description objectForKey: @"fields"]) {
		NSString				*name = [field objectForKey: @"name"];
		//int						length = [[field objectForKey: @"length"] intValue];
		
		//if (length == 0) continue;
		if ([field[@"deprecatedAndHidden"] integerValue]) continue;
		if ([ignoreThese containsObject: name]) continue;
		if (onlyThese && ![onlyThese containsObject: name]) continue;
		[fields addObject: field];
	}
	return fields;
}

- (void) populateQueryFilters: (MM_SOQLQueryString *) query withFilterString: (NSString *) filter {
	if (filter.length) query.predicate = [MM_SOQLPredicate predicateWithString: filter];
	[query addPredicateString:  filter.length ? filter : nil];							//sync_objects.plist key
	query.fetchLimit = [[self metadataValueForKey: @"fetch-limit"] intValue];			//sync_objects.plist key
	query.fetchOrderField = [self metadataValueForKey: @"fetch-order"];					//sync_objects.plist key
	
	#if DEBUG
		if (s_fixedFetchLimit && query.fetchLimit == 0 && ![self.name isEqual: @"User"]) query.fetchLimit = s_fixedFetchLimit;			//allow debug builds to set an overall fetch limit to reduce data loads when developing
	#endif
}

- (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs {	
	MM_SOQLQueryString					*query = [MM_SOQLQueryString queryWithObjectName: self.serverObjectName_mm.length ? self.serverObjectName_mm : self.name];
	NSMutableArray						*fields = [NSMutableArray array];
	
	for (NSDictionary *field in self.queriedFields) {
		if ([field isKindOfClass: [NSString class]]) {
			[fields addObject: field];
			continue;
		}
		NSString				*name = [field objectForKey: @"name"];									//sync_objects.plist key
		[fields addObject: name];
	}
	query.fields = fields;
	
	if (self.lastSyncedAt_mm && ![self.lastSyncedAt_mm isEqualToDate: [NSDate distantPast]] && self.canFilterOnLastModifiedValue) {
		query.lastModifiedDate = self.lastSyncedAt_mm;
	} else {
		MMLog(@"Setting up a full sync for %@", self.name);
	}
	
	for (NSString *filter in self.filters) {
		[self populateQueryFilters: query withFilterString: filter];
	}
	
	query.isFirstSyncOperation = [[MM_ContextManager sharedManager].threadContentContext numberOfObjectsOfType: self.name matchingPredicate: nil] == 0;
	
	return query;
}

- (BOOL) requiresPostSyncLink {
	NSNumber				*value = [self metadataValueForKey: @"post-sync-link"];	//sync_objects.plist key. set to NO to have it NOT inclue a link phase during the sync for this object

	if (value) return [value boolValue];

	return YES;
}

- (BOOL) reloadOnObjectCreation {
	return ![[self metadataValueForKey: @"no-reload-on-creation"] boolValue];			//sync_objects.plist key
}

- (NSUInteger) numberOfMissingLinkRecordsInContext: (NSManagedObjectContext *) ctx {
	NSUInteger				linkRequiredMinimumTag = self.linkRequiredTag.intValue;
	NSPredicate				*predicate = $P(MISSING_LINK_ATTRIBUTE_NAME @" && " MISSING_LINK_ATTRIBUTE_NAME @" < %d", linkRequiredMinimumTag);
	
	return [ctx numberOfObjectsOfType: self.name matchingPredicate: predicate];
}

- (void) connectAllMissingLinksInContext: (NSManagedObjectContext *) ctx showingProgress: (BOOL) showingProgress {
	[self countAndConnectAllMissingLinksInContext: ctx showingProgress: showingProgress];		//will need to add to this at some point
}

#if 0
//filter fields based on only
NSArray* onlyFields = [self fieldListForType:@"only"];
if (onlyFields != nil)
{
	NSMutableDictionary* filteredShadowFieldNames = [NSMutableDictionary dictionaryWithCapacity:shadowFieldNames.count];
	
	[shadowFieldNames enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSUInteger ndx = [onlyFields indexOfObject:key];
		if (ndx != NSNotFound)
		{
			[filteredShadowFieldNames setObject:obj forKey:key];
		}
	}];
	
	shadowFieldNames = filteredShadowFieldNames;
}
#endif

- (NSUInteger) countAndConnectAllMissingLinksInContext: (NSManagedObjectContext *) ctx showingProgress: (BOOL) showingProgress {
    if (![MMSF_Object isDynamicRecordLinkingEnabled]) {
		return 0;
	}
	
	if (ctx == nil) ctx = [MM_ContextManager sharedManager].contentContextForWriting;

	NSUInteger				connectedRecordCount = 0;
    // NSDate				*startTime = [NSDate date];
	NSString				*format = MISSING_LINK_ATTRIBUTE_NAME @" > 0 AND " MISSING_LINK_ATTRIBUTE_NAME @" != %d";
	NSUInteger				linkRequiredMinimumTag = self.linkRequiredTag.intValue;
	NSPredicate				*predicate = $P(format, (UInt16) linkRequiredMinimumTag);
    NSInteger				numberOfRecordsToLink = [ctx numberOfObjectsOfType: self.name matchingPredicate: predicate];
	BOOL					recordsLeft = numberOfRecordsToLink > 0;
	
	@autoreleasepool {
		NSEntityDescription			*entity = [NSEntityDescription entityForName: self.name inManagedObjectContext: ctx];
		NSDictionary				*relationships = entity.relationshipsByName, *attributes = attributes = entity.attributesByName;
		NSDictionary				*shadowFieldNames = [MMSF_Object shadowFieldNamesFromRelationships: relationships andAttributes: attributes];
		NSMutableSet				*dataFields = [NSMutableSet set];
		int							batchSize = MIN(10000, [UIDevice.currentDevice availableMemory] / 5000);	//uggggly
		
		for (NSAttributeDescription *descName in attributes) {
			if ([[attributes objectForKey: descName] attributeType] == NSBinaryDataAttributeType) {
				[dataFields addObject: DATA_URL_SHADOW(descName)];
				[dataFields addObject: DATA_PATH_SHADOW(descName)];
			}
		}

		if (shadowFieldNames.count == 0) recordsLeft = 0;
		
		MMLog(@"About to link %d of %d %@ records", MIN(batchSize, numberOfRecordsToLink), numberOfRecordsToLink, self.name);
		if (recordsLeft) {
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_MissingLinksConnectingObject object: self.name info: @{ @"count": @(numberOfRecordsToLink)}];
			NSArray					*recordsToLink = [ctx allObjectsOfType: self.name matchingPredicate: predicate sortedBy: nil fetchLimit: batchSize];
			
			if (recordsToLink.count == 0) numberOfRecordsToLink = [ctx numberOfObjectsOfType: self.name matchingPredicate: predicate];
			[MMSF_Object setDynamicRecordLinkingEnabled: NO];
			for (MMSF_Object *object in recordsToLink) {
				TRY(		//seeing an occasional un-faulted object here. not sure why, but this should prevent a crash when trying to link to it
					[object connectMissingLinksUsingRelationships: relationships attributes: attributes shadowFieldNames: shadowFieldNames andDataFields: dataFields withLinkTag: linkRequiredMinimumTag];
					);
				object[MISSING_LINK_ATTRIBUTE_NAME] = @(linkRequiredMinimumTag);
				connectedRecordCount++;
			}
			[ctx save];
			[ctx reset];
			[MMSF_Object setDynamicRecordLinkingEnabled: YES];

			if (showingProgress) {
				float				value = (float) connectedRecordCount / (float) numberOfRecordsToLink;
				dispatch_async(dispatch_get_main_queue(), ^{
					[SA_PleaseWaitDisplay pleaseWaitDisplay].progressValue = value;
				});
			}
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_MissingLinksConnectedObject object: self.name];
		}
		

        // NSTimeInterval duration = 0; //keeps the "unused variable error" fairy at bay
        // duration = ABS([startTime timeIntervalSinceNow]);
    }
    
    [[MM_ContextManager sharedManager] setMissingLinksAreConnected: YES forObjectNamed: self.name];
    
	return connectedRecordCount;
}

//=============================================================================================================================
#pragma mark entity generation
- (NSEntityDescription *) entityDescription {
	NSEntityDescription					*entity = [NSEntityDescription entityDescriptionNamed: self.name];
	NSDictionary						*description = (id) self.metaDescription_mm;
	
	if (description == nil) return nil;
	
	if (!self.requiresPostSyncLink) {
		NSMutableDictionary				*info = entity.userInfo.mutableCopy;
		
		if (info == nil) info = [NSMutableDictionary dictionary];
		[info setObject: @(self.requiresPostSyncLink) forKey: @"post-sync-link"];
		[entity setUserInfo: info];
	}
	
	NSArray								*fields = [self fieldListForType: @"only"];
	NSArray								*extraQuery = [self fieldListForType: @"extra-query"];
	NSArray								*extraDevice = [self fieldListForType: @"extra-device"];
	NSArray								*indexes = [self fieldListForType: @"indexed"];
	
//	if ([indexes isKindOfClass: [NSString class]]) indexes = [(id) indexes componentsSeparatedByString: @","];
	
	for (NSString *field in fields) {
		if ([field rangeOfString: @"."].location != NSNotFound) {
			[entity addAttributeNamed: CONVERT_EXTRA_FIELD_TO_PROPERTY_NAME(field) ofType: NSStringAttributeType indexed: NO updateable: NO createable: NO];
		}
	}
	
	if ([extraDevice isKindOfClass: [NSString class]]) extraDevice = [(NSString *) extraDevice componentsSeparatedByString: @","];
	if ([extraQuery isKindOfClass: [NSString class]]) extraQuery = [(NSString *) extraQuery componentsSeparatedByString: @","];
	if (extraDevice && extraQuery) extraQuery = [extraQuery arrayByAddingObjectsFromArray: extraDevice];
	if (extraQuery == nil) extraQuery = extraDevice;
	
	for (NSString *field in extraQuery) {
		NSString				*fieldName = [field isKindOfClass: [NSString class]] ? field : [(id) field objectForKey: @"name"];
		NSAttributeType			fieldType = [field isKindOfClass: [NSString class]] ? NSStringAttributeType : [[(id) field objectForKey: @"type"] convertToAttributeType];
		[entity addAttributeNamed: CONVERT_EXTRA_FIELD_TO_PROPERTY_NAME(fieldName) ofType: fieldType indexed: NO updateable: NO createable: NO];
	}
	
	[entity addAttributeNamed: MMID_FIELD ofType: NSStringAttributeType indexed: YES updateable: NO createable: NO];

	for (NSDictionary *field in [description objectForKey: @"fields"]) {
		NSString				*name = [field objectForKey: @"name"];
		NSAttributeType			type = [[field objectForKey: @"type"] convertToAttributeType];
		BOOL					indexed = [name isEqual: @"Id"] || [indexes containsObject: name];
		
		if ([name isEqual: [NSNull null]]) continue;
		if ([[field objectForKey: @"type"] isEqual: @"reference"]) {
			NSArray				*destinations = [field objectForKey: @"referenceTo"];

			if (destinations.count > 1 || [name isEqual: @"WhatId"] || [name isEqual: @"ParentId"] || [name isEqual: @"WhoId"]) {
				//This is a polymorphic relationship. Since we can't support this natively, we'll create a shadow field to store a Core Data Object ID. 
				//Normally, this shadow field won't be used. However, if we create a related object while offline, we can store the ID of the related
				//object here, and then connect the two of them once we have an actual SFID
				[entity addAttributeNamed: name ofType: NSStringAttributeType indexed: YES updateable: [[field objectForKey: @"updateable"] boolValue] createable: [[field objectForKey: @"createable"] boolValue]];
				[entity addAttributeNamed: RELATIONSHIP_OBJECTID_SHADOW(name) ofType: NSStringAttributeType indexed: NO updateable: [[field objectForKey: @"updateable"] boolValue] createable: [[field objectForKey: @"createable"] boolValue]];
			} else if (destinations.count > 0) {
				mm_oneToManyType			type = mm_oneToManyType_one_to_many;
				NSString					*dest = [destinations objectAtIndex: 0];
				
				dest = [MM_SFObjectDefinition localObjectNameForServerName: dest];
				[entity addPendingRelationship: name to: dest backLinkName: nil isToMany: type updateable: [[field objectForKey: @"updateable"] boolValue] createable: [[field objectForKey: @"createable"] boolValue]];
			}
			continue;
		}
		
		if (type == NSUndefinedAttributeType) {
			MMLog(@"Found an unknown attribute (type: %@, name: %@, owner: %@", [field objectForKey: @"type"], name, self.name);
			continue;
		}
		
		if (type == NSBinaryDataAttributeType) {
			[entity addAttributeNamed: DATA_URL_SHADOW(name) ofType: NSStringAttributeType];
			[entity addAttributeNamed: DATA_PATH_SHADOW(name) ofType: NSStringAttributeType];
		}
		[entity addAttributeNamed: name ofType: type indexed: indexed updateable: [[field objectForKey: @"updateable"] boolValue] createable: [[field objectForKey: @"createable"] boolValue]];
	}
	
	for (NSDictionary *addedField in [self metadataValueForKey: @"add"]) {							//sync_objects.plist key
		NSString				*name = [addedField objectForKey: @"name"];
		NSString				*type = [addedField objectForKey: @"type"];
		NSString				*index = [addedField objectForKey: @"index"];
		
		if (type == nil) type = @"string";
		[entity addAttributeNamed: name ofType: type.convertToAttributeType indexed: [index isEqual: @"YES"] updateable: NO createable: NO];
	}

	
	for (NSDictionary *relationship in [description objectForKey: @"childRelationships"]) {
		NSString				*deprecatedAndHidden = [relationship objectForKey: @"deprecatedAndHidden"];
		NSString				*backLinkName = [relationship objectForKey: @"field"];
		NSString				*destination = [relationship objectForKey: @"childSObject"];
		NSString				*name = [relationship objectForKey: @"relationshipName"];
		/*
         BOOL					isToMany = 0 && [[relationship objectForKey: @"cascadeDelete"] boolValue];		//need to figure out how to determine this
         */
        BOOL isToMany = NO;
		
		if ([name isEqual: [NSNull null]] || [deprecatedAndHidden boolValue]) continue;

		destination = [MM_SFObjectDefinition localObjectNameForServerName: destination];
		[entity addPendingRelationship: name to: destination backLinkName: backLinkName isToMany: isToMany updateable: [[relationship objectForKey: @"updateable"] boolValue] createable: [[relationship objectForKey: @"createable"] boolValue]];
	}
	
		
	entity.managedObjectClassName = NSStringFromClass(self.objectClass);
	[entity addAttributeNamed: MISSING_LINK_ATTRIBUTE_NAME ofType: NSInteger32AttributeType indexed: YES updateable: NO createable: NO];
	
	return entity;
}

//- (BOOL) validateExistingEntityDescription: (NSEntityDescription *) 

//=============================================================================================================================
#pragma mark Properties
- (BOOL) shouldSyncServerData {
	return ![[self metadataValueForKey: @"write-only"] boolValue] && ![[self metadataValueForKey: @"skip-autosync"] boolValue];								//sync_objects.plist key
}

- (Class) objectClass {
	NSString		*customClassName = $S(@"MMSF_%@", self.name);
	Class			class = NSClassFromString(customClassName);
	
	if (class) return class;
	return [MMSF_Object class];
}


//=============================================================================================================================
#pragma mark metadata
- (NSArray *) picklistOptionsForField: (NSString *) fieldName {
	NSDictionary						*description = (id) self.metaDescription_mm;
	NSArray								*fields = [description objectForKey: @"fields"];
	
	for (NSDictionary *info in fields) {
		if ([[info objectForKey: @"name"] isEqual: fieldName]) {
			return [info objectForKey: @"picklistValues"];
		}
	}
	return nil;
}

- (NSString *) picklistLabelForValue: (NSString *) value inField: (NSString *) field {
	NSArray				*items = [self picklistOptionsForField: field];
	
	if (value == nil) return @"";
	
	for (NSDictionary *item in items) {
		NSString			*itemValue = item[@"value"];
		
		if ([itemValue isEqual: value]) return item[@"label"] ?: item[@"value"];
	}
	
	return value;
}

- (NSString *) picklistLabelForMultiselectValue: (NSString *) value inField: (NSString *) field {
	NSArray				*items = [self picklistOptionsForField: field];
	
	if (value == nil) return @"";
	
	NSMutableString		*results = [NSMutableString string];
	NSArray				*values = [value componentsSeparatedByString: @";"];
	
	for (NSString *component in values) {
		for (NSDictionary *item in items) {
			NSString			*itemValue = item[@"value"];
			
			if ([itemValue isEqual: component]) [results appendFormat: @"%@%@", results.length ? @"; " : @"", item[@"label"]];
		}
	}
	
	return results.length ? results : value;
}

- (NSArray *) picklistOptionsForField: (NSString *) fieldName basedOffRecordType: (MMSF_Object *) recordType {
	return [self picklistOptionsForField: fieldName inRecord: nil basedOffRecordType: recordType];
}

- (NSArray *) picklistOptionsForField: (NSString *) fieldName inRecord: (MMSF_Object *) record basedOffRecordType: (MMSF_Object *) recordType {
	NSDictionary			*describedLayout = self.describeLayout;
	NSString				*recordID = recordType.Id;
	
	if (describedLayout == nil) return nil;			//no data yet
	
	NSDictionary			*foundLayout = nil;
	for (NSDictionary *layout in [describedLayout objectForKey: @"recordTypeMappings"]) {
		if ([recordID isEqual: [layout objectForKey: @"recordTypeId"]]) {
			foundLayout = layout;
			break;
		}
	}

	if (foundLayout == nil) for (NSDictionary *layout in [describedLayout objectForKey: @"recordTypeMappings"]) {
		if ([[layout objectForKey: @"defaultRecordTypeMapping"] boolValue]) {
			foundLayout = layout;
			break;
		}
	}
	
	if (foundLayout == nil) return nil;
    
	NSDictionary		*fieldInfo = [self infoForField: fieldName];
	NSString			*controllerField = fieldInfo[@"controllerName"];
	NSArray				*rawPicklistOptions = fieldInfo[@"picklistValues"];
	NSInteger			controllerIndex = NSNotFound;
	
	if (![rawPicklistOptions isKindOfClass: [NSArray class]]) rawPicklistOptions = nil;
	
	if (![controllerField isKindOfClass: [NSNull class]] && controllerField.length && record[controllerField]) {
		NSArray					*controllerOptions = [self infoForField: controllerField][@"picklistValues"];
		NSString				*controllerValue = record[controllerField];
		
		for (NSDictionary *controllerOption in controllerOptions) {
			if ([[controllerOption valueForKey: @"value"] isEqual: controllerValue]) {
				controllerIndex = [controllerOptions indexOfObject: controllerOption];
				break;
			}
		}
	}
	
	for (NSDictionary *picklistInfo in [foundLayout objectForKey: @"picklistsForRecordType"]) {
		if ([[picklistInfo objectForKey: @"picklistName"] isEqual: fieldName]) {
			NSArray			*values = [picklistInfo objectForKey: @"picklistValues"];
           if (![values isKindOfClass: [NSArray class]]) values = $A(values);
            NSMutableArray *translatedArray = [[NSMutableArray alloc] initWithCapacity:values.count];
			
            for(NSDictionary *item in values) {
                NSMutableDictionary *dictionary = item.mutableCopy;
				NSDictionary				*rawOption = nil;
				
				for (NSDictionary *option in rawPicklistOptions) {
					if ([option[@"value"] isEqual: item[@"value"]]) {
						rawOption = option;
						break;
					}
				}
				
				if (rawOption == nil && controllerIndex != NSNotFound) continue;
				
				if (rawOption && controllerIndex != NSNotFound) {
					NSString			*validFor = [rawOption objectForKey: @"validFor"];
					if (validFor.length == 0) continue;
					NSData				*data = [NSData dataWithBase64EncodedString: validFor];
					uint8_t				*validForBytes = (uint8_t *)[data bytes];
					uint8_t				shiftedIndex = controllerIndex >> 3;
					
					if (data.length <= shiftedIndex) continue;
					if ((validForBytes[shiftedIndex] & (0x80 >> controllerIndex % 8)) == 0) continue;
				} else {
					LOG(@"No match found for %@", item);
				//	rawOption = nil;
				}
				
				if (s_fallBackOnDefinitionPicklistLabels && rawOption)
					dictionary[@"label"] = rawOption[@"label"];
				else {
					NSString *label = [item valueForKey:@"label"] ? [item valueForKey:@"label"] : [item valueForKey:@"value"] ;
					NSString *decodedString = [NSString stringWithUTF8String:[label cStringUsingEncoding: NSUTF8StringEncoding]];
					[dictionary setValue:decodedString forKey:@"label"];
                }
				[translatedArray addObject:dictionary];
            }
			return translatedArray;
		}
	}
	return rawPicklistOptions;
}

- (NSDictionary *) infoForField: (NSString *) fieldName {
	NSDictionary						*description = (id) self.metaDescription_mm;
	NSArray								*fields = [description objectForKey: @"fields"];
	
	for (NSDictionary *info in fields) {
		if ([[info objectForKey: @"name"] isEqual: fieldName]) return info;
	}
	return nil;
}

- (NSAttributeType) typeOfField: (NSString *) fieldName {
	NSDictionary						*info = [self infoForField: fieldName];
	
	return [[info objectForKey: @"type"] convertToAttributeType];
}

- (id) metadataValueForKey: (NSString *) key {
	return [(id) self.syncInfo_mm objectForKey: key];
}

- (NSArray *) availableRecordTypesInContext: (NSManagedObjectContext *) moc {
	NSArray				*allTypes = [self.metaDescription_mm valueForKey: @"recordTypeInfos"];
	NSMutableArray		*availableTypes = [NSMutableArray array];
	
	for (NSDictionary *info in allTypes) {
		if ([info[@"available"] intValue] != 1) continue;
		
		MMSF_Object				*type = [moc anyObjectOfType: @"RecordType" matchingPredicate: $P(@"Id == %@", info[@"recordTypeId"])];
		
		if (type) [availableTypes addObject: type];
	}
	return availableTypes;
}

- (NSArray *) picklistOptionsForField: (NSString *) fieldName basedOffRecord: (MMSF_Object *) record {
	NSDictionary						*info = [self infoForField: fieldName];
	NSString							*controllerName = info[@"controllerName"];
    
	if (controllerName == nil || [controllerName isEqual: [NSNull null]]) {
        if ([record hasAttribute:@"RecordTypeId"])
            return [record.definition picklistOptionsForField: fieldName basedOffRecordType: [record valueForKey: @"RecordTypeId"]];
        return [info objectForKey: @"picklistValues"];		
    }
	
	return [self picklistOptionsForFieldInfo: info basedOffControllerField: controllerName withValue: record[controllerName]];
}

- (NSArray *) picklistOptionsForFieldInfo: (NSDictionary *) info basedOffControllerField: (NSString *) field withValue: (NSString *) value {
	NSMutableArray		*available = [NSMutableArray array];
	NSInteger			selectedIndex = NSNotFound;
	NSArray				*controllerOptions = [self picklistOptionsForField: field];

	if (value.length == 0) return available;			//nothing selected, return no items

	for (NSDictionary *controllerOption in controllerOptions) {
		if ([[controllerOption valueForKey: @"value"] isEqual: value]) {
			selectedIndex = [controllerOptions indexOfObject: controllerOption];
			break;
		}
	}
	
	if (selectedIndex == NSNotFound) {
		for (NSDictionary *controllerOption in controllerOptions) {
			if ([value hasPrefix: [controllerOption valueForKey: @"value"]]) {
				selectedIndex = [controllerOptions indexOfObject: controllerOption];
				break;
			}
		}
	}
	
	for (NSDictionary *option in [info objectForKey: @"picklistValues"]) {
		NSString			*validFor = [option objectForKey: @"validFor"];
		if (validFor.length == 0) continue;
		NSData				*data = [NSData dataWithBase64EncodedString: validFor];
		uint8_t				*validForBytes = (uint8_t *)[data bytes];
		uint8_t				shiftedIndex = selectedIndex >> 3;
		
		if (data.length <= shiftedIndex) continue;
		if ((validForBytes[shiftedIndex] & (0x80 >> selectedIndex % 8)) != 0) {
			[available addObject: option];
		}
	}

	return available;
}

- (BOOL) hasDataBlobs {
	return [self.name isEqual: @"Attachment"] || [self.name isEqual: @"ContentVersion"];
}

- (void) refreshAllDataBlobs:(BOOL)ifNeeded {
    [self refreshAllDataBlobs:ifNeeded markingComplete:NO];
}

- (void) refreshAllDataBlobs: (BOOL) ifNeeded markingComplete:(BOOL) markComplete {
	NSString					*name = self.name;
	

	dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
		@try {
			//NSMutableSet				*checked = [NSMutableSet set];
			NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadContentContext;
			for (MMSF_Object *obj in [moc allObjectsOfType: name matchingPredicate: nil]) {
//				if ([checked containsObject: obj.Id]) {
//					LOG(@"Queing dupe: %@", obj);
//					continue;
//				}
				//[checked addObject: obj.Id];
				[obj refreshDataBlobs: ifNeeded];
			}
            
            if (markComplete) {                // Queue blobs done operation
                MM_RestOperation *blobfinale = [MM_RestOperation operationWithRequest: nil
                                                                      completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
                        MMLog(@"Data blobs complete for object: %@",name);
                        MM_SFObjectDefinition * def = [MM_SFObjectDefinition objectNamed: name
                                                                               inContext: [MM_ContextManager sharedManager].threadMetaContext];
                        [[MM_SyncManager sharedManager] markObjectAsSynced:def];
                        def.lastSyncedAt_mm = [NSDate date];
                        [def save];
                        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ObjectSyncCompleted
                                                                                        object: def.name];
                    return NO;
                } sourceTag: CURRENT_FILE_TAG];
                blobfinale.iWorkAlone = YES;
                [[MM_SyncManager sharedManager] queueOperation: blobfinale atFrontOfQueue:NO];
            }
		} @catch (id e) {};
	});
}

- (NSString *) defaultRecordType {
    NSDictionary					*layout = [self describeLayout];
    NSArray							*mappings = layout[@"recordTypeMappings"];
    NSString                        *recordTypeID;
    
    if (mappings != nil) {
        NSDictionary			*layoutMapping = nil;
        
        for (NSDictionary *mapping in mappings) {
            if ([mapping[@"defaultRecordTypeMapping"] isEqual: @"true"]) {
                layoutMapping = mapping;
                break;
            }
        }
        recordTypeID = layoutMapping[@"recordTypeId"];
    }
    return recordTypeID;
}

- (NSArray *) allItemsInLayout: (NSString *) layoutID {
	NSMutableArray					*allItems = [NSMutableArray array];
	NSDictionary					*layout = [self describeLayout];
	NSArray							*mappings = layout[@"recordTypeMappings"];
	NSArray							*layouts = layout[@"layouts"];
	
	if (mappings != nil && layouts != nil) {
		NSDictionary			*layoutMapping = nil, *defaultLayout = nil;
		
		if (layoutID == nil) {
			for (NSDictionary *mapping in mappings) {
				if ([mapping[@"defaultRecordTypeMapping"] isEqual: @"true"]) {
					layoutMapping = mapping;
					break;
				}
			}
			layoutID = layoutMapping[@"layoutId"];
		}
		
		if (layoutID != nil) {
			for (NSDictionary *layout in layouts) {
				if ([layout[@"id"] isEqual: layoutID]) {
					defaultLayout = layout;
					break;
				}
			}
		}
		
		if (defaultLayout != nil) {
			NSArray			*sections = defaultLayout[@"editLayoutSections"];
			
			for (NSDictionary *section in sections) {
				NSArray			*layoutRows = [section[@"layoutRows"] isKindOfClass: [NSArray class]] ? section[@"layoutRows"] : @[ section[@"layoutRows"] ];
				NSArray			*rows = layoutRows;
				for (NSDictionary *row in rows) {
					NSArray			*items = row[@"layoutItems"];
					
					if ([items isKindOfClass: [NSDictionary class]]) items = @[ items ];
					
					[allItems addObjectsFromArray: items];
				}
			}
		}
	}

	return allItems;
}

- (NSArray *) allFieldsInLayout: (NSString *) layoutID { return [self allFieldsInLayout: layoutID requiredOnly: false]; }

- (NSArray *) allFieldsInLayout: (NSString *) layoutID requiredOnly: (BOOL) requiredOnly {
	NSMutableArray					*fields = [NSMutableArray array];
	NSArray							*allLayoutItems = [self allItemsInLayout: layoutID];
	
	if (allLayoutItems.count > 0) {
		for (NSDictionary *item in allLayoutItems) {
			if (!requiredOnly || [item[@"required"] isEqual: @"true"]) {
				NSArray			*itemFields = item[@"layoutComponents"][@"components"] ?: @[ item[@"layoutComponents"] ];
				
				for (NSDictionary *field in itemFields) {
					if ([field[@"type"] isEqual: @"Field"]) {
						NSString		*fieldName = field[@"value"];
						NSDictionary	*info = [self infoForField: fieldName];
						
						[fields addObject: info];
					}
				}
			}
			
		}
		return fields;
	}
	
	for (NSDictionary *info in self.metaDescription_mm[@"fields"]) {
		NSString				*nillable = info[@"nillable"];
		
		if (nillable == nil || [nillable intValue] == 0) {
			[fields addObject: info];
		}
	}
	
	return fields;
}



- (NSArray *) requiredFieldsInLayout: (NSString *) layoutID { return [self allFieldsInLayout: layoutID requiredOnly: true]; }



@end

@implementation NSDate (Salesforce)
- (NSString *) salesforceStringRepresentation {
	@synchronized (@"NSDate-salesforceStringRepresentation") {
		static NSDateFormatter				*formatter = nil;
		
		if (formatter == nil) {
			formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat: @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.000Z'"];
			[formatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
		}
		
		return [formatter stringFromDate: self];
	}
}
@end
