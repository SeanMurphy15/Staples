//
//  MM_ContextManager+Atomic.h
//  McGraw Hill
//
//  Created by Ben Gottlieb on 4/7/14.
//  Copyright (c) 2014 Model Metrics. All rights reserved.
//

#import "MM_ContextManager.h"

@interface MM_ContextManager (Atomic)

@property (nonatomic, readonly) BOOL isBackedUpDataAvailable;

- (void) copyExistingDataOffWithCompletion: (errorArgumentBlock) completion;
- (void) restoreBackedUpDataWithCompletion: (errorArgumentBlock) completion;
- (void) clearBackedUpDataWithCompletion: (errorArgumentBlock) completion;

- (void) clearAllDataWithCompletion: (errorArgumentBlock) block;

@end
