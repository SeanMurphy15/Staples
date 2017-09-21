//
//  UIDevice+UserInfo.h
//
//  Created by Ben Gottlieb on 6/29/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	connection_none,
	connection_wan,
	connection_lan
} connection_type;

#define					kTransform_Portrait				CGAffineTransformMake(1, 0, 0, 1, 0, 0)
#define					kTransform_PortraitUpsideDown	CGAffineTransformMake(-1, 0, 0, -1, 0, 0)
#define					kTransform_LandscapeLeft		CGAffineTransformMake(0, 1, -1, 0, 0, 0)
#define					kTransform_LandscapeRight		CGAffineTransformMake(0, -1, 1, 0, 0, 0)

@interface UIDevice (UIDevice_UserInfo)

@property (nonatomic, readonly) BOOL isHookedUpToDebugger;
@property (nonatomic, readonly) natural_t totalStorageSpace, availableStorageSpace, availableMemory;
@property (nonatomic, readonly) connection_type connectionType;
@property (nonatomic, readonly) NSString *deviceMachineName, *shortLocalizedModel, *displayName;
@property (nonatomic, readonly) float OSVersion;
@property (nonatomic, readonly) UIInterfaceOrientation userInterfaceOrientation;

@property (nonatomic, readonly) NSString *legacyUniqueIdentifier;

@end


@interface UIScreen (SA_Additions)
- (CGRect) currentFrameConsideringInterfaceOrientation;		//not working properly yet
@end
