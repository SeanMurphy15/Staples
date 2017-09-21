//
//  SA_ConnectionQueue.h
//
//  Created by Ben Gottlieb on 3/29/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SCNetworkReachability.h>

#ifdef LOG_CONNECTION_PROGRESS
	#define					LOG_CONNECTION_START(c)				LOG(@"Starting: <0x%X> %@ (%@)", c, [[[c url] absoluteString] truncateToLength: 40], c.delegate)
	#define					LOG_CONNECTION_PHASE(phase, conn)	LOG(@"%@: <0x%X>", phase, [conn url])
#else
	#define					LOG_CONNECTION_START(c)	
	#define					LOG_CONNECTION_PHASE(phase, conn)
#endif

#if DEBUG
	#define			LOG_CONNECTION(connection)				LOG_DATA(connection.uploadedDataStream, connection.tag) 
	#define			LOG_UPLOAD(connection, name)			[connection.uploadedDataStream writeToFile: [[NSString stringWithFormat: @"~/Library/Downloads/%@ up.txt", name] stringByExpandingTildeInPath] options: 0 error: nil]
	#define			LOG_DOWNLOAD(connection, name)			[connection.downloadedDataStream writeToFile: [[NSString stringWithFormat: @"~/Library/Downloads/%@ down.txt", name] stringByExpandingTildeInPath] options: 0 error: nil]
#else
	#define			LOG_CONNECTION(connection)
	#define			LOG_UPLOAD(connection, name)
	#define			LOG_DOWNLOAD(connection, nam)
#endif

#if !TARGET_OS_IPHONE
	typedef NSUInteger 		UIBackgroundTaskIdentifier;
#endif

#define			HTTP_STATUS_CODE_IS_ERROR(c)				(c >= 400)

#define			kUIBackgroundTaskInvalid				0

@class SA_Connection;

typedef void (^connectionFinished)(SA_Connection *incoming, NSInteger resultCode, id error);

typedef enum {
	connection_dontRecord,				//default behavior
	connection_record,					//record all transactions
	connection_playback,				//playback pre-recorded transactions, fail others
	connection_playbackAndFetch			//playback pre-recorded transactions, run others as normal
} connection_record_setting;


@protocol SA_ConnectionRouter <NSObject>
- (BOOL) shouldProcessSuccessfulConnection: (SA_Connection *) connection;
- (BOOL) shouldProcessFailedConnection: (SA_Connection *) connection;
@end

//use VALIDATE_XML_UPLOADS to turn on XML validation

/***********************************************************************************************************************

 Requires:		SystemConfiguration.framework, libsqlite3 (for Persistance)




***********************************************************************************************************************/

@class SA_Connection;

@protocol SA_ConnectionDelegate <NSObject>
@optional
- (void) connectionWillBegin: (SA_Connection *) connection;
- (void) connectionDidFinish: (SA_Connection *) connection;
- (void) connectionFailed: (SA_Connection *) connection withError: (NSError *) error;
- (BOOL) connectionFailed: (SA_Connection *) connection withStatusCode: (NSInteger) statusCode;			//return YES to continue the connection anyway
- (void) connectionCancelled: (SA_Connection *) connection;
- (NSString *) persistantIdentifier;					//used when persisting

//please wait support
- (NSString *) pleaseWaitMajorStringForConnection: (SA_Connection *) connection;
- (NSString *) pleaseWaitMinorStringForConnection: (SA_Connection *) connection;
- (BOOL) pleaseWaitShowProgressValueForConnection: (SA_Connection *) connection;	
- (float) pleaseWaitProgressValueForConnection: (SA_Connection *) connection;
@end


@interface SA_Connection : NSObject <NSCopying> {
	NSURL						*_url;
	NSData						*_payload;
	NSString					*_method;
	NSMutableData				*_data;
	NSString					*_filename;
	NSFileHandle				*_file;
	NSString					*_tag;
	id <SA_ConnectionDelegate>	_delegate;
	NSInteger 					_priority, _order;
	__strong NSURLConnection	*_connection;
	BOOL						_persists, _canceled, _replaceOlder, _ignoreLater;
	NSMutableDictionary			*_headers;
	NSInteger 					_persistantID;
	NSDictionary				*_responseHeaders;
	NSInteger 					_statusCode;
	BOOL						_showsPleaseWait, _resumable, _completeInBackground, _prefersFileStorage, _suppressConnectionAlerts, _inProgress, _discardIfOffline;
	NSMutableDictionary			*_extraKeyValues;
	BOOL						_allowRepeatedKeys;
	NSURLRequest				*_request;
	
	#if DEBUG
		NSDate					*_requestStartedAt, *_responseReceivedAt, *_finishedLoadingAt;
		NSString				*_requestLogFileName;
	#endif

	connectionFinished		_connectionFinishedBlock;
}

@property (nonatomic, readwrite, strong) NSURL *url;								//the URL to be hit
@property (nonatomic, readwrite, strong) NSData *payload;						//data to be pushed up, usually with a PUT or POST call
@property (nonatomic, readwrite, strong) NSURLRequest *request;					//for pre-configured requests
@property (nonatomic, readonly) NSURLRequest *generatedRequest;					//takes the configured values and returns an NSURLRequest
@property (nonatomic, readwrite, strong) NSData *data;							//the data returned by the server
@property (nonatomic, readonly) NSFileHandle *file;								//if storing in a file, the file
@property (nonatomic, readwrite, strong) NSString *filename;						//if storing in a file, the filenamel this can be set if a known filename is desired
@property (nonatomic, readwrite, strong) NSString *method;						//what HTTP method should be used? Defaults to GET
@property (nonatomic, readwrite, strong) id <SA_ConnectionDelegate> delegate;	//where completed/failed messages are sent
@property (nonatomic, readwrite, strong) NSString *tag;							//a tag, broken down into different.segment.types, for filtering and identification
@property (nonatomic, readwrite) NSInteger priority;									//where in the pending queue should this transaction fall?
@property (nonatomic, readwrite) BOOL persists;									//should this transaction be freeze-dried for later retrieval and restart?  Defaults to YES
@property (readwrite) NSInteger persistantID;
@property (nonatomic, readwrite) NSInteger order;
@property (nonatomic, readonly) NSDictionary *allResponseHeaders;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readwrite) BOOL replaceOlder, ignoreLater;					//should older connections be deleted if they match the tag, or should this be tossed?
@property (nonatomic, readwrite) BOOL showsPleaseWait, resumable, completeInBackground, prefersFileStorage, suppressConnectionAlerts;
@property (nonatomic, readonly) NSData *downloadedData;
@property (nonatomic, readonly) BOOL completed, alreadyStarted, canceled;
@property (nonatomic, readwrite, copy) NSDictionary *submissionParameters;
@property (nonatomic, readonly) BOOL inProgress;
@property (nonatomic, readwrite) BOOL allowRepeatedKeys, discardIfOffline;
@property (nonatomic, readonly) NSString *dataString, *payloadString;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic) BOOL disableNativeCookieHandling;
@property (nonatomic, strong) NSArray *sentCookies, *receivedCookies;

@property (nonatomic, readwrite, copy) connectionFinished connectionFinishedBlock;

#if DEBUG
	@property (nonatomic, readwrite, strong) NSDate *requestStartedAt, *responseReceivedAt, *finishedLoadingAt;
	@property (nonatomic, readwrite, strong) NSString *requestLogFileName;
#endif

@property(nonatomic, readonly) NSData *uploadedDataStream, *downloadedDataStream;

+ (id) connectionWithURL: (NSURL *) url completionBlock: (connectionFinished) completionBlock;
+ (id) connectionWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority completionBlock: (connectionFinished) completionBlock;

+ (id) connectionWithURL: (NSURL *) url tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;
+ (id) connectionWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;
+ (id) connectionWithURLRequest: (NSURLRequest *) request completionBlock: (connectionFinished) completionBlock;

+ (SA_Connection *) downloadURL: (NSURL *) url withCompletionBlock: (connectionFinished) completionBlock;
+ (SA_Connection *) downloadURLRequest: (NSURLRequest *) urlRequest withCompletionBlock: (connectionFinished) completionBlock;

- (id) initWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;

- (void) addHeader: (NSString *) header label: (NSString *) label;
- (void) removeHeader: (NSString *) label;
- (BOOL) start;
- (void) reset;
- (void) cancel: (BOOL) clearDelegate;
- (void) cancelIfNotInProgress: (BOOL) clearDelegate;
- (void) switchToFileStorage;
- (void) setUsername: (NSString *) username password: (NSString *) password;

- (NSString *) responseHeader: (NSString *) key;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) queue;
@end



@interface SA_ConnectionQueue : NSObject <SA_ConnectionRouter> {
	NSMutableArray					*_pending, *_pleaseWaitConnections;
	NSMutableSet					*_active;
	NSMutableDictionary				*_headers;
	
	BOOL							_offline, _showProgressInPleaseWaitDisplay;
	NSUInteger 						_maxSimultaneousConnections;
	NSArray							*_connectionSortDescriptors;
	NSInteger 						_defaultPriorityLevel, _minimumIndicatedPriorityLevel;
	float							_highwaterMark;
	
	void							*_db;
	NSString						*_dbPath;
	
@protected
	BOOL							_wifiAvailable, _wlanAvailable, _managePleaseWaitDisplay;
	NSInteger 								_fileSwitchOverLimit;
	
	BOOL							_dontProcessFailedStatusCodes;

	SA_Connection					*_currentTopPleaseWaitConnection;				//not strong, simply the address of the connection that currently has the please wait 'focus'
	BOOL							_suppressPleaseWaitDisplay;						//if the app wants to show it's own 'please wait', set this to true
	BOOL							_offlineAlertShown, _suppressOfflineAlerts;
	NSInvocation					*_backOnlineInvocation;
	NSInteger						_activityIndicatorCount;
	
	UIBackgroundTaskIdentifier		_backgroundTaskID;
	NSThread						*_backgroundThread;
	SCNetworkReachabilityRef		_reachabilityRef;
	#if DEBUG
		connection_record_setting		_recordSetting;
	#endif
}

@property (readwrite) BOOL offline, showProgressInPleaseWaitDisplay;
@property (readonly) BOOL wifiAvailable, wlanAvailable;
@property (readwrite) NSUInteger maxSimultaneousConnections;
@property (nonatomic, readwrite, strong) NSString *dbPath;				//used for persistance
@property (nonatomic, readwrite) NSInteger defaultPriorityLevel, minimumIndicatedPriorityLevel, fileSwitchOverLimit;
@property (nonatomic, readonly) NSUInteger connectionCount;
@property (nonatomic, readwrite) BOOL dontProcessFailedStatusCodes;
@property (nonatomic, readwrite) BOOL suppressPleaseWaitDisplay;
@property (nonatomic, readonly) BOOL shouldPleaseWaitBeVisible;					//used to check if a pleaseWait SHOLD be shown, regardless of whether _suppressPleaseWaitDisplay is set 
@property (nonatomic, readonly) BOOL connectionsArePending;
@property (nonatomic, readwrite, strong) NSInvocation *backOnlineInvocation;
@property (nonatomic, readwrite, strong) NSThread *backgroundThread;
@property (nonatomic, readwrite) BOOL managePleaseWaitDisplay, suppressOfflineAlerts;
@property (nonatomic, weak) id <SA_ConnectionRouter> router;
@property (atomic, readwrite) NSInteger activityIndicatorCount;
@property (nonatomic, assign) dispatch_queue_t backgroundQueue;
@property (nonatomic) BOOL paused;
@property (nonatomic, readonly) long long bytesDownloaded;

#if DEBUG
	@property (nonatomic, readwrite) connection_record_setting recordSetting;
#endif

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(SA_ConnectionQueue, sharedQueue);

- (BOOL) queueConnection: (SA_Connection *) connection;
- (BOOL) queueConnection: (SA_Connection *) connection andPromptIfOffline: (BOOL) prompt;
- (BOOL) performInvocationIfOffline: (NSInvocation *) invocation;
- (void) processQueue;
- (void) resetOfflineAlerts;
- (void) attempToGoOnline;

- (void) determineConnectionLevelAvailable;
- (void) resetHighwaterMark;								//call this to clear out the 'highwater mark', used when displaying progress

- (void) addHeader: (NSString *) header label: (NSString *) label;
- (void) removeHeader: (NSString *) label;
- (void) removeAllHeaders;
- (BOOL) isExistingConnectionsTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;
- (BOOL) isExistingConnectionSimilar: (SA_Connection *) targetConnection;
- (void) removeConnectionsTaggedWith: (NSString *) tag;
- (void) removeConnectionsWithDelegate: (id) delegate;
- (void) removeConnectionsTaggedWith: (NSString *) tag delegate: (id) delegate;
- (void) cancelAllConnections;
- (SA_Connection *) existingConnectionsTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;

- (void) connectionFailed: (SA_Connection *) connection withError: (NSError *) error;
- (float) remainingConnectionsAboveMinimum;
- (void) dequeueConnection: (SA_Connection *) connection;
- (void) updatePleaseWaitDisplay;
- (void) hideActivityIndicator;

- (void) resetBytesDownloaded;

+ (NSString *) nextPrefixed: (NSString *) prefix pathForTag: (NSString *) tag;
+ (NSString *) logDirectoryPath;
@end

@interface NSError (SA_ConnectionQueue)
- (BOOL) internetConnectionFailed;
@end

extern NSString *kConnectionNotification_Queued;
extern NSString *kConnectionNotification_ConnectionStarted;

extern NSString *kConnectionNotification_Dequeued;
extern NSString *kConnectionNotification_ConnectionFinished, *kConnectionNotification_ConnectionCancelled, *kConnectionNotification_ConnectionFailed;
extern NSString *kConnectionNotification_ConnectionStateChanged;



extern NSString *kConnectionNotification_NotConnectedToInternet, *kConnectionNotification_ConnectionFailedToStart, *kConnectionNotification_ConnectionReturnedBadStatus, *kConnectionNotification_AllConnectionsCompleted;


@interface NSDictionary (SA_Connection)
- (NSData *) postDataByEncoding: (BOOL) encode;
- (NSData *) encodedPostData;
- (NSData *) postData;
+ (NSDictionary *) dictionaryWithPostData: (NSData *) data;
+ (NSDictionary *) dictionaryWithParameterString: (NSString *) string;
@end