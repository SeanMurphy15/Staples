//
//  MM_OrgMetaData.m
//  SFRestTesting
//
//  Created by Ben Gottlieb on 11/18/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_OrgMetaData.h"
#import "MM_ContextManager.h"
#import "MM_SFObjectDefinition.h"
#import "MM_Notifications.h"
#import "MM_SyncManager.h"
#import "MM_Log.h"

@interface MM_OrgMetaData ()
@property (nonatomic, readonly) BOOL okayToMutateModel;
@end

@implementation MM_OrgMetaData
@synthesize objectsToSync = _objectsToSync;

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(MM_OrgMetaData, sharedMetaData);

- (void) setAllObjectsToSync: (NSArray *) objectsToSync {
	if (!self.okayToMutateModel) return;
	
	NSMutableArray				*list = [NSMutableArray array];
	NSMutableArray				*names = [NSMutableArray array];
	
	for (id obj in objectsToSync) {
		NSString			*objectName = [obj isKindOfClass: [NSString class]] ? obj : [obj objectForKey: @"name"];
		NSDictionary		*objInfo = [obj isKindOfClass: [NSString class]] ? $D(objectName, @"name") : obj;

		#if ALLOW_OBJECT_REMAPPING
			if ([objInfo isKindOfClass: [NSDictionary class]] && objInfo[@"server-name"]) objectName = objInfo[@"server-name"];
		#endif
				

		if ([names containsObject: objectName]) {
			MMLog(@"Trying to add the same object to the sync list twice: %@", objectName);
			continue;
		}
		
		[list addObject: objInfo];
		[names addObject: objectName];
	}
	
	_objectsToSync = list;	
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_OrgSyncObjectsChanged object: names];
}

- (BOOL) isObjectSynced: (NSString *) object { return [self syncObjectNamed: object] != nil; }

- (NSDictionary *) syncObjectNamed: (NSString *) name {
	for (NSDictionary *obj in self.objectsToSync) {
		if ([[obj objectForKey: @"name"] isEqual: name]) return obj;
	}
	return nil;
}

- (void) setSyncObjectInfo: (NSDictionary *) info {
	NSMutableArray				*objects = self.objectsToSync.mutableCopy;
	NSDictionary				*existing = [self syncObjectNamed: info[@"name"]];
	
	if (existing)
		[objects replaceObjectAtIndex: [objects indexOfObject: existing] withObject: info];
	else
		[objects addObject: info];
	
	self.objectsToSync = objects;
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_OrgSyncObjectsChanged object: $A(info[@"name"])];
}


- (void) addObjectToSyncList: (NSString *) objectName {
	if ([self isObjectSynced: objectName] || !self.okayToMutateModel) return;

	[self setSyncObjectInfo: @{ @"name": objectName }];
}

- (void) resetObjectsToSync {
	_objectsToSync = nil;
}

- (NSString *) editedSyncObjectsPath {
	return [[NSFileManager libraryDirectory] URLByAppendingPathComponent: @"sync_objects.plist"].path;
}

- (void) setObjectsToSync: (NSArray *) objectsToSync {
	NSError				*error = nil;
	NSString			*errorMessage = nil;
	NSData				*plistData = [NSPropertyListSerialization dataFromPropertyList: @{ @"objects": objectsToSync} format: NSPropertyListBinaryFormat_v1_0 errorDescription: &errorMessage];
	
	if (errorMessage) [SA_AlertView showAlertWithTitle: @"There Was a Problem When Saving your Sync'd Objects" message: errorMessage];
	
	if (plistData) [plistData writeToFile: self.editedSyncObjectsPath options: NSDataWritingAtomic error: &error];
	
	if (error) [SA_AlertView showAlertWithTitle: @"There Was a Problem When Saving your Sync'd Objects" error: error];
	_objectsToSync = objectsToSync;
}

- (NSArray *) objectsToSync {
	if (_objectsToSync == nil) {
		NSString				*path = self.editedSyncObjectsPath;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: path]) path = [[NSBundle mainBundle] pathForResource: @"sync_objects" ofType: @"plist"];

		NSData					*data = [NSData dataWithContentsOfFile: path];
		NSPropertyListFormat	format;
		NSError					*error = nil;
		if (data) {
			NSDictionary			*plist = [NSPropertyListSerialization propertyListWithData: data options: 0 format: &format error: &error]; 
			if (error) [SA_AlertView showAlertWithTitle: @"Error while reading in list of objects to sync" error: error];
		
			_objectsToSync = [plist objectForKey: @"objects"];
		} else {
			_objectsToSync = [NSArray array];
		}
		
		NSInteger				userIndex = -1;
		
		for (NSDictionary *item in _objectsToSync) {
			if ([item[@"name"] isEqual: @"User"]) {
				userIndex = [_objectsToSync indexOfObject: item];
				break;
			}
		}
		
		if (userIndex != 0) {
			NSMutableArray				*objects = _objectsToSync.mutableCopy;
			
			if (userIndex == -1) {
				[objects insertObject: @{ @"name": @"User" } atIndex: 0];
			} else {
				NSDictionary			*user = objects[userIndex];
				
				[objects removeObjectAtIndex: userIndex];
				[objects insertObject: user atIndex: 0];
			}
			_objectsToSync = objects;
		}
	}
	
	return _objectsToSync;
}

- (BOOL) isMetadataAvailableForObjects: (NSArray *) objects {
	NSManagedObjectContext		*ctx = [MM_ContextManager sharedManager].threadMetaContext;
	
	if ([ctx numberOfObjectsOfType: [MM_SFObjectDefinition entityName] matchingPredicate: nil] == 0) return NO;
	
	if (objects == nil) objects = [MM_OrgMetaData sharedMetaData].objectsToSync;
		
	for (NSDictionary *objectInfo in objects) {
		NSString			*name = objectInfo[@"name"];
		
		MM_SFObjectDefinition			*object = [MM_SFObjectDefinition objectNamed: name inContext: ctx];
		
		if (object.metaDescription_mm == nil) return NO;
	}
	return YES;
}


//=============================================================================================================================
#pragma mark Private
- (BOOL) okayToMutateModel {
	if ([MM_SyncManager sharedManager].isModelUpdateInProgress) {
		[SA_AlertView showAlertWithTitle: @"Model Update in Progress" message: @"You cannot modify your object sync list while the model is updating. Please try again later."];
		return NO;
	}
	
	if ([MM_SyncManager sharedManager].isSyncInProgress) {
		[SA_AlertView showAlertWithTitle: @"Sync in Progress" message: @"You cannot modify your object sync list while synchronizing. Please try again later."];
		return NO;
	}
	
	return YES;
}



@end
