//
//  MM_ContextManager.m
//
//  Created by Ben Gottlieb on 11/13/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_ContextManager+Model.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_Notifications.h"
#import "MM_SFChange.h"
#import "MM_LoginViewController.h"
#import "MM_SyncManager.h"
#import "MMSF_Object.h"
#import "MM_Log.h"
#import "MM_Constants.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_ContextManager+Atomic.h"

#define META_CONTEXT_KEY			@"META_CONTEXT"
#define CONTENT_CONTEXT_KEY			@"CONTENT_CONTEXT"


static NSString *kMetaDataKey_ConnectedObjectNames = @"kMetaDataKey_ConnectedObjectNames";
static NSString *kMetaDataKey_ModelVersionNumber = @"kMetaDataKey_ModelVersionNumber";

static NSString *s_storeFileProtection = nil;
static NSURL* s_dataStoreRoot;
static NSURL* s_contentModelRoot;
static NSURL* s_metadataModelRoot;
static NSString* s_metadataFilename = @"Metadata.db";
static NSString* s_contentFilename = @"Main.db";
static NSString* s_contentModelFilename = @"ContentModel.mom";
static NSUInteger s_dataModelVersion = 0;

@interface MM_ContextManager ()
@property (atomic, readwrite) BOOL deletingAllData;
@property (atomic, strong) SA_ThreadsafeMutableArray *threadContexts, *metaThreadContexts;

@end

@implementation MM_ContextManager
@synthesize mainMetaContext = _mainMetaContext, metaContextPath, importDispatchQueue = _importDispatchQueue, contentContextPath, contentModel = _contentModel,metaContextModel=_metaContextModel, mainContentContext = _mainContentContext, deletingAllData;

- (void) dealloc {
	[self removeAsObserver];
}

+ (void) initialize
{
    s_dataStoreRoot = [NSFileManager documentsDirectory];
    s_contentModelRoot = [NSFileManager libraryDirectory];
}

+ (void) setDataStoreRoot:(NSURL *)rootURL
{
    s_dataStoreRoot = rootURL;
}

+ (void) setContentModelRoot:(NSURL *)rootURL
{
    s_contentModelRoot = rootURL;
}

+ (void) setMetadataFilename:(NSString*) filename
{
    s_metadataFilename = filename;
}

+ (void) setContentFilename:(NSString*) filename
{
    s_contentFilename = filename;
}

+ (void) setContentModelFilename:(NSString*) filename
{
    s_contentModelFilename = filename;
}

+ (void) setMetadataModelRoot:(NSURL *)rootURL
{
    s_metadataModelRoot = rootURL;
}

+ (void) setDataModelVersion: (NSUInteger) version {
	s_dataModelVersion = version;
}

- (NSString *) contentModelPath {
	return [s_contentModelRoot.path stringByAppendingPathComponent: s_contentModelFilename];
}

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(MM_ContextManager, sharedManager);
- (id) init {
	if ((self = [super init])) {
		self.saveLock = [NSLock new];
		[self resetContextSetupTag];
		[self addAsObserverForName: kNotification_PersistentStoreResetDueToSchemaChange selector: @selector(persistentStoreReset:)];
		[self addAsObserverForName: kNotification_MetaDataDownloadsComplete selector: @selector(metadataDownloadComplete:)];
		[self addAsObserverForName: NSThreadWillExitNotification selector: @selector(threadWillExit:)];

		self.metaContextPath = [s_dataStoreRoot.path stringByAppendingPathComponent: s_metadataFilename];
		self.contentContextPath = [s_dataStoreRoot.path stringByAppendingPathComponent: s_contentFilename];
		[self mainMetaContext];
		
		if ([_mainMetaContext.primaryStoreMetadata[kMetaDataKey_ModelVersionNumber] intValue] != s_dataModelVersion) {
			NSError					*error = nil;
			
			_mainMetaContext = nil;
			_mainContentContext = nil;
			
			if (![[NSFileManager defaultManager] removeItemAtPath: self.metaContextPath error: &error] || ![[NSFileManager defaultManager] removeItemAtPath: self.contentContextPath error: &error]) {
				[SA_AlertView showAlertWithTitle: @"There was an Error While Upgrading Your Data Store; You Should Delete and Re-Install" error: error];
			}
			[NSNotificationCenter postNotificationNamed: kNotification_AllDataDeletedDueToModelUpdate];
			[self mainMetaContext];
		}
		
		if (self.isBackedUpDataAvailable) {
			dispatch_async_main_queue(^{
				[[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_crashed];
				[self restoreBackedUpDataWithCompletion: nil];
			});
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: self.contentContextPath]) {
			[self saveContentContextWithBlock:^{
				[NSFileManager setFileAtURLNotBackedUp: [NSURL fileURLWithPath: self.contentContextPath]];
			}];
		} else
			[NSFileManager setFileAtURLNotBackedUp: [NSURL fileURLWithPath: self.contentContextPath]];

		if (![[NSFileManager defaultManager] fileExistsAtPath: self.metaContextPath]) {
			[self saveMetaContextWithBlock:^{
				[NSFileManager setFileAtURLNotBackedUp: [NSURL fileURLWithPath: self.metaContextPath]];
			}];
		} else
			[NSFileManager setFileAtURLNotBackedUp: [NSURL fileURLWithPath: self.metaContextPath]];
		
		[self addAsObserverForName: UIApplicationDidEnterBackgroundNotification selector: @selector(willEnterBackground)];
	}
	return self;
}

+ (void) setStoreFileProtection: (NSString *) protection {
	s_storeFileProtection = protection;
}

- (void) willEnterBackground {
	[NSManagedObject saveRobustObjectIDsCache];
}

+ (mm_model_validation_result) validateCurrentModelReturningInfo: (NSMutableDictionary *) invalidObjectsAndFieldsInfo {
	NSString						*path = [[NSBundle mainBundle] pathForResource: @"field_validation" ofType: @"plist"], *errorString;
	mm_model_validation_result		result = mm_model_validation_result_valid;
	NSMutableArray					*missingObjects;
	NSMutableDictionary				*incompleteObjects;
	NSUInteger						missingFieldCount = 0;
	
	missingObjects = [NSMutableArray array];
	invalidObjectsAndFieldsInfo[@"missing objects"] = missingObjects;
	
	incompleteObjects = [NSMutableDictionary dictionary];;
	invalidObjectsAndFieldsInfo[@"incomplete objects"] = incompleteObjects;
	
	if (path == nil) return mm_model_validation_result_missing;
	
	NSData					*data = [NSData dataWithContentsOfFile: path];
	if (data == nil) return mm_model_validation_result_missing;
	
	NSPropertyListFormat	format;
	NSDictionary			*entityFieldLists = [NSPropertyListSerialization propertyListFromData: data mutabilityOption: NSPropertyListImmutable format: &format errorDescription: &errorString];
	
	if (entityFieldLists == nil) return mm_model_validation_result_missing;
	
	NSManagedObjectContext	*moc = [[self sharedManager] contentContextForWriting];
	
	if (moc == nil) return mm_model_validation_result_missing;
	
	NSDictionary			*entities = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName;
	
	for (NSString *entityName in entityFieldLists) {
		NSEntityDescription			*desc = entities[entityName];
			
		if (desc == nil) {
			[missingObjects addObject: entityName];
			continue;
		}
		NSDictionary				*attr = desc.attributesByName, *rel = desc.relationshipsByName;
		
		for (NSString *field in entityFieldLists[entityName]) {
			if (attr[field] == nil && rel[field] == nil) {
				if (incompleteObjects[entityName] == nil) incompleteObjects[entityName] = [NSMutableArray array];
				[incompleteObjects[entityName] addObject: field];
				missingFieldCount++;
			}
		}
	}
	
	if (missingObjects.count || incompleteObjects.count) {
		NSMutableString				*missingObjectsText = [NSMutableString string];
								
		if (missingObjects.count) {
			[missingObjectsText appendFormat: @"You're missing access to %@ ", (missingObjects.count > 1) ? @"the following objects" : @"the object"];
		
			for (NSString *objectName in missingObjects) { [missingObjectsText appendFormat: [missingObjects indexOfObject: objectName] ? @", %@" : @"%@", objectName]; }
			
			result = mm_model_validation_result_failedMissingEntity;
		} else
			result = mm_model_validation_result_failedMissingField;
		
		if (incompleteObjects.count) {
			[missingObjectsText appendFormat: (missingObjects.count == 0) ? @"You're missing access to %@ on %@:" : @". You're also missing access to %@ on %@:", missingFieldCount > 1 ? @"fields" : @"a field", incompleteObjects.count > 1 ? @"the following objects" : @"one object"];
			
			BOOL				isFirst = YES;
			for (NSString *objectName in incompleteObjects) {
				if (!isFirst) [missingObjectsText appendString: @","];
				[missingObjectsText appendFormat: @" %@ (on %@)", [incompleteObjects[objectName] componentsJoinedByString: @", "], objectName];
				isFirst = NO;
			}
		}
		
		[missingObjectsText appendString: @"."];
		invalidObjectsAndFieldsInfo[@"description"] = missingObjectsText;
	}
	
	return result;
}

- (void) threadWillExit: (NSNotification *) note {
	NSThread						*thread = note.object;
	NSMutableDictionary				*info = thread.threadDictionary;
	NSManagedObjectContext			*contentMoc = info[CONTENT_CONTEXT_KEY];
	NSManagedObjectContext			*metaMoc = info[META_CONTEXT_KEY];
	
	[self.threadContexts removeObject: contentMoc];
	[self.metaThreadContexts removeObject: metaMoc];
	
	[info removeObjectForKey: CONTENT_CONTEXT_KEY];
	[info removeObjectForKey: META_CONTEXT_KEY];
}

- (void) reapContexts {
	[self.threadContexts safelyAccessInBlock: ^(NSMutableArray *array) {
		for (MM_ManagedObjectContext *moc in array) {
			if (moc.sourceThread.isFinished) {
				NSMutableDictionary				*info = moc.sourceThread.threadDictionary;
				[info removeObjectForKey: CONTENT_CONTEXT_KEY];
				[info removeObjectForKey: META_CONTEXT_KEY];
				[array removeObject: moc];
			}
		}
	}];

	[self.metaThreadContexts safelyAccessInBlock: ^(NSMutableArray *array) {
		for (MM_ManagedObjectContext *moc in array) {
			if (moc.sourceThread.isFinished) {
				NSMutableDictionary				*info = moc.sourceThread.threadDictionary;
				[info removeObjectForKey: META_CONTEXT_KEY];
				[info removeObjectForKey: CONTENT_CONTEXT_KEY];
				[array removeObject: moc];
			}
		}
	}];
}

- (NSManagedObjectContext *) metaContextForWriting {
	if (self.deletingAllData) return nil;

	MM_ManagedObjectContext		*ctx = [[MM_ManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
	NSManagedObjectContext		*parent = self.mainMetaContext;
	ctx.contextSetupTag = self.contextSetupTag;
	
	ctx.saveThread = [NSThread currentThread];
	[ctx setParentContext: parent];
	return ctx;
}

- (void) resetContextSetupTag {
	self.contextSetupTag = [NSDate timeIntervalSinceReferenceDate];
}

- (void) persistentStoreReset: (NSNotification *) note {
	[self resetContextSetupTag];
	if ([MM_LoginViewController isAuthenticated]) {
		[[MM_SyncManager sharedManager] downloadObjectDefinitionsWithCompletionBlock: nil];
	} else {
		[[NSNotificationCenter defaultCenter] addFireAndForgetBlockFor: kNotification_DidAuthenticate object: nil block: ^(NSNotification *note) {
			[[MM_SyncManager sharedManager] downloadObjectDefinitionsWithCompletionBlock: nil];
		}];
	}
}

- (void) metadataDownloadComplete: (NSNotification *) note {
	[self.metaThreadContexts safelyAccessInBlock:^(NSMutableArray *array) {
		for (NSManagedObjectContext *moc in array) {
			[moc reset];
		}
	}];
	[self.mainContentContext reset];
	[self.mainMetaContext reset];
}

- (void) clearContext: (NSManagedObjectContext *) moc {
	NSError					*error = nil;
	NSPersistentStore		*store = moc.persistentStoreCoordinator.persistentStores.lastObject;
	NSURL					*storeURL = [[moc persistentStoreCoordinator] URLForPersistentStore: store];

	[moc lock];
	[moc reset];


	if (store && [[moc persistentStoreCoordinator] removePersistentStore: store error: &error]) {
		[[NSFileManager defaultManager] removeItemAtURL: storeURL error: &error];
		[[moc persistentStoreCoordinator] addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: storeURL options:nil error: &error];
	} else if (error) {
		LOG(@"An error occurred while attempting to remove a database at %@: %@", storeURL, error);
		IF_DEBUG([SA_AlertView showAlertWithTitle: @"An error occurred while attempting to remove a database" error: error]);
	}
	[moc unlock];

}

- (void) pushAllPendingChangesAndRemoveAllData {
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_WillRemoveAllData object: nil];
	if (![SA_ConnectionQueue sharedQueue].offline && [MM_SFChange numberOfPendingChanges]) {
		[MM_SFChange pushPendingChangesWithCompletionBlock: ^(BOOL completed) {
			if (completed) [self removeAllDataIncludingMetaData: NO withDelay: 0.3];
		}];
	} else {
		[self removeAllDataIncludingMetaData: NO withDelay: 0.0];
	}
}

- (void) removeAllDataIncludingMetaData: (BOOL) andMetadata withDelay: (NSTimeInterval) delay {
	self.deletingAllData = YES;
	[self resetContextSetupTag];
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_WillRemoveAllData object: nil];
	
	[NSObject performBlock: ^{
		[MMSF_Object clearSFIDCache];
		[NSManagedObject clearRobustObjectIDs];
		[self clearContext: self.mainContentContext];				//we clear the content database here
		if (andMetadata) [self clearContext: self.mainMetaContext];	//and we clear the metadata here

		NSError						*error = nil;
		NSString					*directory = [MMSF_Object privateDocumentsPath];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: directory]) {
			if (![[NSFileManager defaultManager] removeItemAtPath: directory error: &error])
				[SA_AlertView showAlertWithTitle: @"An error occurred while clearing out files and attachments." error: error];

			[[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories: YES attributes: nil error: &error];
		}
		
        _mainContentContext = nil;
        if (andMetadata) {
            _mainMetaContext = nil;
            [[NSFileManager defaultManager] removeItemAtPath: [self.metaContextPath stringByDeletingLastPathComponent] error: &error];
            [self mainMetaContext];
        }
		
		self.deletingAllData = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_DidRemoveAllData object: nil];
		[self resetContextSetupTag];
	} afterDelay: 0.3];
}

- (NSManagedObjectContext *) contentContextForWriting {
	MM_ManagedObjectContext		*ctx = nil;
	if (self.deletingAllData) return nil;
	
//	@synchronized (self) {
		MM_ManagedObjectContext		*parent = self.mainContentContext;
		if (parent == nil) return nil;
		
		ctx = [[MM_ManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
		ctx.usesMMIDs = YES;
		ctx.contextSetupTag = self.contextSetupTag;

		ctx.saveThread = [NSThread currentThread];
		
		[ctx setParentContext: parent];
//	}
	return ctx;
}

- (NSManagedObjectContext *) contentContextForReading {
	MM_ManagedObjectContext		*ctx = nil;
	if (self.deletingAllData) return nil;
	
	@synchronized (self) {
		NSManagedObjectContext		*parent = self.mainContentContext;
		if (parent == nil) return nil;
		
		ctx = [[MM_ManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
		ctx.contextSetupTag = self.contextSetupTag;
		ctx.usesMMIDs = YES;
		ctx.parentContext = parent;
//		ctx.persistentStoreCoordinator = parent.persistentStoreCoordinator;
	}
	return ctx;
}

- (void) resetContentContext {
	_contentModel = nil;
	_mainContentContext = nil;
}

- (id) objectInNewContext: (NSManagedObject *) object {
	id			newObject = [self.contentContextForWriting objectWithID: object.objectID];
	
	if (newObject) return newObject;
	
	newObject = [self.threadMetaContext objectWithID: object.objectID];
	return newObject;
}

+ (void) saveContentContext {
	[[MM_ContextManager sharedManager] saveContentContext];
}

+ (void) saveMetaContext {
	[[MM_ContextManager sharedManager] saveMetaContext];
}

- (void) saveMetaContext { [self saveMetaContextWithBlock: nil]; }

- (void) saveMetaContextWithBlock: (simpleBlock) block {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self saveMetaContextWithBlock: block]; });
		return;
	}
	
	[self.saveLock lock];
	[self.mainMetaContext save];
	[self.saveLock unlock];
	if (block) block();
}

- (void) saveContentContext { [self saveContentContextWithBlock: nil]; }

- (void) saveContentContextWithBlock: (simpleBlock) block {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self saveContentContextWithBlock: block];
	//		if (block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		});
		return;
	}
	if (!self.deletingAllData) [self.mainContentContext save];
	if (block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

- (void) saveAndClearContentContext { 
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self saveAndClearContentContext]; });
		return;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_WillResetMainContext object: nil];
	[self.saveLock lock];
	[self.mainContentContext save];
	[self.saveLock unlock];

	[self.mainContentContext reset];
}

//=============================================================================================================================
#pragma mark Properties
- (MM_ManagedObjectContext *) contextAtPath: (NSString *) path model: (NSManagedObjectModel *) model {
	NSDictionary						*options = [NSDictionary dictionaryWithObjectsAndKeys: 
													[NSNumber numberWithBool: YES], NSMigratePersistentStoresAutomaticallyOption, 
													[NSNumber numberWithBool: YES], NSInferMappingModelAutomaticallyOption, 
													s_storeFileProtection, NSPersistentStoreFileProtectionKey,
												nil];
	NSError								*error = nil;
	
	if (![[NSFileManager defaultManager] createDirectoryAtPath: [path stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: &error]) {
		MMLog(@"Failed to creat directory at %@: %@", path, error);
		return nil;
	}
	
	if (model == nil) model = [NSManagedObjectModel mergedModelFromBundles: nil];
	
	NSPersistentStoreCoordinator		*coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
	@try {
		[coordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: path] options: options error: &error];
	} @catch (NSException *e) {
		MMLog(@"Exception while opening database: %@", e);
		
		[[NSFileManager defaultManager] removeItemAtPath: path error: &error];
		[coordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: path] options: options error: &error];
	}
		
	if (coordinator.persistentStores.count == 0) {
        NSString* message=nil;
		
        message = [NSString stringWithFormat: @"The database format has changed. The existing database (%@) has been removed.", [path lastPathComponent]];
		
		MMLog(@"%@", message);
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_PersistentStoreResetDueToSchemaChange object: nil];
			
		[[NSFileManager defaultManager] removeItemAtPath: path error: &error];
		[coordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: path] options: options error: &error];
	}
	
	if (coordinator.persistentStores.count) {
		NSPersistentStore		*mainStore = coordinator.persistentStores[0];
		
		MMLog(@"\n\nMain Persistent Store ID: %@ at %@\n\n", mainStore.identifier, mainStore.URL.path);
	}
		
	if (error) MMLog(@"Error while adding persistant store: %@ (%@)", error, error.userInfo);
	
	MM_ManagedObjectContext			*objectContext = nil;

	objectContext = [[MM_ManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
	objectContext.saveThread = [NSThread currentThread];
	objectContext.contextSetupTag = self.contextSetupTag;

	[objectContext setPersistentStoreCoordinator: coordinator];
	
	return objectContext;
	
}

- (NSManagedObjectContext *) mainMetaContext {
	if (_mainMetaContext == nil) {
		NSString			*contextPath = self.metaContextPath;
		
		_mainMetaContext = [self contextAtPath: contextPath model: self.metaContextModel];
		
		if (s_dataModelVersion) {
			NSMutableDictionary					*info = _mainMetaContext.primaryStoreMetadata.mutableCopy;
			
			if (info[kMetaDataKey_ModelVersionNumber] == nil) {
				info[kMetaDataKey_ModelVersionNumber] = @(s_dataModelVersion);
				_mainMetaContext.primaryStoreMetadata = info;
				[_mainMetaContext save];
			}
		}
	}
	return _mainMetaContext;
}

- (NSManagedObjectContext *) mainContentContext {
	if (_mainContentContext == nil) {
		
		if (self.contentModel == nil) return nil;
		_mainContentContext = [self contextAtPath: self.contentContextPath model: self.contentModel];
		_mainContentContext.usesMMIDs = YES;

	}
	return _mainContentContext;
}

static NSUInteger		s_threadCountIndex = 0;

- (NSManagedObjectContext *) threadMetaContext {
	if (self.deletingAllData) return nil;
	
	NSMutableDictionary		*threadDict = [[NSThread currentThread] threadDictionary];
	MM_ManagedObjectContext	*moc = [threadDict objectForKey: META_CONTEXT_KEY];
	
	if (moc == nil || moc.contextSetupTag != self.contextSetupTag) {
		moc = (id) self.metaContextForWriting;
		moc.sourceThread = [NSThread currentThread];
        if (moc) {
            [threadDict setObject: moc forKey: META_CONTEXT_KEY];
            if (self.metaThreadContexts == nil)
                self.metaThreadContexts = [SA_ThreadsafeMutableArray array];
            [self.metaThreadContexts addObject: moc];
            
            if (moc.sourceThread.name.length == 0)
                moc.sourceThread.name = $S(@"MM_Named Thread %d", (UInt16) s_threadCountIndex++);
        }
	}
//	dispatch_async(dispatch_get_main_queue(), ^{ [self cancelAndPerformSelector: @selector(reapContexts) withObject: nil afterDelay: 5.0];});
	return moc;
}

- (NSManagedObjectContext *) threadContentContext {
	if (self.deletingAllData) return nil;
	
	if ([NSThread isMainThread]) return self.mainContentContext;
	NSMutableDictionary		*threadDict = [[NSThread currentThread] threadDictionary];
	MM_ManagedObjectContext	*moc = [threadDict objectForKey: CONTENT_CONTEXT_KEY];
	
	if (moc == nil || moc.contextSetupTag != self.contextSetupTag) {
		moc = (id) self.contentContextForWriting;
		if (moc) {
			moc.sourceThread = [NSThread currentThread];
			[threadDict setObject: moc forKey: CONTENT_CONTEXT_KEY];
			if (self.threadContexts == nil) self.threadContexts = [SA_ThreadsafeMutableArray array];
			[self.threadContexts addObject: moc];
		}

		if (moc.sourceThread.name.length == 0) moc.sourceThread.name = $S(@"MM_Named Thread %d", (UInt16) s_threadCountIndex++);
	}

//	dispatch_async(dispatch_get_main_queue(), ^{ [self cancelAndPerformSelector: @selector(reapContexts) withObject: nil afterDelay: 5.0];});
	return moc;
}

- (dispatch_queue_t) importDispatchQueue {
	if (_importDispatchQueue == nil) {
		_importDispatchQueue = dispatch_queue_create("importDispatchQueue", DISPATCH_QUEUE_SERIAL);
	}
	return _importDispatchQueue;
}

- (NSManagedObjectModel *) contentModel {
	if (_contentModel == nil) {
		NSString				*path = self.contentModelPath;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: path]) _contentModel = [NSManagedObjectModel modelWithContentsOfFile: path];
	}
	return _contentModel;
}

- (NSManagedObjectModel *) metaContextModel {
	if (_metaContextModel == nil) {
        if (s_metadataModelRoot == nil)
        {
            NSString			*modelPath = [[NSBundle mainBundle] pathForResource: @"MetaModel" ofType: @"momd"];
            BOOL				isDirectory;
			
            if ([[NSFileManager defaultManager] fileExistsAtPath: modelPath isDirectory: &isDirectory]) {
				if (isDirectory)
					_metaContextModel = [NSManagedObjectModel modelWithContentsOfFile: [modelPath stringByAppendingPathComponent: @"MetaModel.mom"]];
				else
					_metaContextModel = [NSManagedObjectModel modelWithContentsOfFile: modelPath];
            }
            
            if ([[NSFileManager defaultManager] fileExistsAtPath: modelPath]) _metaContextModel = [NSManagedObjectModel modelWithContentsOfFile: modelPath];
            
            if (_metaContextModel == nil) _metaContextModel = [NSManagedObjectModel mergedModelFromBundles: nil];
            if (_metaContextModel.entities.count == 0) {
                _metaContextModel = nil;
                MMLog(@"Unable to load meta context. Make sure the meta mom is included in your project %@", @"");
            }
            SA_Assert(_metaContextModel.entities.count > 0, @"Unable to load meta context. Make sure the meta mom is included in your project");
        }
        else
        {
            _metaContextModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:s_metadataModelRoot];
        }
	}
	return _metaContextModel;
}

- (BOOL) objectExistsInContentModel: (NSString *) objectName {
	if (self.mainContentContext == nil) return NO;
	return [NSEntityDescription entityForName: objectName inManagedObjectContext: self.mainContentContext] != nil;
}

- (BOOL) missingLinksAreConnectedForObjectNamed: (NSString *) objectName {
	NSDictionary			*info = self.mainContentContext.primaryStoreMetadata;
	NSArray					*connectedObjects = [info objectForKey: kMetaDataKey_ConnectedObjectNames];
	
	return ([connectedObjects containsObject: objectName]);
}

- (void) setMissingLinksAreConnected: (BOOL) exist forObjectNamed: (NSString *) objectName {
	if (objectName == nil) return;

	NSDictionary			*info = self.mainContentContext.primaryStoreMetadata;
	NSSet					*connectedObjects = [info objectForKey: kMetaDataKey_ConnectedObjectNames];
	NSMutableArray			*newList = [connectedObjects mutableCopy] ?: [NSMutableArray array];
	
	if (exist)
		[newList addObject: objectName];
	else if (![newList containsObject: objectName])
		[newList removeObject: objectName];
	
	NSMutableDictionary		*newInfo = [info mutableCopy] ?: [NSMutableDictionary dictionary];
	[newInfo setObject: newList forKey: kMetaDataKey_ConnectedObjectNames];
	self.mainContentContext.primaryStoreMetadata = newInfo;
}

@end

@implementation MM_ManagedObjectContext
NSInteger s_contextCount = 0;

- (NSManagedObject *) insertNewEntityWithName: (NSString *) name {
	NSManagedObject			*object = [super insertNewEntityWithName: name];
	
	if (self.usesMMIDs && [object hasValueForKey: MMID_FIELD]) object[MMID_FIELD] = object.generatedMMID;
	return object;
}

//- (void) save {
//	NSSet			*inserted = [self insertedObjects];
//	
//	if (self.usesMMIDs) {
//		for (MMSF_Object *object in inserted) {
//			if (!object.isDeleted && [object hasValueForKeyPath: MMID_FIELD] && object.Id == nil && object.mmID == nil) object.mmID = object.generatedMMID;
//		}
//	}
//	[super save];
//}

//- (id) initWithConcurrencyType: (NSManagedObjectContextConcurrencyType) ct {
//	if (self = [super initWithConcurrencyType: ct]) {
//		LOG(@"Created Context (%d)", ++s_contextCount);
//	}
//	return self;
//}
//
//- (void) dealloc {
//	LOG(@"Deleted Context (%d)", --s_contextCount);
//}

@end
