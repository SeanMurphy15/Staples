//
//  MM_RestOperation.h
//
//  Created by Ben Gottlieb on 11/14/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "SFRestRequest.h"
//#import "SFRestAPI.h"

@class MM_SOQLQueryString, MM_SFObjectDefinition, MMSF_Object, MM_RestOperation, SFRestRequest;

typedef NS_ENUM(UInt8, MM_Rest_Error_Handling) {
	MM_Rest_Error_Handling_none,
	MM_Rest_Error_Handling_alertOnFirst,
	MM_Rest_Error_Handling_alertOnAll
};

typedef BOOL (^restArgumentBlock)(NSError *error, id jsonResponse, MM_RestOperation *completedOp);
typedef BOOL (^dataArgumentBlock)(NSError *error, NSData *results, MM_RestOperation *completedOp);

@interface MM_RestOperation : NSObject

@property (nonatomic, copy) restArgumentBlock completionBlock;
@property (nonatomic, strong) SFRestRequest *request;
@property (nonatomic, strong) NSString *tag, *groupTag;					//two items with the same groupTag will not run simultaneously
@property (nonatomic) BOOL iWorkAlone, isRunning, completed;			//if set, this connection will run all by itself
@property (nonatomic) BOOL isCleanupOperation;							//if set, this connection is intended to run after all the others
@property (nonatomic, strong) NSString *oauthRequiredPath;				//a path to a server resource that will require OAuth creds
@property (nonatomic, strong) MM_SOQLQueryString *query;
@property (nonatomic, copy) simpleBlock fireBlock;
@property (nonatomic, copy) NSString *destinationFilePath, *createOrUpdateObjectID, *boundaryString, *objectName;
@property (nonatomic, retain) NSData *postPayload;
@property (nonatomic) BOOL isSniffingRequest;							//checking to see if our OAuth creds are valid
@property (nonatomic, copy) simpleBlock willStartBlock;
@property (nonatomic) NSInteger requeueCount;
@property (nonatomic, strong) NSString *sourceTag;

+ (void) setDefaultTimeoutInterval: (NSTimeInterval) interval;
+ (void) setErrorHandling: (MM_Rest_Error_Handling) handling;
+ (MM_Rest_Error_Handling) errorHandling;
+ (NSString *) APIVersion;
+ (void) setAPIVersion: (NSString *) version;

+ (void) queueCountOperationForObjectDefinition: (MM_SFObjectDefinition *) definition;
+ (void) queueSyncOperationsForObjectDefintion: (MM_SFObjectDefinition *) definition;

+ (MM_RestOperation *) operationWithBlock: (simpleBlock) block sourceTag: (NSString *) sourceTag;
+ (MM_RestOperation *) operationWithRequest: (SFRestRequest *) request completionBlock: (restArgumentBlock) block sourceTag: (NSString *) sourceTag;
+ (MM_RestOperation *) operationWithRequest: (SFRestRequest *) request groupTag: (id) groupTag completionBlock: (restArgumentBlock) block sourceTag: (NSString *) sourceTag;
+ (MM_RestOperation *) operationWithQuery: (MM_SOQLQueryString *) query groupTag: (id) groupTag completionBlock: (restArgumentBlock) block sourceTag: (NSString *) sourceTag;
+ (MM_RestOperation *) dataOperationWithOAuthPath: (NSString *) path completionBlock: (dataArgumentBlock) block sourceTag: (NSString *) sourceTag;
+ (MM_RestOperation *) postOperationWithSalesforceID: (NSString *) sfid pushingData: (NSData *) data ofMimeType: (NSString *) mimeType toField: (NSString *) field onObjectType: (NSString *) entityName completionBlock: (dataArgumentBlock) block sourceTag: (NSString *) sourceTag;
+ (MM_RestOperation *) operationToCreateObject: (MMSF_Object *) object completionBlock: (dataArgumentBlock) block sourceTag: (NSString *) sourceTag;
- (void) start;
- (void) pause;
- (void) completeWithResponse: (id) jsonResponse;
- (void) dequeue;
- (void) request: (SFRestRequest *) request didFailLoadWithError: (NSError *) error;

@end
