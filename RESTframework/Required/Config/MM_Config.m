//
//  MM_Config.m
//
//  Created by Ben Gottlieb on 1/4/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "MM_Config.h"
#import "MM_LoginViewController.h"
#import "MM_Headers.h"

@implementation MM_Config
@synthesize startupSyncInterval, lastSyncDate = _lastSyncDate;

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(MM_Config, sharedManager);

- (id) init {
	if ((self = [super init])) {
		_lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey: kDefaults_LastSyncDate];
		
		[self addAsObserverForName: UIApplicationDidBecomeActiveNotification selector: @selector(checkForAutosync)];
		[self addAsObserverForName: UIApplicationDidFinishLaunchingNotification selector: @selector(checkForAutosync)];
		[self performSelector: @selector(checkForAutosync) withObject: nil afterDelay: 1.0];
	}
	return self;
}

- (BOOL) startupSyncRequired {
	if (![MM_LoginViewController isLoggedIn]) return NO;
	if (![[MM_SyncManager sharedManager] hasSyncedOnce]) return NO;
	if (self.lastSyncDate == nil) return YES;
	
	NSDate			*now = [NSDate date];
	
	if (self.syncOnceADay && (self.lastSyncDate.day != now.day || self.lastSyncDate.month != now.month || self.lastSyncDate.year != now.year)) return  YES;
	
	if (self.startupSyncInterval == 0) return NO;
	return ABS([self.lastSyncDate absoluteTimeIntervalFromNow]) > self.startupSyncInterval;
}

- (void) setLastSyncDate:(NSDate *)lastSyncDate {
	_lastSyncDate = lastSyncDate;
	
	[[NSUserDefaults standardUserDefaults] setObject: lastSyncDate forKey: kDefaults_LastSyncDate];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *) lastSyncDate {
	if (![MM_LoginViewController isLoggedIn]) return nil;
	return _lastSyncDate;
}

- (float) libraryVersion { return LIBRARY_VERSION; }

- (void) checkForAutosync {
	if ([self startupSyncRequired]) {
		[[MM_SyncManager sharedManager] synchronize: nil withCompletionBlock: nil];
	}
}

- (void) reset
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey: kDefaults_LastSyncDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.lastSyncDate = nil;
}
@end
