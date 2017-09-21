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

+ (connection_type) connectionType;
+ (float) availableMemory;
+ (float) availableStorageSpace;
+ (NSString*) deviceMachineName;

- (float) OSVersion;
- (NSString *) udid;			//based off of MAC address
- (NSString *) appBasedUDID;	//based off of MAC address and app identifier

- (UIInterfaceOrientation) userInterfaceOrientation;
- (NSString *) shortLocalizedModel;
- (NSString *) MACAddress;
@end
