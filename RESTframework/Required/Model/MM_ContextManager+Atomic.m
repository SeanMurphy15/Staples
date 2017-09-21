//
//  MM_ContextManager+Atomic.m
//  McGraw Hill
//
//  Created by Ben Gottlieb on 4/7/14.
//  Copyright (c) 2014 Model Metrics. All rights reserved.
//

#import "MM_ContextManager+Atomic.h"
#import "MM_SFObjectDefinition.h"
#import "MM_Notifications.h"
#import "MM_Log.h"

@implementation MM_ContextManager (Atomic)



- (NSURL *) mainDBBackupURL {
	NSError				*error;
	NSURL				*dir = [[NSFileManager libraryDirectory] URLByAppendingPathComponent: @"Atomic_Backups"];
	[[NSFileManager defaultManager] createDirectoryAtURL: dir withIntermediateDirectories: YES attributes: nil error: &error];
	return [dir URLByAppendingPathComponent: @"main.db"];
}

- (void) copyExistingDataOffWithCompletion: (errorArgumentBlock) completion {
	[NSNotificationCenter postNotificationNamed: kNotification_WillMoveDataAsideForAtomicSync];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		LOG(@"Moving data aside");
		[self.saveLock lock];
		NSURL			*mainSrc = [NSURL fileURLWithPath: self.contentContextPath];
		NSError			*error = nil;
		
		[self deleteDatabaseAtURL: self.mainDBBackupURL];
		
		[[NSFileManager defaultManager] copyItemAtURL: mainSrc toURL: self.mainDBBackupURL error: &error];

		[self.saveLock unlock];
		LOG(@"Data moved aside");
		dispatch_on_main_queue(^{
			[NSNotificationCenter postNotificationNamed: kNotification_DidMoveDataAsideForAtomicSync];
		});
		if (completion) completion(error);
	});
}

- (void) restoreBackedUpDataWithCompletion: (errorArgumentBlock) completion {
	NSError										*error;
	
	if (self.isBackedUpDataAvailable) {
		LOG(@"Restoring data that was moved aside");
		[NSNotificationCenter postNotificationNamed: kNotification_WillBeginAtomicRestore];
		[MM_SFObjectDefinition clearCachedObjectDefinitions];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: self.mainDBBackupURL.path]) {
			error = [self replaceStoreInContext: self.mainContentContext withURL: self.mainDBBackupURL];
			if (error) LOG(@"Error while replacing Main DB: %@", error);
		}

		[self clearBackedUpDataWithCompletion: nil];
		[NSNotificationCenter postNotificationNamed: kNotification_DidCompleteAtomicRestore];
	}
	
	if (completion) completion(error);
}

- (NSError *) replaceStoreInContext: (NSManagedObjectContext *) moc withURL: (NSURL *) url {
	NSPersistentStoreCoordinator		*psc = moc.persistentStoreCoordinator;
	NSError								*error = nil;
	
	[moc lock];
	[moc reset];
	
	if (psc.persistentStores.count > 0) {
		NSPersistentStore				*store = psc.persistentStores[0];
		NSURL							*storeURL = store.URL;
		
		[psc removePersistentStore: store error: &error];
		
		[self deleteDatabaseAtURL: storeURL];
		if (url) [[NSFileManager defaultManager] moveItemAtURL: url toURL: storeURL error: &error];
		
		[psc addPersistentStoreWithType: store.type configuration: store.configurationName URL: storeURL options: store.options error: &error];
	}
	
	[moc unlock];
	return error;
}

- (void) clearBackedUpDataWithCompletion: (errorArgumentBlock) completion {
	NSError			*error = nil;
	[self deleteDatabaseAtURL: self.mainDBBackupURL];
	
	if (completion) completion(error);
}

- (BOOL) isBackedUpDataAvailable {
	return [[NSFileManager defaultManager] fileExistsAtPath: self.mainDBBackupURL.path];
}

- (void) deleteDatabaseAtURL: (NSURL *) url {
	NSError				*error;
	NSArray				*contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: url.URLByDeletingLastPathComponent includingPropertiesForKeys: nil options: 0 error: &error];
	NSString			*name = [[url lastPathComponent] stringByDeletingPathExtension];
	
	for (NSURL *fileURL in contents) {
		if ([fileURL.lastPathComponent.stringByDeletingPathExtension isEqual: name]) {
			[[NSFileManager defaultManager] removeItemAtURL: fileURL error: &error];
		}
	}
}

- (void) clearAllDataWithCompletion: (errorArgumentBlock) completion {
	NSError										*error;
	
	[NSNotificationCenter postNotificationNamed: kNotification_WillClearAllData];
	[MM_SFObjectDefinition clearCachedObjectDefinitions];
	
	error = [self replaceStoreInContext: self.mainContentContext withURL: nil];
    if (error) {
        MMLog(@"Error replacing store: %@", error);
    }
	error = [self replaceStoreInContext: self.mainMetaContext withURL: nil];
    if (error) {
        MMLog(@"Error replacing store: %@", error);
    }
	
	[NSNotificationCenter postNotificationNamed: kNotification_DidClearAllData];
	if (completion) completion(error);
}


@end
