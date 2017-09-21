//
//  MM_Log.h
//
//  Created by Ben Gottlieb on 11/25/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@class MM_SFChange, MMSF_Object;

typedef NS_ENUM(uint8_t, MM_LOG_LEVEL) {
	MM_LOG_LEVEL_VERBOSE,
	MM_LOG_LEVEL_LOW,
	MM_LOG_LEVEL_HIGH,
	MM_LOG_LEVEL_CRITICAL
};

typedef NSString * (^stringGenBlock)();

#define			MMLog(fmt, ...)			[[MM_Log sharedLog] logLevel: MM_LOG_LEVEL_LOW string: fmt, __VA_ARGS__]
#define			MMVerboseLog(fmt, ...)	[[MM_Log sharedLog] logLevel: MM_LOG_LEVEL_VERBOSE string: fmt, __VA_ARGS__]

@interface MM_Log : NSObject <MFMailComposeViewControllerDelegate>

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(MM_Log, sharedLog);

@property (nonatomic, readwrite, strong) NSString *logFilePath;
@property (nonatomic, readonly) NSArray *recentErrors;
@property (nonatomic, assign) BOOL enabled, logToConsoleToo;
@property (nonatomic) MM_LOG_LEVEL currentLogLevel;
@property (nonatomic, assign) BOOL logToCrashlytics;

@property (nonatomic, readonly) NSData *dataForMailing;

+ (BOOL) zombieEnabled;

- (void) clearRecentErrors;

- (void) logMetadataError: (NSError *) error forObjectNamed: (NSString *) name;
- (void) logSyncError: (NSError *) error forObjectNamed: (NSString *) name;
- (void) logUploadError: (NSError *) error forChange: (MM_SFChange *) change;
- (void) logBlobDownloadError: (NSError *) error forField: (NSString *) field onObjectID: (NSManagedObjectID *) objectID;
- (void) logPOSTError: (NSError *) error onURL: (NSURL *) url;
- (void) logFields: (NSDictionary *) fields savedForObjectName: (NSString *) objectName;

- (void) logString: (NSString *) message;

- (void) clearLog;
- (void) emailLogFromViewController: (UIViewController *) controller;

- (void) logLevel: (MM_LOG_LEVEL) level string: (NSString *) format, ...;
- (void) logLevel: (MM_LOG_LEVEL) level stringGen: (stringGenBlock) block;
@end
