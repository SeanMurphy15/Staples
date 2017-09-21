// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MM_SFObjectDefinition.m instead.

#import "_MM_SFObjectDefinition.h"

const struct MM_SFObjectDefinitionAttributes MM_SFObjectDefinitionAttributes = {
	.activateable = @"activateable",
	.canFilterOnLastModified = @"canFilterOnLastModified",
	.checkingForDeletedObjects_mm = @"checkingForDeletedObjects_mm",
	.createable = @"createable",
	.custom = @"custom",
	.customSetting = @"customSetting",
	.deletable = @"deletable",
	.deprecatedAndHidden = @"deprecatedAndHidden",
	.feedEnabled = @"feedEnabled",
	.fullSyncCompleted_mm = @"fullSyncCompleted_mm",
	.fullSyncInProgress_mm = @"fullSyncInProgress_mm",
	.keyPrefix = @"keyPrefix",
	.label = @"label",
	.labelPlural = @"labelPlural",
	.lastSyncError_mm = @"lastSyncError_mm",
	.lastSyncedAt_mm = @"lastSyncedAt_mm",
	.layout_mm = @"layout_mm",
	.layoutable = @"layoutable",
	.mergeable = @"mergeable",
	.metaDescription_mm = @"metaDescription_mm",
	.metaLayout_mm = @"metaLayout_mm",
	.moreResultsURL_mm = @"moreResultsURL_mm",
	.name = @"name",
	.objectName_mm = @"objectName_mm",
	.queryable = @"queryable",
	.replicateable = @"replicateable",
	.retrieveable = @"retrieveable",
	.searchable = @"searchable",
	.serverObjectCount = @"serverObjectCount",
	.serverObjectName_mm = @"serverObjectName_mm",
	.syncInfo_mm = @"syncInfo_mm",
	.triggerable = @"triggerable",
	.undeletable = @"undeletable",
	.updateable = @"updateable",
	.urls = @"urls",
};

const struct MM_SFObjectDefinitionRelationships MM_SFObjectDefinitionRelationships = {
};

const struct MM_SFObjectDefinitionFetchedProperties MM_SFObjectDefinitionFetchedProperties = {
};

@implementation MM_SFObjectDefinitionID
@end

@implementation _MM_SFObjectDefinition

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SFObjectDefinition" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SFObjectDefinition";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SFObjectDefinition" inManagedObjectContext:moc_];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"activateableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"activateable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"canFilterOnLastModifiedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"canFilterOnLastModified"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"checkingForDeletedObjects_mmValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"checkingForDeletedObjects_mm"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"createableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"createable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"customValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"custom"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"customSettingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"customSetting"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"deletableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"deletable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"deprecatedAndHiddenValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"deprecatedAndHidden"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"feedEnabledValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"feedEnabled"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"fullSyncCompleted_mmValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fullSyncCompleted_mm"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"fullSyncInProgress_mmValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"fullSyncInProgress_mm"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"layoutableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"layoutable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"mergeableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"mergeable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"queryableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"queryable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"replicateableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"replicateable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"retrieveableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"retrieveable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"searchableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"searchable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"serverObjectCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"serverObjectCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"triggerableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"triggerable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"undeletableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"undeletable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"updateableValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"updateable"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic activateable;



- (BOOL)activateableValue {
	NSNumber *result = [self activateable];
	return [result boolValue];
}

- (void)setActivateableValue:(BOOL)value_ {
	[self setActivateable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveActivateableValue {
	NSNumber *result = [self primitiveActivateable];
	return [result boolValue];
}

- (void)setPrimitiveActivateableValue:(BOOL)value_ {
	[self setPrimitiveActivateable:[NSNumber numberWithBool:value_]];
}





@dynamic canFilterOnLastModified;



- (BOOL)canFilterOnLastModifiedValue {
	NSNumber *result = [self canFilterOnLastModified];
	return [result boolValue];
}

- (void)setCanFilterOnLastModifiedValue:(BOOL)value_ {
	[self setCanFilterOnLastModified:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveCanFilterOnLastModifiedValue {
	NSNumber *result = [self primitiveCanFilterOnLastModified];
	return [result boolValue];
}

- (void)setPrimitiveCanFilterOnLastModifiedValue:(BOOL)value_ {
	[self setPrimitiveCanFilterOnLastModified:[NSNumber numberWithBool:value_]];
}





@dynamic checkingForDeletedObjects_mm;



- (BOOL)checkingForDeletedObjects_mmValue {
	NSNumber *result = [self checkingForDeletedObjects_mm];
	return [result boolValue];
}

- (void)setCheckingForDeletedObjects_mmValue:(BOOL)value_ {
	[self setCheckingForDeletedObjects_mm:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveCheckingForDeletedObjects_mmValue {
	NSNumber *result = [self primitiveCheckingForDeletedObjects_mm];
	return [result boolValue];
}

- (void)setPrimitiveCheckingForDeletedObjects_mmValue:(BOOL)value_ {
	[self setPrimitiveCheckingForDeletedObjects_mm:[NSNumber numberWithBool:value_]];
}





@dynamic createable;



- (BOOL)createableValue {
	NSNumber *result = [self createable];
	return [result boolValue];
}

- (void)setCreateableValue:(BOOL)value_ {
	[self setCreateable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveCreateableValue {
	NSNumber *result = [self primitiveCreateable];
	return [result boolValue];
}

- (void)setPrimitiveCreateableValue:(BOOL)value_ {
	[self setPrimitiveCreateable:[NSNumber numberWithBool:value_]];
}





@dynamic custom;



- (BOOL)customValue {
	NSNumber *result = [self custom];
	return [result boolValue];
}

- (void)setCustomValue:(BOOL)value_ {
	[self setCustom:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveCustomValue {
	NSNumber *result = [self primitiveCustom];
	return [result boolValue];
}

- (void)setPrimitiveCustomValue:(BOOL)value_ {
	[self setPrimitiveCustom:[NSNumber numberWithBool:value_]];
}





@dynamic customSetting;



- (BOOL)customSettingValue {
	NSNumber *result = [self customSetting];
	return [result boolValue];
}

- (void)setCustomSettingValue:(BOOL)value_ {
	[self setCustomSetting:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveCustomSettingValue {
	NSNumber *result = [self primitiveCustomSetting];
	return [result boolValue];
}

- (void)setPrimitiveCustomSettingValue:(BOOL)value_ {
	[self setPrimitiveCustomSetting:[NSNumber numberWithBool:value_]];
}





@dynamic deletable;



- (BOOL)deletableValue {
	NSNumber *result = [self deletable];
	return [result boolValue];
}

- (void)setDeletableValue:(BOOL)value_ {
	[self setDeletable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveDeletableValue {
	NSNumber *result = [self primitiveDeletable];
	return [result boolValue];
}

- (void)setPrimitiveDeletableValue:(BOOL)value_ {
	[self setPrimitiveDeletable:[NSNumber numberWithBool:value_]];
}





@dynamic deprecatedAndHidden;



- (BOOL)deprecatedAndHiddenValue {
	NSNumber *result = [self deprecatedAndHidden];
	return [result boolValue];
}

- (void)setDeprecatedAndHiddenValue:(BOOL)value_ {
	[self setDeprecatedAndHidden:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveDeprecatedAndHiddenValue {
	NSNumber *result = [self primitiveDeprecatedAndHidden];
	return [result boolValue];
}

- (void)setPrimitiveDeprecatedAndHiddenValue:(BOOL)value_ {
	[self setPrimitiveDeprecatedAndHidden:[NSNumber numberWithBool:value_]];
}





@dynamic feedEnabled;



- (BOOL)feedEnabledValue {
	NSNumber *result = [self feedEnabled];
	return [result boolValue];
}

- (void)setFeedEnabledValue:(BOOL)value_ {
	[self setFeedEnabled:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveFeedEnabledValue {
	NSNumber *result = [self primitiveFeedEnabled];
	return [result boolValue];
}

- (void)setPrimitiveFeedEnabledValue:(BOOL)value_ {
	[self setPrimitiveFeedEnabled:[NSNumber numberWithBool:value_]];
}





@dynamic fullSyncCompleted_mm;



- (BOOL)fullSyncCompleted_mmValue {
	NSNumber *result = [self fullSyncCompleted_mm];
	return [result boolValue];
}

- (void)setFullSyncCompleted_mmValue:(BOOL)value_ {
	[self setFullSyncCompleted_mm:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveFullSyncCompleted_mmValue {
	NSNumber *result = [self primitiveFullSyncCompleted_mm];
	return [result boolValue];
}

- (void)setPrimitiveFullSyncCompleted_mmValue:(BOOL)value_ {
	[self setPrimitiveFullSyncCompleted_mm:[NSNumber numberWithBool:value_]];
}





@dynamic fullSyncInProgress_mm;



- (BOOL)fullSyncInProgress_mmValue {
	NSNumber *result = [self fullSyncInProgress_mm];
	return [result boolValue];
}

- (void)setFullSyncInProgress_mmValue:(BOOL)value_ {
	[self setFullSyncInProgress_mm:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveFullSyncInProgress_mmValue {
	NSNumber *result = [self primitiveFullSyncInProgress_mm];
	return [result boolValue];
}

- (void)setPrimitiveFullSyncInProgress_mmValue:(BOOL)value_ {
	[self setPrimitiveFullSyncInProgress_mm:[NSNumber numberWithBool:value_]];
}





@dynamic keyPrefix;






@dynamic label;






@dynamic labelPlural;






@dynamic lastSyncError_mm;






@dynamic lastSyncedAt_mm;






@dynamic layout_mm;






@dynamic layoutable;



- (BOOL)layoutableValue {
	NSNumber *result = [self layoutable];
	return [result boolValue];
}

- (void)setLayoutableValue:(BOOL)value_ {
	[self setLayoutable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveLayoutableValue {
	NSNumber *result = [self primitiveLayoutable];
	return [result boolValue];
}

- (void)setPrimitiveLayoutableValue:(BOOL)value_ {
	[self setPrimitiveLayoutable:[NSNumber numberWithBool:value_]];
}





@dynamic mergeable;



- (BOOL)mergeableValue {
	NSNumber *result = [self mergeable];
	return [result boolValue];
}

- (void)setMergeableValue:(BOOL)value_ {
	[self setMergeable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveMergeableValue {
	NSNumber *result = [self primitiveMergeable];
	return [result boolValue];
}

- (void)setPrimitiveMergeableValue:(BOOL)value_ {
	[self setPrimitiveMergeable:[NSNumber numberWithBool:value_]];
}





@dynamic metaDescription_mm;






@dynamic metaLayout_mm;






@dynamic moreResultsURL_mm;






@dynamic name;






@dynamic objectName_mm;






@dynamic queryable;



- (BOOL)queryableValue {
	NSNumber *result = [self queryable];
	return [result boolValue];
}

- (void)setQueryableValue:(BOOL)value_ {
	[self setQueryable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveQueryableValue {
	NSNumber *result = [self primitiveQueryable];
	return [result boolValue];
}

- (void)setPrimitiveQueryableValue:(BOOL)value_ {
	[self setPrimitiveQueryable:[NSNumber numberWithBool:value_]];
}





@dynamic replicateable;



- (BOOL)replicateableValue {
	NSNumber *result = [self replicateable];
	return [result boolValue];
}

- (void)setReplicateableValue:(BOOL)value_ {
	[self setReplicateable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveReplicateableValue {
	NSNumber *result = [self primitiveReplicateable];
	return [result boolValue];
}

- (void)setPrimitiveReplicateableValue:(BOOL)value_ {
	[self setPrimitiveReplicateable:[NSNumber numberWithBool:value_]];
}





@dynamic retrieveable;



- (BOOL)retrieveableValue {
	NSNumber *result = [self retrieveable];
	return [result boolValue];
}

- (void)setRetrieveableValue:(BOOL)value_ {
	[self setRetrieveable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveRetrieveableValue {
	NSNumber *result = [self primitiveRetrieveable];
	return [result boolValue];
}

- (void)setPrimitiveRetrieveableValue:(BOOL)value_ {
	[self setPrimitiveRetrieveable:[NSNumber numberWithBool:value_]];
}





@dynamic searchable;



- (BOOL)searchableValue {
	NSNumber *result = [self searchable];
	return [result boolValue];
}

- (void)setSearchableValue:(BOOL)value_ {
	[self setSearchable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSearchableValue {
	NSNumber *result = [self primitiveSearchable];
	return [result boolValue];
}

- (void)setPrimitiveSearchableValue:(BOOL)value_ {
	[self setPrimitiveSearchable:[NSNumber numberWithBool:value_]];
}





@dynamic serverObjectCount, linkRequiredTag;



- (int32_t)serverObjectCountValue {
	NSNumber *result = [self serverObjectCount];
	return [result intValue];
}

- (void)setServerObjectCountValue:(int32_t)value_ {
	[self setServerObjectCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveServerObjectCountValue {
	NSNumber *result = [self primitiveServerObjectCount];
	return [result intValue];
}

- (void)setPrimitiveServerObjectCountValue:(int32_t)value_ {
	[self setPrimitiveServerObjectCount:[NSNumber numberWithInt:value_]];
}





@dynamic serverObjectName_mm;






@dynamic syncInfo_mm;






@dynamic triggerable;



- (BOOL)triggerableValue {
	NSNumber *result = [self triggerable];
	return [result boolValue];
}

- (void)setTriggerableValue:(BOOL)value_ {
	[self setTriggerable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveTriggerableValue {
	NSNumber *result = [self primitiveTriggerable];
	return [result boolValue];
}

- (void)setPrimitiveTriggerableValue:(BOOL)value_ {
	[self setPrimitiveTriggerable:[NSNumber numberWithBool:value_]];
}





@dynamic undeletable;



- (BOOL)undeletableValue {
	NSNumber *result = [self undeletable];
	return [result boolValue];
}

- (void)setUndeletableValue:(BOOL)value_ {
	[self setUndeletable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUndeletableValue {
	NSNumber *result = [self primitiveUndeletable];
	return [result boolValue];
}

- (void)setPrimitiveUndeletableValue:(BOOL)value_ {
	[self setPrimitiveUndeletable:[NSNumber numberWithBool:value_]];
}





@dynamic updateable;



- (BOOL)updateableValue {
	NSNumber *result = [self updateable];
	return [result boolValue];
}

- (void)setUpdateableValue:(BOOL)value_ {
	[self setUpdateable:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUpdateableValue {
	NSNumber *result = [self primitiveUpdateable];
	return [result boolValue];
}

- (void)setPrimitiveUpdateableValue:(BOOL)value_ {
	[self setPrimitiveUpdateable:[NSNumber numberWithBool:value_]];
}





@dynamic urls;











@end
