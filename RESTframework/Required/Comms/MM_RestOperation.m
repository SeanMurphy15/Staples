//
//  MM_RestOperation.m
//
//  Created by Ben Gottlieb on 11/14/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_RestOperation.h"
#import <SalesforceNativeSDK/SFRestRequest.h>
#import <SalesforceNativeSDK/SFRestAPI.h>
#import "MM_SyncManager.h"
#import "MM_LoginViewController.h"			//for the current creds
#import "MM_SOQLQueryString.h"
#import "MM_SyncManager.h"
#import "MM_ContextManager.h"
#import "NSObject+SBJson.h"
#import "MMSF_Object.h"
#import "MM_SFObjectDefinition.h"
#import "MM_Headers.h"
#import "RKRequest.h"
#import <MKNetworkKit-iOS/MKNetworkOperation.h>


static MM_Rest_Error_Handling			s_errorHandling = MM_Rest_Error_Handling_none;
static BOOL								s_hasShownErrorAlert = NO;
static NSTimeInterval					s_defaultTimeoutInterval = 60.0;
static NSString 						*s_APIVersion = @"32.0";

@interface RKRequestDelegateWrapper : NSObject
+ (id)wrapperWithDelegate:(id<SFRestDelegate>)delegate request:(SFRestRequest *)request;
+ (id)wrapperWithRequest:(SFRestRequest *)request;
- (RKRequest *)send;
@end

@interface MM_RestOperation () <SFRestDelegate>
@end


@interface NSString (MM_RestOperation)
@property (nonatomic, readonly) NSString *stringByConvertingToTemporaryFilePath, *stringByConvertingFromTemporaryFilePath;
@end

@implementation NSString (MM_RestOperation)

#define		TEMP_FILE_PREFIX			@"temp_download_mm_"

- (NSString *) stringByConvertingToTemporaryFilePath {
	NSString				*filename = [self lastPathComponent];
	
	if ([filename hasPrefix: TEMP_FILE_PREFIX]) return self;
	
	NSString				*path = [self stringByDeletingLastPathComponent];

	filename = $S(@"%@%@", TEMP_FILE_PREFIX, filename);
	return [path stringByAppendingPathComponent: filename];
}

- (NSString *) stringByConvertingFromTemporaryFilePath {
	NSString				*filename = [self lastPathComponent];
	
	if (![filename hasPrefix: TEMP_FILE_PREFIX]) return self;
	
	NSString				*path = [self stringByDeletingLastPathComponent];
	
	filename = [filename substringFromIndex: TEMP_FILE_PREFIX.length];
	return [path stringByAppendingPathComponent: filename];
}


@end

@implementation MM_RestOperation
@synthesize completionBlock, request = _request, tag, iWorkAlone, isCleanupOperation, groupTag, oauthRequiredPath, query, fireBlock, destinationFilePath, postPayload, createOrUpdateObjectID, boundaryString;
- (void) dealloc {
	if (self.request.delegate == self) self.request.delegate = nil;
}

+ (NSString *) APIVersion { return s_APIVersion; }
+ (void) setAPIVersion: (NSString *) version { s_APIVersion = version; [SFRestAPI sharedInstance].apiVersion = version; }
+ (void) setDefaultTimeoutInterval: (NSTimeInterval) interval { s_defaultTimeoutInterval = interval; }
+ (void) setErrorHandling: (MM_Rest_Error_Handling) handling {s_errorHandling = handling; }
+ (MM_Rest_Error_Handling) errorHandling { return s_errorHandling; }

+ (void) load {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(syncBegan:) name: kNotification_SyncBegan object: nil];
	}
}

+ (void) syncBegan: (NSNotification *) note {
	s_hasShownErrorAlert = NO;
}

+ (void) queueCountOperationForObjectDefinition: (MM_SFObjectDefinition *) definition {
	MM_SOQLQueryString				*query = [definition baseQueryIncludingData: NO];
//	NSString						*objectName = definition.serverObjectName_mm ?: definition.name;
	
	query.isCountQuery = YES;
	
	MM_RestOperation				*op = [MM_RestOperation operationWithQuery: query groupTag: @"count" completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
		NSUInteger					count = [[json objectForKey: @"totalSize"] integerValue];
		NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadMetaContext;
		MM_SFObjectDefinition		*def = [definition objectInContext: moc];
		

		if (error) [[MM_Log sharedLog] logSyncError: error forQuery: query];
		def.serverObjectCountValue = (UInt32) count;
		[def save];
		return NO;
	} sourceTag: CURRENT_FILE_TAG];
	
	[[MM_SyncManager sharedManager] queueOperation: op];
}

+ (void) queueSyncOperationsForObjectDefintion: (MM_SFObjectDefinition *) definition {
	definition = [definition objectInContext: [MM_ContextManager sharedManager].threadMetaContext];

	if (!definition.shouldSyncServerData) return;

	[[MM_SyncManager sharedManager] queuePendingDefinitionSync: definition];
}

+ (MM_RestOperation *) operationWithBlock: (simpleBlock) block sourceTag: (NSString *) sourceTag {
	MM_RestOperation			*op = [[self alloc] init];
	
	op.sourceTag = sourceTag;
	op.fireBlock = block;
	return op;
}

+ (MM_RestOperation *) operationWithQuery: (MM_SOQLQueryString *) query groupTag: (id) groupTag completionBlock: (restArgumentBlock) block sourceTag: (NSString *) sourceTag {
	MM_RestOperation			*op = [[self alloc] init];

	op.completionBlock = block;
	op.query = query;
	op.sourceTag = sourceTag;
	return op;
}

+ (MM_RestOperation *) operationWithRequest: (SFRestRequest *) request completionBlock: (restArgumentBlock) block sourceTag: (NSString *) tag {
	return [self operationWithRequest: request groupTag: nil completionBlock: block sourceTag: tag];
}

+ (MM_RestOperation *) operationWithRequest: (SFRestRequest *) request groupTag: (id) groupTag completionBlock: (restArgumentBlock) block sourceTag: (NSString *) tag {
	MM_RestOperation			*op = [[MM_RestOperation alloc] init];
	
	op.request = request;
	op.completionBlock = block;
	op.sourceTag = tag;
	return op;
}

+ (MM_RestOperation *) dataOperationWithOAuthPath: (NSString *) path completionBlock: (dataArgumentBlock) block sourceTag: (NSString *) sourceTag {
	MM_RestOperation			*op = [[MM_RestOperation alloc] init];
	
	op.oauthRequiredPath = path;
	op.completionBlock = block;
	op.sourceTag = sourceTag;
	return op;
}

+ (MM_RestOperation *) operationToCreateObject: (MMSF_Object *) object completionBlock: (dataArgumentBlock) block sourceTag: (NSString *) sourceTag {
	MM_RestOperation			*op = [[MM_RestOperation alloc] init];
	NSMutableData				*payload = [NSMutableData data];
	NSString					*boundaryString = @"--boundary";
	NSData						*lineBreak = [NSData dataWithString: @"\r\n"];
	NSMutableDictionary			*fields = [object snapshot].mutableCopy;
	NSMutableDictionary			*dataBlobs = [NSMutableDictionary dictionary];
	
	for (NSString *key in fields.allKeys) {
		id			data = [fields objectForKey: key];
		
		if ([data isKindOfClass: [NSData class]]) {
			[dataBlobs setObject: data forKey: key];
			[fields removeObjectForKey: key];
		}
	}
	
	[payload appendData: [NSData dataWithString: boundaryString]]; 	[payload appendData: lineBreak];
	
	[payload appendData: [NSData dataWithString: @"Content-Disposition: form-data; name=\"entity_content\";"]];	[payload appendData: lineBreak];
	[payload appendData: [NSData dataWithString: @"Content-Type: application/json;"]];	[payload appendData: lineBreak];	[payload appendData: lineBreak];
	//[payload appendData: [NSData dataWithString: @"{"]];	[payload appendData: lineBreak];
	[payload appendData: [NSData dataWithString: [fields JSONRepresentation]]];	[payload appendData: lineBreak];
//	for (NSString *key in fields.allKeys) {
//		id					value = [fields objectForKey: key];
//		NSString			*jsonValue = nil;
//		
//		if ([value isKindOfClass: [NSNumber class]] || [value isKindOfClass: [NSString class]]) {
//			jsonValue = $S(@"%@", value);
//		} else if ([value isKindOfClass: [NSArray class]] || [value isKindOfClass: [NSDictionary class]]) {
//			jsonValue = [value JSONRepresentation];
//		} else {
//			MMLog(@"Unable to generate JSON for %@: %@", [value class], value);
//		}
//
//		if (jsonValue) { 
//			[payload appendData: [NSData dataWithString: $S(@"\"%@\": %@", key, jsonValue)]];[payload appendData: lineBreak];
//		}
//	}
	
	//[payload appendData: [NSData dataWithString: @"}"]];	[payload appendData: lineBreak];
	[payload appendData: [NSData dataWithString: boundaryString]]; 	[payload appendData: lineBreak];
	
	if (dataBlobs.count) {
		for (NSString *key in dataBlobs.allKeys) {
			NSData				*data = [dataBlobs valueForKey: key];
			NSString			*mimeType = @"data/data";
			
			[payload appendData: lineBreak];
			[payload appendData: [NSData dataWithString: $S(@"Content-Type: %@;", mimeType)]];	[payload appendData: lineBreak];
			[payload appendData: [NSData dataWithString: $S(@"Content-Disposition: form-data; name=\"%@\"; filename=\"testfile.dat\";", key)]];	[payload appendData: lineBreak];	[payload appendData: lineBreak];
			[payload appendData: data]; 	[payload appendData: lineBreak];
			[payload appendData: [NSData dataWithString: boundaryString]];
		}
	}
	
	[payload appendData: [NSData dataWithString: @"--"]];
	//[payload appendData: lineBreak];
	op.boundaryString = boundaryString;
	op.sourceTag = sourceTag;
	op.oauthRequiredPath = $S(@"/services/data/%@/sobjects/%@/", [MM_RestOperation APIVersion], [MM_SFObjectDefinition serverObjectNameForLocalName: object.entity.name]);
	op.postPayload = payload;
	return op;
}

+ (MM_RestOperation *) postOperationWithSalesforceID: (NSString *) sfid pushingData: (NSData *) data ofMimeType: (NSString *) mimeType toField: (NSString *) field onObjectType: (NSString *) entityName completionBlock: (dataArgumentBlock) block sourceTag: (NSString *) sourceTag{
	//referencing http://www.salesforce.com/us/developer/docs/api_rest/Content/dome_sobject_insert_update_blob.htm
	//curl https://instance name.salesforce.com/services/data/v23.0/sobjects/Document/015D0000000N3ZZIA0  -H "Authorization: Bearer token" -H "X-PrettyPrint:1" -H "Content-Type: multipart/form-data; boundary=\"boundary_string\"" --data-binary @UpdateDocument.json -X PATCH

	MM_RestOperation			*op = [[MM_RestOperation alloc] init];
	NSMutableData				*payload = [NSMutableData data];
	NSString					*boundaryString = @"--boundary--";
	NSData						*lineBreak = [NSData dataWithString: @"\r\n"];

	
	[payload appendData: [NSData dataWithString: boundaryString]]; 	[payload appendData: lineBreak];
	
//	[payload appendData: [NSData dataWithString: @"Content-Disposition: form-data; name=\"entity_content\";"]];	[payload appendData: lineBreak];
//	[payload appendData: [NSData dataWithString: @"Content-Type: application/json"]];	[payload appendData: lineBreak];
//	[payload appendData: [NSData dataWithString: @"{"]];	[payload appendData: lineBreak];

	[payload appendData: [NSData dataWithString: $S(@"Content-Type: %@", mimeType)]];	[payload appendData: lineBreak];
	[payload appendData: [NSData dataWithString: $S(@"Content-Disposition: form-data; name=\"%@\"; filename=\"testfile.dat\";", field)]];	[payload appendData: lineBreak];
	[payload appendData: data]; 	[payload appendData: lineBreak];
	[payload appendData: [NSData dataWithString: boundaryString]]; 	[payload appendData: lineBreak]; 	[payload appendData: lineBreak];
	
	op.boundaryString = boundaryString;
	op.sourceTag = sourceTag;
	op.oauthRequiredPath = $S(@"/services/data/%@/sobjects/%@/%@", [MM_RestOperation APIVersion], entityName, sfid);
	op.postPayload = payload;
	return op;
}

//=============================================================================================================================
#pragma mark comms
- (NSString *) description {
	if (self.postPayload) return $S(@"%@ MM_RestOp (POST): %@", self.sourceTag, self.postPayload.stringValue);
	if (self.oauthRequiredPath) return $S(@"%@ MM_RestOp (OAuth): %@", self.sourceTag, self.oauthRequiredPath);
	if (self.request) {
		NSString			*desc = self.request.description;
		
		return $S(@"MM_RestOp (Request): %@", [desc substringToIndex: MIN(250, desc.length)]);
	}
	if (self.query) {
		if (self.query.moreURLString) return $S(@"More %@: %@", self.query.objectName, self.query.moreURLString);
		return $S(@"MM_RestOp (Query): %@", self.query);
	}
	if (self.completionBlock) return $S(@"%@ MM_RestOp (Completion Block)", self.sourceTag);
	if (self.fireBlock) return $S(@"%@ MM_RestOp (Fire Block)", self.sourceTag);
	return [super description];
}

- (void) dequeue {
	[[MM_SyncManager sharedManager] dequeueOperation: self completed: YES];
}

- (void) start {
	if (self.requeueCount) {
		LOG(@"Requeuing Request (#%d): %@", (UInt16) self.requeueCount + 1, self);
	}
	if (self.isRunning) return;
	self.isRunning = YES;

	if (self.query.objectName) {
		[[MM_SyncStatus status] markObjectNameStarted: self.query.objectName];
		if (![[MM_SyncManager sharedManager].currentObjectName isEqual: self.query.objectName]) {
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_ObjectSyncBegan object: self.query.objectName];
		}
		
		MMLog(@"%@ %@ Sync for %@", self.query.isContinuationQuery ? @"Continuing" : @"Starting", self.query.shouldSearchForExistingRecordsWhenImporting ? (self.query.isIDOnlyQuery ? @"ID" : @"Full") : @"Delta", self.query.objectName);
	}

	if (self.willStartBlock) self.willStartBlock();
	if (self.isTestOnlyOperation) {
		
	} else if (self.postPayload) {
		if ([SA_ConnectionQueue sharedQueue].offline) return;
		
		NSURL				*url = $U(@"%@%@", [SFOAuthCoordinator currentInstanceURL].absoluteString, self.oauthRequiredPath);
		SA_Connection		*connection = [SA_Connection connectionWithURL: url completionBlock: ^(SA_Connection *incoming, NSInteger resultCode, id error) {
			if (error) [[MM_Log sharedLog] logPOSTError: error onURL: url];
			[self dequeue];
		}];
		
		connection.method = @"POST";
		connection.payload = self.postPayload;
		[connection addHeader: $S(@"OAuth %@", [SFOAuthCoordinator currentAccessToken]) label: @"Authorization"];
		[connection addHeader: $S(@"multipart/form-data; boundary=\"%@\"", self.boundaryString) label: @"Content-Type"];
		
		[[SA_ConnectionQueue sharedQueue] queueConnection: connection];
	} else if (self.oauthRequiredPath) {
		if ([SA_ConnectionQueue sharedQueue].offline) return;
		NSURL				*url = $U(@"%@%@", [SFOAuthCoordinator currentInstanceURL].absoluteString, self.oauthRequiredPath);
		NSString			*tempFilePath = self.destinationFilePath.stringByConvertingToTemporaryFilePath;
		
		SA_Connection		*connection = [SA_Connection connectionWithURL: url completionBlock: ^(SA_Connection *incoming, NSInteger resultCode, id error) {
			if (error) TRY(MMLog(@"Error while trying to submit to an OAuth path: %@ (%@, %@)", self.oauthRequiredPath, [error localizedDescription], [error userInfo]));
			
			if (resultCode == 401) {
				error = [NSError errorWithDomain: @"credentials" code: 401 userInfo: nil];			//expired token
				[MM_LoginViewController handleFailedOAuth];
			} else if (error == nil && tempFilePath && ![self.destinationFilePath isEqual: tempFilePath]) {
				NSError				*moveError = nil;
				if (![[NSFileManager defaultManager] moveItemAtPath: tempFilePath toPath: self.destinationFilePath error: &moveError]) {
					MMLog(@"Unable to move file from %@ to %@ (%@)", tempFilePath, self.destinationFilePath, moveError);
				}
			}

			dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
				if (!self.completionBlock(error, incoming.data, self)) [self dequeue];
			});
		}];
		
		if (self.destinationFilePath) connection.filename = tempFilePath;
		[connection addHeader: $S(@"OAuth %@", [SFOAuthCoordinator currentAccessToken]) label: @"Authorization"];
		
		[[SA_ConnectionQueue sharedQueue] queueConnection: connection];
	} else if (self.request) {
		if ([SA_ConnectionQueue sharedQueue].offline) return;
		[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
		[[SFRestAPI sharedInstance] send: self.request delegate: self];
    } else if (self.query) {
		if ([SA_ConnectionQueue sharedQueue].offline) return;
		
		if (query.moreURLString) {
			NSString							*moreURL = [query.moreURLString stringByReplacingOccurrencesOfString: @"/services/data" withString: @""];
			
			self.request = [SFRestRequest requestWithMethod: SFRestMethodGET path: moreURL queryParams: nil];
		} else {
			self.request = [[SFRestAPI sharedInstance] requestForQuery: query.queryString];
            MMLog(@"Running query on %@: ", query.objectName);
			MMVerboseLog(@"\n%@\n\n", query.description);
		}
		[[SFRestAPI sharedInstance] send: self.request delegate: self];
	} else if (self.completionBlock) { 
		[SA_ConnectionQueue sharedQueue].activityIndicatorCount++;
		dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
			if (!self.completionBlock(nil, nil, self)) [self dequeue];
			dispatch_async(dispatch_get_main_queue(), ^{ [SA_ConnectionQueue sharedQueue].activityIndicatorCount--;});
		});
	} else if (self.fireBlock) {
		self.fireBlock();
		[self dequeue];
	}
}
 
- (void) pause {
	self.isRunning = NO;
}

#pragma mark - callbacks

- (void) request: (SFRestRequest *) request didLoadResponse: (id) jsonResponse {
	dispatch_async([MM_SyncManager sharedManager].parseDispatchQueue, ^{
		[self completeWithResponse: request.networkOperation.internalOperation.response andJSON: jsonResponse];
	});
}

- (void) completeWithResponse: (SFNetworkOperation *) response andJSON: (id) jsonResponse {
	self.isRunning = NO;
	self.completed = YES;
	self.sfdcHeaderDate = [NSDate dateWithHTTPHeaderString: response.allHeaderFields[@"Date"]];
	if (!self.completionBlock || !self.completionBlock(nil, jsonResponse, self)) [self dequeue];
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
}

- (void) request: (SFRestRequest *) request didFailLoadWithError: (NSError *) error {
	__strong MM_RestOperation				*op = self;
	op.isRunning = NO;
	
	BOOL				shouldDequeue = NO;
	
	if (error) [[MM_Log sharedLog] logSyncError: error forQuery: self.query];
	
	if (op.isSniffingRequest) {
		shouldDequeue = (!op.completionBlock || !op.completionBlock(error, nil, op));
	} else if (op.completionBlock) {
		shouldDequeue = (!op.completionBlock(error, nil, op));
	} else {
		[SA_AlertView showAlertWithTitle: request.path error: error];

		shouldDequeue = YES;
	}
	
	if (error && !op.isSniffingRequest) {
		if (self.query.isSyncOperation) [[MM_SyncManager sharedManager] receivedError: error forQuery: self.query];
		shouldDequeue = YES;
		NSString			*title, *message = @"";
		
		switch (s_errorHandling) {
			case MM_Rest_Error_Handling_none:
				break;
				
			case MM_Rest_Error_Handling_alertOnFirst:
				if (s_hasShownErrorAlert) break;
				s_hasShownErrorAlert = YES;
			case MM_Rest_Error_Handling_alertOnAll:
				title = $S(NSLocalizedString(@"Error while Syncing %@", nil), op.objectName ?: @"");
				message = error.userInfo[@"message"] ? $S(@"%@\n\n%@", error.userInfo[@"message"], op.description) : op.description;
				
				[SA_AlertView showAlertWithTitle: title message: message buttons: @[NSLocalizedString(@"OK", @"OK"), NSLocalizedString(@"Submit Feedback", @"Submit Feedback")] buttonBlock: ^(NSInteger buttonIndex) {
					if (buttonIndex != 0) {
						UIViewController					*root = [[UIApplication sharedApplication].windows[0] rootViewController];
						MFMailComposeViewController			*controller = [[MFMailComposeViewController alloc] init];
						__weak MFMailComposeViewController	*weakController = controller;
						
						[controller setMessageBody: message isHTML: NO];
						[controller addAttachmentData: [MM_Log sharedLog].dataForMailing mimeType: @"text/text" fileName: @"log.txt"];
						[[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_auth_server_error];
						
						controller.SA_CompletionBlock = ^(MFMailComposeResult result) {
							[weakController dismissViewControllerAnimated: YES completion: nil];
						};
						[root presentViewController: controller animated: YES completion: nil];
					}
				}];
				break;
		}
		MMLog(@"----------------------------------------------------- Error while syncing -----------------------------------------------------\n %@", error);
		if (error.code == 999 && [error.domain isEqual: @"com.salesforce.OAuth.ErrorDomain"]) {
			[MM_LoginViewController handleFailedOAuth];
		} else if (error.code == -1001 && [error.domain isEqual: @"NSURLErrorDomain"]) {
			[op requestDidTimeout: request];
		} else if (error.code == kCFURLErrorNotConnectedToInternet && [error.domain isEqual: @"NSURLErrorDomain"]) {
			[SA_ConnectionQueue sharedQueue].offline = YES;
		}
	}

	if (shouldDequeue) [op dequeue];
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
}

- (void) requestDidCancelLoad:(SFRestRequest *) request {
	self.isRunning = NO;
	[[MM_SyncManager sharedManager] dequeueOperation: self completed: NO];
	[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
}

- (void) requestDidTimeout: (SFRestRequest *) request {
	self.isRunning = NO;
	self.completed = NO;
	[[MM_SyncManager sharedManager] dequeueOperation: self completed: NO];
	//[SA_ConnectionQueue sharedQueue].activityIndicatorCount--;
	self.requeueCount++;
	[[MM_SyncManager sharedManager] queueOperation: self];
}

@end
