//
//  MM_ContextManager.h
//
//  Created by Ben Gottlieb on 11/13/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**************************************************
 *
 *	The Context Manager object is a singleton used to create new contexts for importing, editing, and viewing
 *
 *	When a importing, create a new contextForWriting, and save changes to it. When complete, push those changes
 *	up the chain by saving. Finally, save the main context to write them to 'disk'
 *
 **************************************************/

@interface MM_ManagedObjectContext : NSManagedObjectContext
@property (nonatomic, strong) NSThread *sourceThread;
@property (nonatomic) BOOL usesMMIDs;
@property (nonatomic) NSUInteger contextSetupTag;
@end

@interface MM_ContextManager : NSObject

@property (nonatomic, strong, readonly) MM_ManagedObjectContext *mainMetaContext, *mainContentContext, *threadMetaContext, *threadContentContext, *contentContextForReading;
@property (nonatomic, strong) NSString *metaContextPath, *contentContextPath;
@property (nonatomic, readonly) dispatch_queue_t importDispatchQueue;
@property (nonatomic, strong) NSManagedObjectModel *contentModel;
@property (nonatomic, strong) NSManagedObjectModel *metaContextModel;
@property (nonatomic, readonly) NSString *contentModelPath;
@property (nonatomic) NSUInteger contextSetupTag;
@property (nonatomic, strong) NSLock *saveLock;
@property (atomic, readonly) BOOL deletingAllData;

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(MM_ContextManager, sharedManager);

+ (void) setDataStoreRoot:(NSURL*) rootURL;
+ (void) setMetadataModelRoot:(NSURL*) rootURL;
+ (void) setContentModelRoot:(NSURL*) rootURL;

+ (void) setMetadataFilename:(NSString*) filename;
+ (void) setContentFilename:(NSString*) filename;
+ (void) setContentModelFilename:(NSString*) filename;

+ (void) setStoreFileProtection: (NSString *) protection;
+ (void) saveMetaContext;
+ (void) saveContentContext;
+ (void) setDataModelVersion: (NSUInteger) version;

- (void) removeAllDataIncludingMetaData: (BOOL) includeMetadata withDelay: (NSTimeInterval) delay;

- (void) saveMetaContext;
- (void) saveContentContext;
- (void) saveMetaContextWithBlock: (simpleBlock) block;
- (void) saveContentContextWithBlock: (simpleBlock) block;
- (void) saveAndClearContentContext;

- (NSManagedObjectContext *) metaContextForWriting;
- (NSManagedObjectContext *) contentContextForWriting;
- (void) resetContentContext;
- (BOOL) objectExistsInContentModel: (NSString *) objectName;

- (BOOL) missingLinksAreConnectedForObjectNamed: (NSString *) object;
- (void) setMissingLinksAreConnected: (BOOL) exist forObjectNamed: (NSString *) objectName;
- (void) pushAllPendingChangesAndRemoveAllData;

- (id) objectInNewContext: (NSManagedObject *) object;

typedef NS_ENUM(UInt8, mm_model_validation_result) {
	mm_model_validation_result_missing,
	mm_model_validation_result_failedMissingEntity,
	mm_model_validation_result_failedMissingField,
	mm_model_validation_result_valid,
};
+ (mm_model_validation_result) validateCurrentModelReturningInfo: (NSMutableDictionary *) invalidObjectsAndFieldsInfo;		//pass an already created mutable dictionary to retreive info on any missing objects and fields
@end
