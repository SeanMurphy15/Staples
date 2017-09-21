//
//  NSFileManager+SA_Additions.h
//
//  Created by Ben Gottlieb on 4/1/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (NSFileManager_SA_Additions)

@property (nonatomic, readonly) NSString *applicationSupportFolder, *documentsFolder;

- (NSDate *) modificationDateOfFileAtPath: (NSString *) path;
- (BOOL) copyFileOfVersion: (NSUInteger) currentFileVersion from: (NSString *) srcPath to: (NSString *) dstPath error: (NSError	**) outError;

+ (void) watchForChangesAtPath: (NSString *) path withTarget: (id) target action: (SEL) action;
+ (void) stopWatchingChangesAtPath: (NSString *) path;

+ (NSURL *) libraryDirectory;
+ (NSURL *) documentsDirectory;
+ (NSURL *) cachesDirectory;
+ (NSURL *) applicationSupportDirectory;

#if TARGET_OS_IPHONE
+ (void) setFileAtURLNotBackedUp: (NSURL *) url;
#endif
@end
