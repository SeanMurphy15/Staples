//
//  MM_Log.m
//
//  Created by Ben Gottlieb on 11/25/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_Log.h"
#import "MM_Constants.h"
#import "MM_SFChange.h"
#import "MM_SyncManager.h"
#import "MM_SOQLQueryString.h"

__attribute__((weak)) extern void CLSLog(NSString *format, ...);

@interface MM_Log ()
@property (nonatomic) FILE *logFile;
@property (nonatomic, readwrite, strong) NSMutableArray *allRecentErrors;
@end

@implementation MM_Log

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(MM_Log, sharedLog);

#pragma mark - Setup

- (id) init {
	if ((self = [super init])) {
		self.logFilePath = [[NSUserDefaults standardUserDefaults] stringForKey: DEFAULTS_LAST_LOG_PATH];
		self.logToConsoleToo = YES;
        self.logToCrashlytics = YES;
		if (self.logFilePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath: self.logFilePath]) {
			NSURL				*path = [NSFileManager libraryDirectory];
		
			self.logFilePath = [path.path stringByAppendingPathComponent: @"mm_log.txt"]; 
            self.enabled = YES;
		}
		self.allRecentErrors = [NSMutableArray array];
		
		self.currentLogLevel = MM_LOG_LEVEL_HIGH;
	}
	
	return self;
}

- (NSData *) dataForMailing {
	NSError					*error;
	NSData					*data = [NSData dataWithContentsOfFile: self.logFilePath options: NSDataReadingMappedIfSafe error: &error];
	
	if (error) NSLog(@"[ERROR] while building file for emailing: %@", error);
	return data;
}

+ (BOOL) zombieEnabled {
	return getenv("NSZombieEnabled") != nil;
}

- (void) logSyncError: (NSError *) error forObjectNamed: (NSString *) name {
	if ([error.userInfo[@"errorCode"] isEqual: @"API_CURRENTLY_DISABLED"]) {
		[SA_AlertView showAlertWithTitle: NSLocalizedString(@"API Disabled for Current User", nil) message: NSLocalizedString(@"Please contact your system administrator.", nil)];
		[[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_api_disabled];
		return;
	}
	[self.allRecentErrors addObject: error];
	[self logString: $S(@"[ERROR] in Sync for %@ (%@)\n%@\n", name, [error.userInfo objectForKey: @"errorCode"], [error.userInfo objectForKey: @"message"])];
}

- (void) logSyncError: (NSError *) error forQuery: (MM_SOQLQueryString *) query {
	if ([error.userInfo[@"errorCode"] isEqual: @"API_CURRENTLY_DISABLED"]) {
		[SA_AlertView showAlertWithTitle: NSLocalizedString(@"API Disabled for Current User", nil) message: NSLocalizedString(@"Please contact your system administrator.", nil)];
		[[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_api_disabled];
		return;
	}
	[self.allRecentErrors addObject: error];
	[self logString: $S(@"[ERROR] in Sync for %@ (%@)\n%@\n (original query: %@)\n", query.objectName, [error.userInfo objectForKey: @"errorCode"], [error.userInfo objectForKey: @"message"], query)];
}

- (void) logMetadataError: (NSError *) error forObjectNamed: (NSString *) name {
	[self.allRecentErrors addObject: error];
	[self logString: $S(@"[ERROR] in Metadata for %@ (%@)\n%@\n", name, [error.userInfo objectForKey: @"errorCode"], [error.userInfo objectForKey: @"message"])];
}

- (void) logUploadError: (NSError *) error forChange: (MM_SFChange *) change {
	[self.allRecentErrors addObject: error];
	[self logString: $S(@"[ERROR] in upload (%@)\n%@\n\n\n%@\n%@", error, [error.userInfo objectForKey: @"errorCode"], [error.userInfo objectForKey: @"message"], [change originalValuesInContext: nil])];
}

- (void) logBlobDownloadError: (NSError *) error forField: (NSString *) field onObjectID: (NSManagedObjectID *) objectID {
	[self.allRecentErrors addObject: error];
	[self logString: $S(@"[ERROR] in download (%@)\n%@\n\n\n%@\n%@", error, [error.userInfo objectForKey: @"errorCode"], [error.userInfo objectForKey: @"message"], field)];
}

- (void) logPOSTError: (NSError *) error onURL: (NSURL *) url {
	[self.allRecentErrors addObject: error];
	[self logString: $S(@"[ERROR] in POST Upload (%@)\n%@\n\n\n%@\n%@", error, [error.userInfo objectForKey: @"errorCode"], [error.userInfo objectForKey: @"message"], url)];
}

- (void) logLevel: (MM_LOG_LEVEL) level string: (NSString *) format, ... {
	if (self.currentLogLevel > level) return;

	va_list args;
    va_start(args, format);
	

	[self logString: [[NSString alloc] initWithFormat: format arguments: args]];
    va_end(args);
}

- (void) logLevel: (MM_LOG_LEVEL) level stringGen: (stringGenBlock) block {
	if (self.currentLogLevel < level) return;
	
	if (block) [self logString: block()];
}

- (void) logFields: (NSDictionary *) fields savedForObjectName: (NSString *) objectName {
	NSMutableString				*string = [NSMutableString stringWithFormat: @"Saving changes for %@:\n", objectName];
	
	for (NSString *key in fields) {
		id				value = fields[key];
		
		if ([value isKindOfClass: [NSData class]]) value = $S(@"Data, %ld bytes", (unsigned long) [value length]);
		if ([value isKindOfClass: [NSString class]] && [value length] > 500) value = $S(@"String, %ld characters", (unsigned long) [value length]);
		if ([value isKindOfClass: [NSNumber class]]) value = $S(@"Number, %@", value);
		
		[string appendFormat: @"\t%@: %@\n", key, value];
	}
	[self logString: string];
}

- (void) logString: (NSString *) message {
	@synchronized(self) {
		if (self.logFile == nil) return;
		if (!self.enabled) return;
        
		if (self.logToConsoleToo) NSLog(@"%@", message);
        
        // log to Crashlytics if available
        if (self.logToCrashlytics) {
            Class cls = NSClassFromString (@"Crashlytics");
            if (cls) {
                if (CLSLog != nil) {
                    CLSLog(@"%@", message);
                }
            }
        }

		NSDate				*date = [NSDate date];
		NSString			*timeStamp = $S(@"%@ %02d:%02d:%02d.%02d: ", date.shortDateString, (UInt16) date.hour, (UInt16) date.minute, (UInt16) date.second, (UInt16)  (date.fractionalSecond * 100));
		const char			*str = timeStamp.UTF8String;
		size_t				len = strlen(str);

		fwrite(str, 1, len, self.logFile);
		str = message.UTF8String;
		len = strlen(str);
		
		size_t				written = fwrite(str, 1, len, self.logFile);
		const char			*breakString = "\n";
//		const char			*breakString = "....................................................................\n";
		
		fwrite(breakString, 1, strlen(breakString), self.logFile);
		
		if (len != written) MMLog(@"Failed to log %@ (%d / %d)", message, (NSInteger) len, (NSInteger) written);
		fflush(self.logFile);
	}
}

- (void) clearRecentErrors { [self.allRecentErrors removeAllObjects]; }

- (void) clearLog {
	if (_logFile) {
		fclose(_logFile);
		_logFile = NULL;
	}
	
	NSError				*error = nil;
	if (![[NSFileManager defaultManager] removeItemAtPath: self.logFilePath error: &error]) MMLog(@"Error while clearing the log: %@", error);
	
	
}

- (void) emailLogFromViewController: (UIViewController *) controller {
	if (![MFMailComposeViewController canSendMail]) return;
	
	MFMailComposeViewController			*mailer = [[MFMailComposeViewController alloc] init];
	NSError								*error = nil;
	
	[mailer setSubject: $S(@"%@ Log", [NSBundle visibleName])];
	[mailer setMessageBody: $S(@"<html><body><pre>%@</pre></body></html>",  [[NSString stringWithContentsOfFile: self.logFilePath encoding: NSUTF8StringEncoding error: &error] stringByReplacingOccurrencesOfString: @"\n" withString: @"<br/>"]) isHTML: YES];
	mailer.mailComposeDelegate = self;
	[self clearLog];
	[controller presentViewController: mailer animated: YES completion: nil];
}

#pragma mark - Mail Delegate

- (void) mailComposeController: (MFMailComposeViewController *) controller didFinishWithResult: (MFMailComposeResult) result error: (NSError *) error {
	[controller dismissViewControllerAnimated: YES completion: nil];
}

#pragma mark - properties

- (void) setLogFilePath:(NSString *)logFilePath {
	_logFilePath = logFilePath;
	if (_logFile) {
		fclose(_logFile);
		_logFile = NULL;
	}
	[[NSUserDefaults standardUserDefaults] setObject: logFilePath forKey: DEFAULTS_LAST_LOG_PATH];
}

- (NSArray *) recentErrors { return self.allRecentErrors; }

- (void) setCurrentLogLevel:(MM_LOG_LEVEL)currentLogLevel {
	_currentLogLevel = currentLogLevel;
	if (currentLogLevel < MM_LOG_LEVEL_HIGH) {
		self.enabled = YES;
		self.logToConsoleToo = YES;
	}
}

#pragma mark - Private

- (FILE *) logFile {
	if (_logFile == NULL) {
		_logFile = fopen([self.logFilePath fileSystemRepresentation], "a");
		if (_logFile == NULL) {
			NSLog(@"Error: %d while opening file.", errno);
			SA_Assert(_logFile != NULL, @"Failed to create/open log file.");
			return nil;
		}
		NSDate				*date = [NSDate date];
		NSString			*versionString = $S(@"%@ (%@)", [NSBundle infoDictionaryObjectForKey: @"CFBundleShortVersionString"], [NSBundle infoDictionaryObjectForKey: @"CFBundleVersion"]);
		[self logString: $S(@"\n\nBegan Logging at %@, %@. Bundle ID: %@, version: %@\n====================================================================", date.mediumDateString, date.mediumTimeString, [NSBundle identifier], versionString)];
	}
	return _logFile;
}

@end
