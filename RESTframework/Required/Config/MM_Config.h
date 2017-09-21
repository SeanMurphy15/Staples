//
//  MM_Config.h
//
//  Created by Ben Gottlieb on 1/4/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDefaults_LastSyncDate				@"mm: last_sync_date"

@interface MM_Config : NSObject

@property (nonatomic) NSTimeInterval startupSyncInterval;		//how often should the app auto-synchronize when starting up? Set to zero to never auto-sync, defaults to 1/day
@property (nonatomic, strong) NSDate *lastSyncDate;
@property (nonatomic, readonly) BOOL startupSyncRequired;
@property (nonatomic, readonly) float libraryVersion;
@property (nonatomic) BOOL syncOnceADay;

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(MM_Config, sharedManager);

- (void) reset;

@end


