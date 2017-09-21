//
//  MMSF_Object.m
//  SFRestTesting
//
//  Created by Ben Gottlieb on 11/19/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MMSF_Object.h"
#import "MM_SFObjectDefinition.h"
#import "MM_Constants.h"
#import "MM_SFChange.h"
#import "MM_RestOperation.h"
#import "MM_SyncManager.h"
#import "MM_Log.h"
#import "MM_ContextManager.h"
#import "MM_Notifications.h"
#import "MM_Constants.h"
#import "NSEntityDescription+MM.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_LoginViewController.h"
#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SalesforceNativeSDK/SFRestAPI.h>

static NSString *s_dataBlobDirectoryPath = nil;
static NSInteger s_disableDynamicRecordLinking = 0;

@interface MMSF_Object()
@property BOOL connectingLinks; 
- (id) importRecord: (NSDictionary *) record withFieldPrefix: (NSString *) prefix includingDataBlobs: (BOOL) includingDataBlobs;
@end

@implementation MMSF_Object
@synthesize lastSnapshot, connectingLinks, shouldRollbackFailedSaves, fieldsToForceToServer, editCount;
@dynamic Id, RecordTypeId, LastModifiedDate, CreatedDate, SystemModStamp, Name;

+ (NSString *) privateDocumentsPath {
	return [@"~/Library/Private Documents" stringByExpandingTildeInPath];
}

+ (void) initialize {
	@autoreleasepool {
		if (s_dataBlobDirectoryPath == nil) [self setDataBlobDirectoryPath: [self privateDocumentsPath]];
		s_sfidCache = [SA_ThreadsafeMutableDictionary dictionary];
	}
}

+ (void) setDataBlobDirectoryPath: (NSString *) path {
	path = [path stringByExpandingTildeInPath];
	if ([s_dataBlobDirectoryPath isEqualToString: path]) return;
	
	s_dataBlobDirectoryPath = path;
	
	NSError							*error = nil;
	
	[[NSFileManager defaultManager] createDirectoryAtPath: path withIntermediateDirectories: YES attributes: nil error: &error];
	if (error) NSLog(@"********* ERROR: while trying to create Data Blob directory at %@: %@", path, error);
	[NSFileManager setFileAtURLNotBackedUp: [NSURL fileURLWithPath: path]];
}

+ (NSString *) entityName {
	if ([self isEqual: [MMSF_Object class]]) {
		MMLog(@"Can't get an entity name for a generic MMSF_Object %@", @"");
		return nil;
	}
	
	NSString			*className = NSStringFromClass(self);
	
	return [className substringFromIndex: 5];
}

+ (void) setDynamicRecordLinkingEnabled: (BOOL) enabled {
	if (enabled) {
		if (s_disableDynamicRecordLinking) s_disableDynamicRecordLinking--;
	} else {
		s_disableDynamicRecordLinking++;
	}
}

+ (BOOL) isDynamicRecordLinkingEnabled { return s_disableDynamicRecordLinking == 0; }

+ (void) connectReturnedSalesforceID: (NSString *) sfid toObjectID: (NSString *) objectID forField: (NSString *) field onEntity: (NSString *) entityName inContext: (NSManagedObjectContext *) moc {
	NSString			*predicateString = [RELATIONSHIP_OBJECTID_SHADOW(field) stringByAppendingString: @" = %@"];
	NSArray				*results = [moc allObjectsOfType: @"Note" matchingPredicate: $P(predicateString, objectID)];
	
	for (MMSF_Object *object in results) {
	//	[object beginEditing];
		[object setValue: sfid forKey: field];
	//	[object finishEditingSavingChanges: YES andPushingToServer: NO];
	}
	[moc save];
}

- (id) importRecord: (NSDictionary *) record includingDataBlobs: (BOOL) includingDataBlobs {
	return [self importRecord: record withFieldPrefix: nil  includingDataBlobs: includingDataBlobs];
}

- (void) deleteFromSalesforceAndLocalPushingChanges: (BOOL) pushChanges {
	NSManagedObjectContext			*moc = self.moc;
	
	[MM_SFChange removePendingChangesForObject: self];
	[self deleteFromSalesforcePushingChanges: pushChanges];
	[moc save];
	[MM_ContextManager saveContentContext];
}

- (void) deleteFromSalesforceAndLocal {
	[self deleteFromSalesforceAndLocalPushingChanges: YES];
}

- (void) deleteFromSalesforce {
	[self deleteFromSalesforcePushingChanges:YES];
}

- (void) deleteFromSalesforcePushingChanges: (BOOL) pushChanges {
	[MM_SFChange queueDeleteForObject: self atTime: [NSDate date]];
	[self deleteFromContext];
	if (pushChanges) [MM_SFChange pushPendingChangesWithCompletionBlock: nil];
}

- (void) deleteFromContext {
	for (NSAttributeDescription *attr in self.entity.properties) {
		if (![attr isKindOfClass: [NSAttributeDescription class]]) continue;
		
		if (attr.attributeType == NSBinaryDataAttributeType) {
			NSString            *path = [self pathForDataField: attr.name includingSFID: YES];
			NSError				*error;

			[[NSFileManager defaultManager] removeItemAtPath: path error: &error];
			path = [self pathForDataField: attr.name includingSFID: NO];
			[[NSFileManager defaultManager] removeItemAtPath: path error: &error];
		}
	}
	[super deleteFromContext];
}

- (void) wasDeletedFromSalesforce {
	
}

- (BOOL) fieldIsReadOnly: (NSString *) field {
	NSDictionary						*info = [self.definition infoForField: field];
	
	if (self.Id && ![[info objectForKey: @"updateable"] boolValue]) return YES;
	if (!self.Id && ![[info objectForKey: @"createable"] boolValue]) return YES;
	return NO;
}

- (void) setValue: (id) value forKey: (NSString *) key {
	if ([value isKindOfClass: [NSData class]] && ([value length] > [MM_SyncManager sharedManager].maxAttachmentSize) && self.Id == nil) {
		[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Attachment Too Large", @"Attachment Too Large")
								 message: $S(NSLocalizedString(@"Attachments must be smaller than %d MB. This one is %d MB.", nil), [MM_SyncManager sharedManager].maxAttachmentSize / (1024 * 1024), [value length] / (1024 * 1024))];
		return;
	}

    if ([value isKindOfClass: [NSData class]] && [self descriptionForAttribute: key].attributeType == NSBinaryDataAttributeType) {
        NSString            *path = [self pathForDataField: key includingSFID: self.existsOnSalesforce];
        NSError             *error;
		
		if ([path containsCString: "(null)"]) NSLog(@"Be sure to set the proper fields for generating a path for the %@ field of a %@", key, self.entity.name);
        if (![value writeToFile: path options: NSDataWritingAtomic error: &error]) {
			MMLog(@"Error while writing %@ to %@: %@", key, self.entity.name, error);
		}
    }
	
	if (([key isEqual: @"WhatId"] || [key isEqual: @"WhoId"]) && [value isKindOfClass: [MMSF_Object class]]) value = [value Id];
	
	
//	if ([value isKindOfClass: [NSString class]] && value && [value length] == 0) {
//		NSString				*current = [self valueForKey: key];
//		
//	
//		if (current.length == 0) return;
//	}
	
    [super setValue: value forKey: key];
}

- (id) importRecord: (NSDictionary *) record withFieldPrefix: (NSString *) prefix includingDataBlobs: (BOOL) includingDataBlobs {
	NSNull					*null = [NSNull null];
	NSString				*shadowKey;
	#if ALLOW_FIELD_REMAPPING
		MM_SFObjectDefinition	*def = self.definition;
	#endif

	NSDictionary					*props = self.entity.propertiesByName;

	for (NSString *key in [record allKeys]) {
		if ([key isEqual: @"attributes"]) {
			NSString				*entityName = self.entity.name;
			
			if ([entityName isEqual: @"ContentVersion"]) {
				[self setValue: [record[key][@"url"] stringByAppendingPathComponent: @"VersionData"] forKey: DATA_URL_SHADOW(@"VersionData")];
				continue;
			} else if ([entityName isEqual: @"Attachment"]) {
				[self setValue: [record[key][@"url"] stringByAppendingPathComponent: @"body"] forKey: DATA_URL_SHADOW(@"Body")];
				continue;
			}
		}
		id				value = record[key];
		NSString		*fieldName = key;
		
		#if ALLOW_FIELD_REMAPPING
			fieldName = [def localNameForServerFieldName: key];
			if (fieldName == nil) {
				//fieldName = [def localNameForServerFieldName: key];
				fieldName = key;
			}
		#endif
		if ([key containsCString: "Geolocation__c"]) continue;
		if ([value isEqual: null]) value = nil;
		
		if ([value isKindOfClass: [NSDictionary class]]) {
			if ([key isEqual: @"VersionData"]) {			//can't handle these yet
				MMLog(@"Failed to download version data for %@", record);
				continue;
			}
			
			if ([key isEqual: @"Body"]) {
				NSString			*url = value[@"file"];
				
				if ([url isKindOfClass: [NSString class]]) [self setValue: url forKey: DATA_URL_SHADOW(key)];
				continue;
			}
			
			NSString			*newPrefix = [(prefix ?: @"") stringByAppendingFormat: @"%@%@", fieldName, JOIN_FIELD_SEPARATOR_STRING];
			
			[self importRecord: value withFieldPrefix: newPrefix includingDataBlobs: includingDataBlobs];
			continue;
		} else if (prefix) {
			NSString					*prefixedKey = $S(@"%@%@", prefix, fieldName);
			if ([self hasValueForKeyPath: prefixedKey])
				[self setValue: value forKey: prefixedKey];
			continue;
		}
		
		
		NSAttributeDescription		*attr = props[fieldName];
		NSAttributeType				type = [attr isKindOfClass: [NSAttributeDescription class]] ? attr.attributeType : NSUndefinedAttributeType;
		id							convertedValue = value;
        
		switch (type) {
			case NSDateAttributeType:
				convertedValue = [NSDate dateWithUNIXString: value];
				if (convertedValue == nil) convertedValue = [NSDate dateWithXMLString: value];
				break;

			case NSInteger16AttributeType:
			case NSInteger32AttributeType:
			case NSInteger64AttributeType:
				if ([value isKindOfClass: [NSString class]]) convertedValue = [NSNumber numberWithInt: [value intValue]];
				break;
				
			case NSDoubleAttributeType:
				if (value == nil) break;
				if ([value isKindOfClass: [NSString class]]) convertedValue = [NSNumber numberWithDouble: [value doubleValue]];
				break;

			case NSFloatAttributeType:
				convertedValue = [NSNumber numberWithFloat: [value floatValue]];
				break;

			case NSBinaryDataAttributeType:
				shadowKey = DATA_URL_SHADOW(key);
				if ([self descriptionForAttribute: shadowKey]) {
					[self setValue: value forKey: shadowKey];
					
					if (includingDataBlobs) [self cancelAndPerformSelector: @selector(refreshDataBlobsIfNeeded) withObject: nil afterDelay: 0];
				}
				continue;
				
			case NSUndefinedAttributeType:		//relationship
				shadowKey = RELATIONSHIP_SFID_SHADOW(key);
				if ([self descriptionForAttribute: shadowKey]) { 
					if (convertedValue == nil && [super valueForKey: fieldName] == nil) continue;				//no change. We call super here so as not to trigger our lazy-linking code
					if (convertedValue == nil) convertedValue = REMOVE_LINK_NAME;
					[self setValue: convertedValue forKey: shadowKey];
					[self setValue: @1 forKey: MISSING_LINK_ATTRIBUTE_NAME];
				}
				continue;
				
			default: break;
		}
		[self setValue: convertedValue forKey: fieldName];
	}
	return self;
	//[self refreshDataBlobsIfNeeded];
}

- (void) refreshDataBlobsIfNeeded {
	[self refreshDataBlobs: YES];
}

- (NSString *) blobDataFieldName {
	NSString		*entityName = self.entity.name;
	
	if ([entityName isEqual: @"Attachment"])
        return @"Body";
	if ([entityName isEqual: @"ContentVersion"])
        return @"VersionData";
    
	return nil;		//no blob data currently supported in any other object
}

- (void) refreshDataBlobs: (BOOL) onlyIfNeeded {
	NSString					*field = [self blobDataFieldName];
	if (field == nil) return;
	NSString					*url = [self valueForKey: DATA_URL_SHADOW(field)];
	
	if (url == nil) return;
	
	NSString					*path = [self pathForDataField: field includingSFID: YES];
	
	if (onlyIfNeeded && [[NSFileManager defaultManager] fileExistsAtPath: path]) return;						//file already exists, we're done

	MMVerboseLog(@"Downloading data for %@: %@", [self class], self.Id);
	MM_RestOperation			*mmRequest;
	NSString					*prefix = @"/services/data";
	NSManagedObjectID			*objectID = self.objectID;
	NSString					*sfID = self.Id;
	
	//MMLog(@"Found URL: %@ for file: %@", url, path);
	if (![url hasPrefix: prefix]) return;							//bad URL, bail

	
	NSString					*existing = [self valueForKey: DATA_PATH_SHADOW(field)];
	NSError						*error = nil;
	if (existing && [[NSFileManager defaultManager] fileExistsAtPath: existing]) {
		[[NSFileManager defaultManager] removeItemAtPath: existing error: &error];	//old file exists, delete it
	}

	//MMLog(@"Queing download for %@", self.Id);
	mmRequest = [MM_RestOperation dataOperationWithOAuthPath: url completionBlock: ^(NSError *error, id response, MM_RestOperation *completedOp) {
		BOOL						noDataReceived = ([response length] == 0 && ![[NSFileManager defaultManager] fileExistsAtPath: path]);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error || noDataReceived) {
				MMLog(@"----------------------------------------------------- Error while syncing -----------------------------------------------------\n %@", error);
				if (error.code == 401) {
					[MM_LoginViewController handleFailedOAuth];
				}

				NSLog(@"Problem (%@) downloading blob for %@", error, objectID);
				if (error) [[MM_Log sharedLog] logBlobDownloadError: error forField: field onObjectID: objectID];
				if (noDataReceived)
					[[MM_Log sharedLog] logBlobDownloadError: [NSError errorWithDomain: kMMFrameworkErrorDomain code: kMMFrameworkErrorNoData userInfo: nil] forField: field onObjectID: objectID];
			} else {
				//MMLog(@"Successfully downloaded %@ on %@", path, [NSThread isMainThread] ? @"Main Thread" : [[NSThread currentThread] name]);
				[NSFileManager setFileAtURLNotBackedUp: [NSURL fileURLWithPath: path]];
				[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_BlobDownloaded object: sfID userInfo: @{
					@"field": field,
				    @"objectID": self.objectID,
					@"entityName": self.entity.name
				 }];
			}
			[completedOp dequeue];
		});
		return YES;
	} sourceTag: CURRENT_FILE_TAG];
	
	NSString			*title = [self titleForDataField: nil];
	if (title.length) mmRequest.willStartBlock = ^{
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectDataBeginning object: self.Id userInfo: @{ @"title": title }];
	};
	mmRequest.destinationFilePath = path;
	[[MM_SyncManager sharedManager] queueOperation: mmRequest atFrontOfQueue: YES];

}

- (NSString *) titleForDataField: (NSString *) dataFieldName { 
	NSDictionary					*attrs = self.entity.attributesByName;
	
	if ([attrs objectForKey: @"Name"]) return [self valueForKey: @"Name"]; 
	if ([attrs objectForKey: @"Title"]) return [self valueForKey: @"Title"]; 
	return @"";
}

- (NSString *) pathForDataField: (NSString *) fieldName {
	NSString			*path = [self pathForDataField: fieldName includingSFID: YES];
	NSFileManager		*mgr = [NSFileManager defaultManager];
	
	if (![mgr fileExistsAtPath: path]) {
		NSString				*prevPath = [self pathForDataField: fieldName includingSFID: NO];
		
		if ([mgr fileExistsAtPath: prevPath]) {
			NSError			*error = nil;
			
			[mgr moveItemAtPath: prevPath toPath: path error: &error];
			if (error) MMLog(@"Error while moving from %@ to %@: %@", prevPath, path, error);
		}
	}
	return path;
}

- (NSString *) mimeTypeForDataField: (NSString *) fieldName {
	NSString				*path = [self pathForDataField: fieldName];
    CFStringRef				UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) [path pathExtension], NULL);
    CFStringRef				mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);

    CFRelease(UTI);
    
	if (!mimeType) return @"application/octet-stream";
	
	NSString				*result = [NSString stringWithString: (__bridge NSString *) mimeType];
	
	CFRelease(mimeType);
    return result;
}


- (NSString *) pathForDataField: (NSString *) fieldName includingSFID: (BOOL) includeSFID {
	NSString			*path = [self valueForKey: DATA_PATH_SHADOW(fieldName)];
	
	if (path == nil) {
		NSString			*name = [self titleForDataField: fieldName];
		NSString			*ext = [name pathExtension];
        
        NSString            *title = nil;
        title = [self hasValueForKey: @"Title"] ? self[@"Title"] : @"";

		if (ext.length == 0 || [title numberOfOccurrencesOfString:@"."] != 0) {
			ext = nil;
			if ([self.entity.name isEqual: @"ContentVersion"]) ext = [self[@"PathOnClient"] pathExtension];
		}
		
		name = [name stringByDeletingPathExtension];
		
		//		NSString			*filename = $S(@"%@ [%@|%d].%@", name, self.Id, (NSInteger) self.LastModifiedDate.timeIntervalSinceReferenceDate, ext ?: @"data");
		NSString			*filename = $S(@"%@ [%@].%@", name, self.Id, ext ?: @"data");
		
		if (!includeSFID || self.Id == nil) filename = $S(@"%@ [--].%@", name, ext ?: @"data");
		
		filename = [filename stringByReplacingOccurrencesOfString: @":" withString: @";"];
		filename = [filename stringByReplacingOccurrencesOfString: @"/" withString: @";"];
		
		path = [s_dataBlobDirectoryPath stringByAppendingPathComponent: filename];
		//NSLog(@"Generating path for object %@ [%@]: %@", self.entity.name, self.Id, path);
		return path;
	}
	
	if ([path hasPrefix: @"~"]) return [path stringByExpandingTildeInPath];
	if (![path hasPrefix: @"/"]) return [s_dataBlobDirectoryPath stringByAppendingPathComponent: path];
	
	return path;
}

- (void) forceServerPushForField: (NSString *) field {
	if (self.fieldsToForceToServer == nil)
		self.fieldsToForceToServer = [NSSet setWithObject: field];
	else
		self.fieldsToForceToServer = [self.fieldsToForceToServer setByAddingObject: field];
}

- (void) beginEditing {
	self.editCount++;
	if (self.editCount > 1) return;
	
	self.lastSnapshot = self.snapshot;
}

- (BOOL) isEditing { return self.editCount > 0; }

- (BOOL) finishEditingSavingChanges: (BOOL) saveChanges {
	return [self finishEditingSavingChanges: saveChanges andPushingToServer: YES];
}

- (void) rollbackToSnapshot: (NSDictionary *) snapshot {
	if (snapshot == nil) snapshot = self.lastSnapshot;
	if (snapshot == nil) {
		[self.moc refreshObject: self mergeChanges: NO];
		return;
	}
	NSDictionary						*properties = self.entity.propertiesByName;

	for (NSString *enumeratedKey in properties) {
		NSString		*key = enumeratedKey;
		id				value = [snapshot valueForKey: key];
		NSString		*objectIDKey = FIELD_BY_ADDING_OBJET_SUFFIX(key);
		
		if ([snapshot objectForKey: objectIDKey]) {
			value = [snapshot valueForKey: objectIDKey];
			key = objectIDKey;
		}
		
		
		if (IS_FIELD_SNAPSHOT_OF_OBJECT(key)) {
			if ([value isKindOfClass: [NSSet class]]) {
				NSMutableSet				*records = [self mutableSetValueForKey: FIELD_BY_REMOVING_OBJECT_SUFFIX(key)];
				
				for (NSString *objectID in value) {
					if (![objectID isKindOfClass: [NSString class]]) continue;
					id			newObject = [self.moc objectWithRobustIDString: objectID];
					
					if (newObject) [records addObject: newObject];
				}
			} else {
				[self setValue: [self.moc objectWithRobustIDString: value] forKey: FIELD_BY_REMOVING_OBJECT_SUFFIX(key)];
			}
		} else if ([[properties objectForKey: key] isKindOfClass: [NSAttributeDescription class]] && [[properties objectForKey: key] attributeType] == NSDateAttributeType) {
            if ([value isKindOfClass:[NSDate class]]) {
                [self setValue: value forKey: key];
            } else {
                NSDate				*convertedDate = [NSDate dateWithUNIXString: value];
                if (convertedDate == nil) convertedDate = [NSDate dateWithXMLString: value];
                [self setValue: convertedDate forKey: key];
            }
		} else if ([value isKindOfClass: [NSManagedObject class]]) {
			value = [self.moc objectWithID: [value objectID]];
			[self setValue: value forKey: key]; 
		} else
			[self setValue: value forKey: key]; 
	}
}

- (BOOL) isEmptyObject { return self.snapshot.allKeys.count == 0; }
- (BOOL) existsOnSalesforce { return self.Id.length > 0; }

- (void) finalizeEditingAndPushingToServer: (BOOL) pushNow {
	self.editCount = 1;
	[self finishEditingSavingChanges: YES];
}

- (BOOL) shouldQueueChangeForOriginal: (NSDictionary *) original toNewValues: (NSDictionary *) newValues atDate: (NSDate *) date {
	return YES;
}

- (BOOL) finishEditingSavingChanges: (BOOL) saveChanges andPushingToServer: (BOOL) pushNow {
	NSDate					*queuedAt = [NSDate date];
	
	if (!saveChanges) {
		[self rollbackToSnapshot: nil];
		self.editCount = 0;
		return NO;
	}
	
	if (self.editCount == 0) {
		MMLog(@"Trying to Finish Editing a %@ that Was Not Editing:\n%@", self.entity.name, self);
		IF_SIM([SA_AlertView showAlertWithTitle: $S(@"Trying to Finish Editing a %@ that Was Not Editing", self.entity.name) message: nil]);
		return NO;
	}
	
	self.editCount--;
	if (self.editCount > 0) return NO;			//still editing
	
	NSDictionary				*previousSnapshot = self.lastSnapshot;
	self.lastSnapshot = nil;

	if (self.fieldsToForceToServer.count == 0 && [self.snapshot isEqualToDictionary: previousSnapshot] && ([MM_SFChange doesChangeExistForObject: self] || self.isEmptyObject || self.existsOnSalesforce)) {
		return NO;							//no changes found
	}

	BOOL				saveToDiskFirst = (self.objectID.isTemporaryID || self.isInserted);

	[self save];
//	NSError					*error = nil;
//	[self.moc obtainPermanentIDsForObjects: @[ self ] error: &error];
//	[self Id];
	
	if (saveToDiskFirst && /* DISABLES CODE */ (0)) {			//not yet saved. Let's do that now
		[[MM_ContextManager sharedManager] saveContentContextWithBlock: ^{
			[self refreshFromContextMergingChanges: NO];
			[self saveAndQueueChangesFromOriginal: previousSnapshot pushingToServer: pushNow atTime: queuedAt];
		}];
	} else
		[self saveAndQueueChangesFromOriginal: previousSnapshot pushingToServer: pushNow atTime: queuedAt];
	
	return YES;
}
	
- (void) saveAndQueueChangesFromOriginal: (NSDictionary *) previousSnapshot pushingToServer: (BOOL) pushNow atTime: (NSDate *) date {
	NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadContentContext;
	MMSF_Object					*object = [self objectInContext: moc];
	NSDictionary				*currentSnapshot = object.snapshot;
	NSDictionary				*properties = object.entity.propertiesByName;
	NSMutableDictionary			*newValues = [NSMutableDictionary dictionary];
	id							originalValues = previousSnapshot;
	NSError						*error;
	
	[moc obtainPermanentIDsForObjects: @[ object ] error: &error];

	MMLog(@"Saving %@: %@ / %@", object.entity.name, object.objectID, self.objectID);
	originalValues = [originalValues dictionaryByConvertingIDsToObjectsInContext: moc];
	currentSnapshot = [currentSnapshot dictionaryByConvertingIDsToObjectsInContext: moc];
	
	for (NSString *field in properties) {
		id						originalValue = [originalValues valueForKey: field];
		id						newValue = [currentSnapshot valueForKey: field];
		NSPropertyDescription	*property = [properties objectForKey: field];
		
		
		if (originalValue && [[[property userInfo] objectForKey: NOT_UPDATEABLE_KEY] boolValue]) continue;
		if (originalValue == nil && self.Id == nil && [[[property userInfo] objectForKey: NOT_CREATABLE_KEY] boolValue]) continue;		//can't create the field until the record exists on SFDC
		//if ([field hasSuffix: SNAPSHOT_OBJECT_SUFFIX] || [field hasSuffix: SNAPSHOT_SFID_SUFFIX]) continue;
		if ([field hasSuffix: SNAPSHOT_SFID_SUFFIX]) continue;
		
		if (newValue == nil) {
			if (originalValue != nil) [newValues setValue: [NSNull null] forKey: field];
			continue;
		}
		
		BOOL					forceSave = [self.fieldsToForceToServer containsObject: field];
		
		if ([property isKindOfClass: [NSAttributeDescription class]]) {
			if (![originalValue isEqual: newValue] || forceSave) [newValues setValue: newValue forKey: field];
		} else {
			if ([newValue isKindOfClass: [NSSet class]] || forceSave) {
				[newValues setValue: newValue forKey: field];
			} else {
				NSString			*idString = [newValue robustIDString];
				NSString			*originalIDString = [originalValue isKindOfClass: [NSString class]] ? originalValue : [originalValue robustIDString];
				if (![idString isEqual: originalIDString] || forceSave) 
					[newValues setValue: [moc objectWithRobustIDString: idString] forKey: field];
			}
		}
	}
		
	//newValues = (id) [newValues dictionaryByConvertingObjectsToIDs];
	[[MM_ContextManager sharedManager] saveContentContextWithBlock:^{
		[MM_SFChange queueChangeForObject: object withOriginalValues: originalValues changedValues: newValues atTime: date andPush: pushNow];
	}];
}

- (NSDictionary *) snapshot {
	NSMutableDictionary			*snapshot = [NSMutableDictionary dictionary];
	NSDictionary				*properties = self.entity.propertiesByName;
	NSArray						*ignore = [self.definition fieldListForType: @"ignore"];
	
	if (![ignore respondsToSelector: @selector(containsObject:)]) ignore = nil;
	for (NSString *field in properties) {
		if ([ignore containsObject: field]) continue;
		id					value = [self valueForKey: field];
		
		if ([value isKindOfClass: [NSSet class]]) {
			if ([value count]) [snapshot setValue: [value valueForKey: @"robustIDString"] forKey: FIELD_BY_ADDING_OBJET_SUFFIX(field)];
		} else if ([value isKindOfClass: [NSManagedObject class]]) {
			[snapshot setValue: [value robustIDString] forKey: FIELD_BY_ADDING_OBJET_SUFFIX(field)];
		} else if (value) {
			[snapshot setValue: value forKey: field];
		}
	}
	
	return snapshot;
}

- (MM_SFObjectDefinition *) definition {
	MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: self.entity.name inContext: nil];
	return def;
}

;
- (id) whatIDOfEntityType: (NSString *) type {
	NSString			*whatID = [self primitiveValueForKey: @"WhatId"];
	MMSF_Object			*object = whatID ? [self.moc anyObjectOfType: type matchingPredicate: $P(@"Id = %@", whatID)] : nil;
	
	if (object) return object;
	
	NSString	*objectID = self[@"WhatId_objectid_shadow_mm"];
	object = [self.moc objectWithRobustIDString: objectID];
	
	if ([object.entity.name isEqual: type]) return object;
	
	return nil;
}

- (void) setWhatID: (MMSF_Object *) what {
	[self setPrimitiveValue: what.Id forKey: @"WhatId"];
	self[@"WhatId_objectid_shadow_mm"] = what.robustIDString;
}

//=============================================================================================================================
#pragma mark Server
- (NSString *) salesForceFieldListString {
    //elements like Account.Name can come back in the list, so cannot always use valueForKey
    
    NSMutableArray* names = [NSMutableArray array];
    for (id item in self.definition.queriedFields)
    {
        if ([item isKindOfClass:[NSString class]])
        {
            [names addObject:item];
        }
        else
        {
            [names addObject:[item valueForKey:@"name"]];
        }
    }
    return [names componentsJoinedByString: @","];
}

- (void) reloadFromServer {
	NSString							*fields = self.salesForceFieldListString;
	NSManagedObjectID					*objectID = self.objectID;
	
	@try {
		if (self.Id.length == 0) {
			MMLog(@"Trying to reload an object that hasn't been added to Salesforce yet. %@", @"");
			return;
		}
	} @catch (id e) {
		return;
	}
	
	[[MM_SyncManager sharedManager] queueOperation: [MM_RestOperation operationWithRequest: [[SFRestAPI sharedInstance] requestForRetrieveWithObjectType: [MM_SFObjectDefinition serverObjectNameForLocalName: self.entity.name] objectId: self.Id fieldList: fields] completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		@try {
			NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].threadContentContext;
			MMSF_Object							*obj = [self objectInContext: moc];
			NSError								*idError = nil;
			
			[moc obtainPermanentIDsForObjects: @[ obj ] error: &idError];
			if (obj == nil) {
				MMLog(@"Failed to lookup retrieved object %@", @"");
				return NO;
			}
			[obj importRecord: json includingDataBlobs: YES];
			[obj save];
			[[MM_ContextManager sharedManager] saveContentContextWithBlock: ^{[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectReloaded object: objectID]; }];
		} @catch (NSException *excp) {
			LOG(@"Exception while reloading from server: %@", excp);
		}
		return NO;
	} sourceTag: CURRENT_FILE_TAG] atFrontOfQueue: NO];
}

- (void) didFailToSaveToServerWithError: (NSError *) error {
	
}

- (void) didSaveToServer: (BOOL) isNew {
	if (isNew) {
		NSDictionary						*properties = self.entity.attributesByName;
		for (NSString *key in properties) {
			NSAttributeDescription			*prop = [properties objectForKey: key];
			
			if (prop.attributeType == NSBinaryDataAttributeType) {
				@autoreleasepool {
					NSData				*data = [self valueForKey: key];
					NSError             *error;
					
					if (![data writeToFile: [self pathForDataField: key includingSFID: YES] options: NSDataWritingAtomic error: &error]) {
						MMLog(@"Error while writing %@ to %@: %@", key, self.entity.name, error);
					}
				}
			}
		}

	}
	if (isNew && self.definition.reloadOnObjectCreation && ![MM_SyncManager sharedManager].autorefreshDisabled) {
		[self reloadFromServer];
	}
}

//=============================================================================================================================
#pragma mark Conversion
- (BOOL) hasValueForKeyPath: (NSString *) keyPath {
	NSArray				*components = [keyPath componentsSeparatedByString: @"."];
	
	if (components.count == 1) return [self hasValueForKey: keyPath];
	
	id					parent = self;
	
	for (NSString *key in components) {
		if (![parent hasValueForKey: key]) return NO;
		if ([components indexOfObject: key] == components.count - 1) return YES;
		parent = parent[key];
		if (parent == nil) return YES;
	}
	return YES;
}

- (NSString *) stringForKeyPath: (NSString *) keyPath {
	if ([keyPath isKindOfClass: [NSArray class]]) {
		SA_Assert(NO, @"-stringWithKeyPath: no longer accepts arrays as arguments");
	}
	
	
	id				value;
	
	@try {
		value = [self valueForKeyPath: keyPath];
	} @catch (NSException *exception) {
		MMLog(@"No such value for key path %@ on %@", keyPath, [[self entity] name]);
		return @"";
	}
	
	NSString						*string = value;
	NSAttributeDescription			*attr = [self.entity.attributesByName objectForKey: keyPath];
	
	if (attr) {
		switch (attr.attributeType) {
			case NSInteger16AttributeType:
			case NSInteger32AttributeType:
			case NSInteger64AttributeType:
				return $S(@"%d", [value intValue]);
				
			default:
				break;
		}
	}

	if ([value isKindOfClass: [NSDate class]]) {
		string = [value mediumDateString];
	} else if ([value isKindOfClass: [NSNumber class]]) {
		string = $S(@"%.2f", [value floatValue]);
	} else 
		string = value ? $S(@"%@", value) : @"";

	return string;
}

- (void) setStringValue: (NSString *) value forKey: (NSString *) key {
	NSAttributeDescription			*attr = [self.entity.attributesByName objectForKey: key];
	
	switch (attr.attributeType) {
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
			[self setValue: [NSNumber numberWithInt: [value intValue]] forKey: key];
			break;
			
		case NSFloatAttributeType:
		case NSDoubleAttributeType:
		case NSDecimalAttributeType:
			[self setValue: [NSNumber numberWithFloat: [value floatValue]] forKey: key];
			break;
			
		case NSStringAttributeType:
			[self setValue: value forKey: key];
			break;
			
		case NSBinaryDataAttributeType:
			[self setValue: [NSData dataWithString: value] forKey: key];
			break;
			
		case NSBooleanAttributeType:
			[self setValue: [NSNumber numberWithBool: [value.uppercaseString isEqual: @"YES"] || [value.uppercaseString isEqual: @"TRUE"] || [value.uppercaseString isEqual: @"Y"] || [value isEqual: @"1"]] forKey: key];
			break;
			
		default:
			break;
	}
}
//=============================================================================================================================
#pragma mark Properties
- (NSString *) mmID { return self[MMID_FIELD]; }
- (void) setMmID: (NSString *) mmID { self[MMID_FIELD] = mmID; }
- (NSString *) recordTypeName { return [self valueForKeyPath: @"RecordTypeId.DeveloperName"]; }
- (void) setRecordTypeName: (NSString *) recordTypeName {
	MMSF_Object			*recordType = [self.moc anyObjectOfType: @"RecordType" matchingPredicate: $P(@"DeveloperName == %@", recordTypeName)];
	
	if (recordType != self[@"RecordTypeId"]) self[@"RecordTypeId"] = recordType;
}

- (id) valueForKey: (NSString *) key {
	if (s_disableDynamicRecordLinking == 0)
        {
            if (!self.connectingLinks && [[super valueForKey: MISSING_LINK_ATTRIBUTE_NAME] intValue] == 1 && [self.entity.relationshipsByName objectForKey: key])
            {
                if ([self connectMissingLinksUsingRelationships: nil attributes: nil shadowFieldNames: nil andDataFields: nil withLinkTag: 0]) {
                    TRY([self.moc save];)
                    dispatch_async(dispatch_get_main_queue(), ^{ [[MM_ContextManager sharedManager] saveContentContext]; });
                }
            }
        }

	return [super valueForKey: key];
}

- (void) setParent: (MMSF_Object *) parent {
	[self setValue: parent.Id forKey: @"ParentId"];
	[self setValue: parent.robustIDString forKey: RELATIONSHIP_OBJECTID_SHADOW(@"ParentId")];
}

- (MMSF_Object *) parent {
	NSString			*objectID = [self valueForKey: RELATIONSHIP_OBJECTID_SHADOW(@"ParentId")];
	
	return objectID.length ? [self.moc objectWithRobustIDString: objectID] : nil;
}

- (MMSF_Object *) parentOfType: (NSString *) type {
	MMSF_Object			*parent = self.parent;
	
	if ([parent.entity.name isEqual: type]) return parent;
	
	NSString			*sfID = [self valueForKey: @"ParentId"];
	
	if (sfID.length) return [self.moc anyObjectOfType: type matchingPredicate: $P(@"Id = %@", sfID)];
	return nil;
}

//=============================================================================================================================
#pragma mark Polymorphic relationships
- (NSSet *) attachments {
	if (![NSEntityDescription entityForName: @"Attachment" inManagedObjectContext: self.moc]) return nil;
	
	return [NSSet setWithArray: [self.moc allObjectsOfType: @"Attachment" matchingPredicate: $P(@"ParentId == %@", [self valueForKey: @"Id"])]];
}


- (MMSF_Object *) owner {
	id			owner = [self primitiveValueForKey: @"OwnerId"];
	
	if ([owner isKindOfClass: [NSString class]]) {
		owner = [self.moc anyObjectOfType: @"User" matchingPredicate: $P(@"Id == %@", owner)];
	}
	
	return owner;
}

+ (NSDictionary *) shadowFieldNamesFromRelationships: (NSDictionary *) relationships andAttributes: (NSDictionary *) attributes {
	NSMutableDictionary				*names = [NSMutableDictionary dictionary];
	
	for (NSString *name in relationships) {
		NSString				*shadowName = RELATIONSHIP_SFID_SHADOW(name);
		
		
		if (![attributes objectForKey: shadowName]) continue;
		[names setObject: shadowName forKey: name];
	}
	return names;
}

static SA_ThreadsafeMutableDictionary			*s_sfidCache = nil;
+ (void) clearSFIDCache { s_sfidCache = nil; }
+ (void) logSFIDCache {  }

- (BOOL) connectMissingLinksUsingRelationships: (NSDictionary *) relationships attributes: (NSDictionary *) attributes shadowFieldNames: (NSDictionary *) shadowFieldNames andDataFields: (NSMutableSet *) dataFields withLinkTag: (NSUInteger) tag {
	[MMSF_Object setDynamicRecordLinkingEnabled: NO];

	BOOL				shouldSetLingRequiredTag = (relationships == nil);

	if (relationships == nil) relationships = self.entity.relationshipsByName;
	if (attributes == nil) attributes = self.entity.attributesByName;
	if (shadowFieldNames == nil) shadowFieldNames = [MMSF_Object shadowFieldNamesFromRelationships: relationships andAttributes: attributes];
//	if (dataFields == nil) {	
//		dataFields = [NSMutableSet set];
//		
//		for (NSAttributeDescription *descName in attributes) {
//			if ([[attributes objectForKey: descName] attributeType] == NSBinaryDataAttributeType) {
//				[dataFields addObject: DATA_URL_SHADOW(descName)];
//				[dataFields addObject: DATA_PATH_SHADOW(descName)];
//			}
//		}
//	}
	
	BOOL						foundLink = NO;
	
	self.connectingLinks = YES;
//	for (NSString *name in dataFields) {
//		NSString					*url = [self valueForKey: name];
//		
//		if (url.length) {
//			MMLog(@"Pulling data for %@", url);
//			foundLink = YES;
//		}
//	}
	
	for (NSString *name in shadowFieldNames) {
		NSString					*shadowFieldName = [shadowFieldNames objectForKey: name];//	RELATIONSHIP_SFID_SHADOW(name);
		NSString					*sfid = [self valueForKey: shadowFieldName];
		
		if (sfid == nil) continue;
		
		foundLink = YES;
		if ([sfid isEqual: REMOVE_LINK_NAME]) {			//remove the link
			[self setValue: nil forKey: name];
		} else {
			NSRelationshipDescription	*rel = [relationships objectForKey: name];
			NSString					*reverseType = rel.destinationEntity.name;
			MMSF_Object					*destination = nil;
						
			NSManagedObjectID			*objID = [s_sfidCache objectForKey: sfid];
			if (objID && [self objectIDIsValidForStore: objID]) {
				TRY(destination = (id) [self.moc objectWithID: objID];);
			}
			if (destination == nil) {
				NSFetchRequest				*request = [self.moc fetchRequestWithEntityName: reverseType predicate: $P(@"Id == %@", sfid) sortBy: nil fetchLimit: 1];
				NSError						*fetchError = nil;

				request.resultType = NSManagedObjectIDResultType;
				
				NSArray			*fetchedIDs = [self.moc executeFetchRequest: request error: &fetchError];
				if (fetchedIDs.count) {
					destination = (id) [self.moc objectWithID: fetchedIDs[0]];
					[s_sfidCache setObject: fetchedIDs[0] forKey: sfid];
				}
				
				//destination = [self.moc anyObjectOfType: reverseType matchingPredicate: $P(@"Id == %@", sfid)];
				//if (destination) [s_sfidCache setObject: destination.objectID forKey: sfid];
			}
			
			if (destination) {
				if (rel) {
					if (rel.maxCount == 1) 
						[self setValue: destination forKey: name];
					else {
						[[self mutableSetValueForKey: name] addObject: destination];
					}
				}
				//if ([attributes objectForKey: shadowFieldName]) [self setValue: nil forKey: shadowFieldName];
			} else {
				//MMLog(@"Failed to connect a %@ link from %@ to %@ (%@)", name, object.entity.name, reverseType, sfid);					
			}
		}
	}
	
	self.connectingLinks = NO;
	if (foundLink && shouldSetLingRequiredTag) [self setValue: tag ? @(tag) : self.definition.linkRequiredTag forKey: MISSING_LINK_ATTRIBUTE_NAME];
	[MMSF_Object setDynamicRecordLinkingEnabled: YES];
	return foundLink;
}

- (BOOL) objectIDIsValidForStore: (NSManagedObjectID *) objectID {
	if ([objectID.URIRepresentation.host isEqual: self.objectID.URIRepresentation.host] || objectID.isTemporaryID || self.objectID.isTemporaryID) return YES;
	LOG(@"Bad Object ID found: %@", objectID);
	return NO;
}


- (NSArray *) picklistOptionsForField: (NSString *) fieldName {
	//NSArray					*options = nil;
	
	//if ([self hasAttribute:@"RecordTypeId"]) options = [self.definition picklistOptionsForField: fieldName basedOffRecordType: [self valueForKey: @"RecordTypeId"]];
	
   // if (options) return options;
	return [self.definition picklistOptionsForField: fieldName basedOffRecord: self];
}


- (void) submitData: (NSData *) data ofMimeType: (NSString *) mimeType forField: (NSString *) field {
	MM_RestOperation			*op = [MM_RestOperation postOperationWithSalesforceID: self.Id pushingData: data ofMimeType: mimeType toField: field onObjectType: [MM_SFObjectDefinition serverObjectNameForLocalName: self.entity.name] completionBlock: ^(NSError *error, NSData *results, MM_RestOperation *completedOp) {
		return NO;
	} sourceTag: CURRENT_FILE_TAG];
	
	[[MM_SyncManager sharedManager] queueOperation: op];
}

- (NSString *) labelForField: (NSString *) field {
	return [self.definition labelForField: field];
}


- (UIImage *) imageWithIDInField: (NSString *) fieldName {
	UIImage* img = nil;
    
	NSString			*imageID = self[fieldName];
	
    if (imageID == nil) return nil;
    
	NSPredicate			*predicate = [NSPredicate predicateWithFormat: @"Id BEGINSWITH %@", imageID];
	MMSF_Object			*attach = [self.moc anyObjectOfType:@"Attachment" matchingPredicate: predicate];
	NSString			*path = [attach pathForDataField:@"Body"];
    
    if (attach != nil) img = [UIImage imageWithContentsOfFile: path];
    
    return img;
}

- (UIImage *) attachmentImage {
	return [self attachmentImageNamed: nil];
}

- (UIImage *) attachmentImageNamed: (NSString *) name {
	MMSF_Object			*attach = [self attachmentNamed: name];
	NSString			*path = [attach pathForDataField:@"Body"];
    
    return attach ? [UIImage imageWithContentsOfFile: path] : nil;
}

- (MMSF_Object *) attachmentNamed: (NSString *) name {
	NSPredicate			*predicate;
	
	if (self.Id.length) {
		predicate = [NSPredicate predicateWithFormat: @"ParentId BEGINSWITH %@", self.Id];
	} else {
		NSString				*field = RELATIONSHIP_OBJECTID_SHADOW(@"ParentId");
		NSString				*format = $S(@"%@ BEGINSWITH %%@", field);
		predicate = $P(format, self.robustIDString);
	}
	
	if (name.length) predicate = [NSCompoundPredicate andPredicateWithSubpredicates: @[ predicate, $P(@"Name = %@", name) ]];
	
	MMSF_Object			*attach = [self.moc firstObjectOfType:@"Attachment" matchingPredicate: predicate sortedBy: [NSSortDescriptor SA_arrayWithDescWithKey: @"LastModifiedDate" ascending: NO]];
	return attach;
}

- (MMSF_Object *) setAttachmentImage: (UIImage *) image withAttributes: (NSDictionary *) attr {
	NSData			*data = UIImageJPEGRepresentation(image, 1.0);
	MMSF_Object		*attach = [self.moc insertNewEntityWithName: @"Attachment"];
	
	[attach beginEditing];
	for (NSString *key in attr) {
		attach[key] = attr[key];
	}
	attach[@"ParentId"] = self.Id;
	attach[RELATIONSHIP_OBJECTID_SHADOW(@"ParentId")] = self.robustIDString;
	attach[@"Body"] = data;
	
	attach[@"ContentType"] = @"image/jpg";
	[attach finishEditingSavingChanges: YES];
	return attach;
}



@end


@implementation NSString (MMSF_Object)
- (id) valueForField: (NSString *) field inRecord: (NSManagedObject *) record {
	NSAttributeType				type = [record descriptionForAttribute: field].attributeType;
	id							convertedValue = nil;
	
	switch (type) {
		case NSDateAttributeType:
			convertedValue = [NSDate dateWithUNIXString: self];
			if (convertedValue == nil) convertedValue = [NSDate dateWithXMLString: self];
			break;
			
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
			convertedValue = [NSNumber numberWithInt: [self intValue]];
			break;
			
		case NSFloatAttributeType:
			convertedValue = [NSNumber numberWithFloat: [self floatValue]];
			break;
			
		case NSDoubleAttributeType:
			convertedValue = [NSNumber numberWithDouble: [self doubleValue]];
			break;
			
		case NSBinaryDataAttributeType:
		case NSUndefinedAttributeType:		//relationship
		default:
            convertedValue = nil;
            break;
	}
	return convertedValue;
}

@end

@interface NSSet (objectIDString)

@end

@implementation NSSet (objectIDString)

- (NSString *) objectIDString {
	NSMutableString			*results = [NSMutableString string];
	for (NSString *string in [[[self valueForKey: @"objectIDString"] allObjects] sortedArrayUsingSelector: @selector(compare:)]) {
		[results appendFormat: @"%@", string];
	}
	return results;
}

- (NSString *) robustIDString {
	NSMutableString			*results = [NSMutableString string];
	for (NSString *string in [[[self valueForKey: @"robustIDString"] allObjects] sortedArrayUsingSelector: @selector(compare:)]) {
		[results appendFormat: @"%@", string];
	}
	return results;
}
@end

