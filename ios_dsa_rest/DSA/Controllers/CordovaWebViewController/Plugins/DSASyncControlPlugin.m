//
// DSASyncControlPlugin.m
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import "DSASyncControlPlugin.h"
#import "NSArray+JSONOperations.h"
#import "MM_Headers.h"
#import "SBJson.h"
#import "SSZipArchive.h"
#import "DSA_AppDelegate.h"
#import "MM_LoginViewController.h"
#import "MMSF_Category__c.h"
#import "DSA_MediaDisplayViewController.h"
#import "MM_SyncManager.h"
#import "MM_OrgMetaData.h"


@implementation DSASyncControlPlugin

- (void) writeErrorForCommand:(CDVInvokedUrlCommand *) command {
    CDVPluginResult *result;
    NSString *javaScript;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error"];
    javaScript = [result toErrorCallbackString:command.callbackId];
    [self writeJavascript:javaScript];
}


- (void) deltaSync:(CDVInvokedUrlCommand *)command {
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        LOG(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    NSArray *echo = [command.arguments[0] componentsSeparatedByString:@","];
    NSArray *listData = [NSArray arrayWithArray:echo];
    NSMutableArray *plistData = [[NSMutableArray alloc] init];
    NSArray *new;
    NSString *path =    [[NSFileManager libraryDirectory] URLByAppendingPathComponent: @"sync_objects.plist"].path;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path])
        path = [[NSBundle mainBundle] pathForResource: @"sync_objects" ofType: @"plist"];
    
    NSData					*data = [NSData dataWithContentsOfFile: path];
    NSPropertyListFormat	format;
    NSError					*error = nil;
    if (data) {
        NSDictionary			*plist = [NSPropertyListSerialization propertyListWithData: data options: 0 format: &format error: &error];
        if (error) [SA_AlertView showAlertWithTitle: @"Error while reading in list of objects to sync" error: error];
		
        new = [plist objectForKey: @"objects"];
    } else {
        new = [NSArray array];
    }
    
    NSDictionary *dictionary = nil;
    for(int i=0;i<[new count];i++){
        for(int j=0;j<[listData count];j++){
            if([[[new objectAtIndex:i] valueForKey:@"name"] isEqualToString:[listData objectAtIndex:j]]){
                dictionary = [new objectAtIndex:i];
                [plistData addObject:dictionary];
            }
            else
                continue;
        }
    }
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"User",@"ProfileId,Id,LastModifiedDate,CreatedDate,Username,Name,FirstName,LastName,Email,UserRoleId",@"YES",@"YES",nil] forKeys:[NSArray arrayWithObjects:@"name",@"only-list",@"post-sync-link",@"always-check-ids-with-server", nil]];
    NSArray *arr = [NSArray arrayWithObject:dic];
    
    NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadMetaContext;
	NSMutableArray				*objectsToSync = [NSMutableArray arrayWithCapacity: arr.count];
	NSMutableArray				*inaccessibleObjects = [NSMutableArray array];
    
	for (NSDictionary *objectInfo in plistData) {
		MM_SFObjectDefinition			*object = [MM_SFObjectDefinition objectNamed: [objectInfo objectForKey: @"name"] inContext: moc];
		
		if (object) {
			NSDictionary			*existingSyncInfo = (id) object.syncInfo_mm;
			
			if (![existingSyncInfo isEqualToDictionary: objectInfo]) {
				object.syncInfo_mm = objectInfo;
				[object save];
			}
			[objectsToSync addObject: object];
		}
        else if (![objectInfo objectForKey: @"ignore-errors"])
			[inaccessibleObjects addObject: objectInfo[@"name"]];
		
	}
    [[MM_SyncManager sharedManager] synchronize:objectsToSync  withCompletionBlock: nil];
    [self writeErrorForCommand:command];
}

- (void) fullSync:(CDVInvokedUrlCommand *)command {
    DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controller];
//    [g_appDelegate syncObjectDataDownload:^(){
//        [[MM_OrgMetaData sharedMetaData] resetObjectsToSync];
//        [[MM_SyncManager sharedManager] resyncAllDataWithCompletionBlock:nil];
//    }];
    [vc dismissViewControllerAnimated:YES completion:nil];
}


@end

#endif
