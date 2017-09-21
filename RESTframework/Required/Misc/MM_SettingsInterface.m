//
//  MM_SettingsInterface.m
//  DSA
//
//  Created by Ben Gottlieb on 6/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "MM_SettingsInterface.h"
#import "MM_LoginViewController.h"
#import "MM_SyncManager.h"

@implementation MM_SettingsInterface

+ (void) load {
	dispatch_after_main_queue(0.1, ^{
		[self checkForChangedSettings];
	});
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(didReturnToForeground) name: UIApplicationDidBecomeActiveNotification object: nil];
}

+ (void) checkForChangedSettings {
	NSString				*lastLoginDomain = [[NSUserDefaults standardUserDefaults] stringForKey: DEFAULTS_LOGIN_DOMAIN];
	
	if (lastLoginDomain.length == 0) {
		lastLoginDomain = @"login.salesforce.com";
	}
	
	BOOL					newSandboxSetting = [[NSUserDefaults standardUserDefaults] boolForKey: DEFAULTS_USE_SANDBOX];
	BOOL					oldSandboxSetting = [lastLoginDomain hasPrefix: @"test."];
	static BOOL				alertShown = NO;
	
	if (newSandboxSetting != oldSandboxSetting && !alertShown) {
		alertShown = YES;
		[MM_LoginViewController logout];
		[NSUserDefaults syncObject: newSandboxSetting ? @"test.salesforce.com" : @"login.salesforce.com" forKey: DEFAULTS_LOGIN_DOMAIN];
		[MM_SyncManager sharedManager].hasSyncedOnce = NO;
		
		[SA_AlertView showAlertWithTitle: NSLocalizedString(@"Your Sandbox Setting has Changed.", nil)
								 message: $S(NSLocalizedString(@"%@ must now restart in order to reconfigure your database.", nil), [NSBundle visibleName])
								 buttons: @[NSLocalizedString(@"OK", nil) ] buttonBlock:^(NSInteger index) {
									 [UILocalNotification presentNotificationText: $S(NSLocalizedString(@"Configuration complete. Please touch \"Continue\" to re-open '%@' and log in.", nil), [NSBundle visibleName]) withAction: NSLocalizedString(@"Continue", nil) sound: nil atDate: [NSDate dateWithTimeIntervalSinceNow: 1.25] andUserInfo: nil];
									 
									 abort();
								 }];
	}
	
}

+ (void) didReturnToForeground {
	[self checkForChangedSettings];
}

@end
