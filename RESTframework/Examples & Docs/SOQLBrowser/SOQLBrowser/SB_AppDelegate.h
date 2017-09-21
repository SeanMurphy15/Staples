//
//  SB_AppDelegate.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/21/11.
//  Copyright (c) 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNotification_EntityTypeSelected			@"kNotification_EntityTypeSelected"

@interface SB_AppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>


@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *accesstoken;
@property (nonatomic, retain) NSString *instanceurl;

- (void) presentLoginScreenFromBarButtonItem: (UIBarButtonItem *) item;

- (void) saveOrgMetaData;
- (void) restoreOrgMetaData;
- (void) fullSync;
@end

extern SB_AppDelegate *g_appDelegate;