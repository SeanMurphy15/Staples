//
//  MM_SyncStatus.h
//
//  Created by Ben Gottlieb on 9/4/13.
//
//

#import <Foundation/Foundation.h>

@interface MM_SyncStatus : NSObject

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(MM_SyncStatus, status);

@property (nonatomic, readonly) BOOL isSyncInProgress;


- (void) beginSyncWithObjectNames: (NSArray *) names;
- (void) markSyncComplete;

- (void) markObjectNameStarted: (NSString *) objectName;
- (void) markObjectNameComplete: (NSString *) objectName;

@end
