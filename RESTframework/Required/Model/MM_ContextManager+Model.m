//
//  MM_ContextManager+Model.m
//
//  Created by Ben Gottlieb on 11/14/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_ContextManager+Model.h"
#import "MM_SyncManager.h"
#import "MM_SFObjectDefinition.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_Log.h"

@implementation MM_ContextManager (Model)


- (void) updateContentModel {
	[MM_SFObjectDefinition clearCachedObjectDefinitions];
	
	NSManagedObjectModel			*existingModel = self.contentModel;
	NSManagedObjectModel			*model = [NSManagedObjectModel modelWithObjects: [MM_SyncManager sharedManager].objectsToSync];
	
	if (![existingModel isEqual: model]) {
		if (existingModel && [[NSFileManager defaultManager] fileExistsAtPath: self.contentContextPath]) {
			if (![model attemptMigrationOfContextAtPath: self.contentContextPath fromOldModel: existingModel]) {
				for (MM_SFObjectDefinition *object in [[MM_SyncManager sharedManager] objectsToSync]) {
					[object resetLastSyncDate];
				}
				[[MM_ContextManager sharedManager].mainMetaContext save];
				[SA_AlertView showAlertWithTitle: @"Model Changed" message: @"The database model has changed. The existing database will be removed, and a full sync will proceed."];
			}
		}
		[model writeToFile: self.contentModelPath];
		[self resetContentContext];
	}
	
	MMLog(@"- Object Model Update: Complete %@", @"");
}

@end
