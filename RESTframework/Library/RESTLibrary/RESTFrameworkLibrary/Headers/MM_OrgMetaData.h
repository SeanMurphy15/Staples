//
//  MM_OrgMetaData.h
//  SFRestTesting
//
//  Created by Ben Gottlieb on 11/18/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//



@interface MM_OrgMetaData : NSObject {
	NSArray				*_objectsToSync;
}
SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(MM_OrgMetaData, sharedMetaData);

@property (nonatomic, strong) NSArray *objectsToSync;
@property (nonatomic, readonly) BOOL areAllObjectsToSyncPresent;
@property (nonatomic, readonly) NSString *editedSyncObjectsPath;

- (NSArray *) objectsToSync;			//returns an array of dictionaries
- (void) addObjectToSyncList: (NSString *) objectName;
- (void) setAllObjectsToSync: (NSArray *) objects;			//takes an array of dictionaries or strings
- (BOOL) isObjectSynced: (NSString *) objectName;
- (NSDictionary *) syncObjectNamed: (NSString *) name;
- (void) setSyncObjectInfo: (NSDictionary *) info;
@end
