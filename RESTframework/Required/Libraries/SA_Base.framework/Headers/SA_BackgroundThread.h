//
//  SA_BackgroundThread.h
//
//  Created by Ben Gottlieb on 7/14/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+SA_Additions.h"

@interface SA_BackgroundThread : NSObject {
	NSThread				*_thread;
	BOOL					_running;
}

@property (nonatomic, readonly) NSThread *thread;

+ (id) startBackgroundThread;
+ (SA_BackgroundThread *) backgroundThread;
+ (id) spawnThread;
+ (BOOL) inBackgroundThread;
+ (NSThread *) thread;
+ (void) performSelector: (SEL) selector onObject: (id) object;
+ (void) performSelector: (SEL) selector onObject: (id) object withObject: (id) anotherObject;
+ (void) performSelector: (SEL) selector onObject: (id) object withObject: (id) anotherObject waitUntilDone: (BOOL) waitUntilDone;

#if NS_BLOCKS_AVAILABLE
	+ (void) performBlockInBackgroundThread: (simpleBlock) block;
#endif
@end
