//
//  NSManagedObjectModel+MM.m
//  DynamicCoreData
//
//  Created by Ben Gottlieb on 10/2/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "NSManagedObjectModel+MM.h"
#import "MM_SFObjectDefinition.h"
#import "MM_ContextManager.h"
#import "MM_Log.h"
#import "MM_Constants.h"

//deprecate the MM_ManagedObjectModel, switch to a category. Keep the class definition around just so we can unarchive properly
@interface MM_ManagedObjectModel : NSManagedObjectModel
@end

@implementation MM_ManagedObjectModel
@end

@implementation NSManagedObjectModel (MM)

+ (id) modelWithObjects: (NSArray *) objects {
	NSManagedObjectModel			*model = [self createModel];
	
	for (MM_SFObjectDefinition *object in objects) {
		NSEntityDescription			*desc = [object entityDescription];
		
		if (desc) [model addEntities: desc, nil];
	}
	
	[model resolveAllPendingRelationships];
	return model;
}

+ (id) createModel {
	NSManagedObjectModel			*model = [[NSManagedObjectModel alloc] init];
	return model;
}

+ (id) modelWithContentsOfFile: (NSString *) path {
	return [NSKeyedUnarchiver unarchiveObjectWithFile: path];
}

- (BOOL) attemptMigrationOfContextAtPath: (NSString *) contextPath fromOldModel: (NSManagedObjectModel *) oldModel {
	NSError							*error = nil;
	NSMappingModel					*mapping = [NSMappingModel inferredMappingModelForSourceModel: oldModel destinationModel: self error: &error];
	
	if (error) {
		MMLog(@"Error while inferring mapping model: %@", error);
		return NO;
	}
	
	NSString						*newContextPath = [contextPath stringByAppendingPathExtension: @"tmp"];
	NSValue							*classValue = [[NSPersistentStoreCoordinator registeredStoreTypes] objectForKey: NSSQLiteStoreType];
	Class							sqliteStoreClass = (Class)[classValue pointerValue];
	Class							sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
	NSURL							*srcURL = [NSURL fileURLWithPath: contextPath], *dstURL = [NSURL fileURLWithPath: newContextPath];
	NSMigrationManager				*manager = [[sqliteStoreMigrationManagerClass alloc] initWithSourceModel: oldModel destinationModel: self];
	
	@try {
		if (![manager migrateStoreFromURL: srcURL type:NSSQLiteStoreType options:nil withMappingModel:mapping toDestinationURL: dstURL destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
			MMLog(@"Migration failed %@", error);
			return NO;
		}
	} @catch (NSException *exception) {
		MMLog(@"Exception: %@", exception);
		return NO;
	}
	
	if (![[NSFileManager defaultManager] removeItemAtPath: contextPath error: &error]) {
		MMLog(@"Error removing old database: %@", error);
		return NO;
	}
	
	if (![[NSFileManager defaultManager] moveItemAtPath: newContextPath toPath: contextPath error: &error]) {
		MMLog(@"Error renaming/moving new database: %@", error);
		return NO;
	}
	
	MMLog(@"- Context Migration: Complete %@", @"");
	
	return YES;
}

- (NSEntityDescription *) entityDescriptionNamed: (NSString *) name {
	for (NSEntityDescription *entity in self.entities) {
		if ([entity.name isEqual: name]) return entity;
	}
	return nil;
}

- (void) addEntities: (NSEntityDescription *) firstEntity, ... {
	NSMutableArray			*entities = [self.entities mutableCopy];
	
	va_list					marker;
	
	va_start(marker, firstEntity);
	while (firstEntity) {
		[entities addObject: firstEntity];
		firstEntity = va_arg(marker, NSEntityDescription *);
	}
	va_end(marker);
	
	self.entities = entities;
}

- (NSManagedObjectContext *) generateContextAtPath: (NSString *) path ofType: (NSInteger) type {
	NSDictionary					*options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool: YES], NSInferMappingModelAutomaticallyOption, nil];
	NSPersistentStoreCoordinator	*coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self];
	NSError							*error = nil;
	
	[coordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: path] options: options error: &error];
	
	NSManagedObjectContext			*objectContext = nil;
	//	if (RUNNING_ON_50)
	//		objectContext = [(id) [NSManagedObjectContext alloc] initWithConcurrencyType: type];
	//	else
	objectContext = [[NSManagedObjectContext alloc] init];
	
	objectContext.saveThread = [NSThread currentThread];
	[objectContext setPersistentStoreCoordinator: coordinator];
	return objectContext;
}

- (void) writeToFile: (NSString *) path {
	[NSKeyedArchiver archiveRootObject: self toFile: path];
}

- (void) resolveAllPendingRelationships {
	for (NSEntityDescription *entity in self.entities) {
		[entity resolvePendingRelationshipsInModel: self];
	}
}

@end

static NSMutableDictionary *s_cachedRobustObjectIDs = nil;

@implementation NSManagedObjectContext (MM)

- (id) objectWithRobustIDString: (NSString *) robustObjectIDString {
	if ([robustObjectIDString hasPrefix: MMID_PREFIX]) {
		NSString				*entity = [robustObjectIDString componentsSeparatedByString: @"|"][1];
		NSPredicate				*pred = $P(MMID_FIELD " == %@", robustObjectIDString);
		
		return [self anyObjectOfType: entity matchingPredicate: pred];
	}
	
	NSManagedObjectID				*managedID = nil;
	NSManagedObject					*object = nil;
	
	if ([robustObjectIDString isKindOfClass: [NSURL class]]) {
		@try {
			managedID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation: (id) robustObjectIDString];
			
			if (managedID) object = [self objectWithID: managedID];
			if (object) return object;
		} @catch (id e) {
			
		}
	}
	if (![robustObjectIDString isKindOfClass: [NSString class]]) return nil;
	
	NSURL							*url = [NSURL URLWithString: robustObjectIDString];
	if (url == nil) return nil;
	
	[NSManagedObject loadRobustObjectIDsCache];
	
	managedID = s_cachedRobustObjectIDs[robustObjectIDString];
	
	@try {
		if (managedID == nil) managedID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation: url];
	} @catch (id e) { }
	if (managedID == nil) return nil;
	
	
	object = [self objectWithID: managedID];
	
	
	if (object) {
		if (!object.isInserted) return nil;
		@try {
			[object valueForKey: @"Id"];
		} @catch (NSException *e) {
			MMLog(@"Exception while retrieving object: %@", url);
			object = nil;
		}
		
		if (object) return object;
	}
	
	managedID = [s_cachedRobustObjectIDs objectForKey: robustObjectIDString];
	
	if (managedID) return [self objectWithID: managedID];
	return nil;
}

@end

#define			OBJECT_IDS_CACHE_PATH				[@"~/Library/objectIDsLookup.dict" stringByExpandingTildeInPath]

@implementation NSManagedObject (MM)
- (NSString *) generatedMMID {
	return [NSString stringWithFormat: @"%@|%@|%@", MMID_PREFIX, self.entity.name, [NSString uuid]];
}

+ (void) cleanUpRobustObjectIDCache {
	if (s_cachedRobustObjectIDs.count == 0) return;
	
	NSManagedObjectContext			*moc = [MM_ContextManager sharedManager].contentContextForWriting;
	BOOL							changed = NO;
	
	for (NSString *key in s_cachedRobustObjectIDs.allKeys) {
		NSManagedObjectID			*objectID = s_cachedRobustObjectIDs[key];
		NSManagedObject				*object = [moc objectWithID: objectID];
		
		if (!objectID.isTemporaryID) continue;
		if (object == nil) {											//object is gone, don't save it's ID
			[s_cachedRobustObjectIDs removeObjectForKey: key];
			changed = YES;
		} else if (![object.objectID isEqual: objectID] && !object.objectID.isTemporaryID) {	//object now has a permanent ID, update it
			s_cachedRobustObjectIDs[key] = object.objectID;
			changed = YES;
		}
	}
	
	if (changed) {
		[self saveRobustObjectIDsCache];
	}
}

+ (void) loadRobustObjectIDsCache {
	if (s_cachedRobustObjectIDs != nil) return;
	
	NSDictionary			*dict = [NSDictionary dictionaryWithContentsOfFile: OBJECT_IDS_CACHE_PATH];
	
	if (s_cachedRobustObjectIDs == nil) s_cachedRobustObjectIDs = [[NSMutableDictionary alloc] init];
	
	NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].mainContentContext;
	NSPersistentStoreCoordinator		*coord = moc.persistentStoreCoordinator;
	
	for (NSString *key in dict.allKeys) {
		NSString							*string = dict[key];
		
		if (![string isKindOfClass: [NSString class]]) continue;
		
		TRY(
			NSURL								*uri = [NSURL URLWithString: string];
			NSManagedObjectID					*objectID = [coord managedObjectIDForURIRepresentation: uri];
			
			if (objectID) s_cachedRobustObjectIDs[key] = objectID;
			);
	}
}

+ (void) saveRobustObjectIDsCache {
	NSMutableDictionary					*saved = [NSMutableDictionary dictionary];
	NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].mainContentContext;
	
	for (NSString *key in s_cachedRobustObjectIDs) {
		NSManagedObjectID			*objectID = s_cachedRobustObjectIDs[key];
		
		if (objectID.isTemporaryID) {
			objectID = [moc objectWithID: objectID].objectID;
			if (objectID.isTemporaryID) continue;
		}
		saved[key] = objectID.URIRepresentation.absoluteString;
	}
	
	[saved writeToFile: OBJECT_IDS_CACHE_PATH atomically: YES];
}

- (NSString *) robustIDString {
	if ([self hasValueForKey: MMID_FIELD] && self[MMID_FIELD]) return self[MMID_FIELD];
	
	NSManagedObjectID				*objectID = self.objectID;
	NSString						*uriString = objectID.URIRepresentation.absoluteString;
	
	if (!objectID.isTemporaryID) return uriString;
	
	if (self[MMID_FIELD]) return self[MMID_FIELD];
	
	[NSManagedObject loadRobustObjectIDsCache];
	
	NSData							*cached = [s_cachedRobustObjectIDs objectForKey: uriString];
	if (cached) return uriString;
	
	[s_cachedRobustObjectIDs setObject: objectID forKey: uriString];
	[NSManagedObject cancelAndPerformSelector: @selector(saveRobustObjectIDsCache) withObject: nil afterDelay: 1.0];
	return uriString;
}

+ (void) clearRobustObjectIDs {
	[s_cachedRobustObjectIDs removeAllObjects];
	NSError				*error;
	
	[[NSFileManager defaultManager] removeItemAtPath: OBJECT_IDS_CACHE_PATH error: &error];
}
@end