// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MM_SFChange.m instead.

#import "_MM_SFChange.h"

const struct MM_SFChangeAttributes MM_SFChangeAttributes = {
	.error = @"error",
	.inProgress = @"inProgress",
	.isNewObject = @"isNewObject",
	.modifiedAt = @"modifiedAt",
	.queuedAt = @"queuedAt",
	.modifiedValuesData = @"modifiedValuesData",
	.originalValuesData = @"originalValuesData",
	.ownerSFID = @"ownerSFID",
	.targetEntity = @"targetEntity",
	.targetObjectID = @"targetObjectID",
	.targetSalesforceID = @"targetSalesforceID",
};

const struct MM_SFChangeRelationships MM_SFChangeRelationships = {
};

const struct MM_SFChangeFetchedProperties MM_SFChangeFetchedProperties = {
};

@implementation MM_SFChangeID
@end

@implementation _MM_SFChange

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SFChange" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SFChange";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SFChange" inManagedObjectContext:moc_];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"inProgressValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"inProgress"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"isNewObjectValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isNewObject"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic error;






@dynamic inProgress;



- (BOOL)inProgressValue {
	NSNumber *result = [self inProgress];
	return [result boolValue];
}

- (void)setInProgressValue:(BOOL)value_ {
	[self setInProgress:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveInProgressValue {
	NSNumber *result = [self primitiveInProgress];
	return [result boolValue];
}

- (void)setPrimitiveInProgressValue:(BOOL)value_ {
	[self setPrimitiveInProgress:[NSNumber numberWithBool:value_]];
}





@dynamic isNewObject;



- (BOOL)isNewObjectValue {
	NSNumber *result = [self isNewObject];
	return [result boolValue];
}

- (void)setIsNewObjectValue:(BOOL)value_ {
	[self setIsNewObject:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsNewObjectValue {
	NSNumber *result = [self primitiveIsNewObject];
	return [result boolValue];
}

- (void)setPrimitiveIsNewObjectValue:(BOOL)value_ {
	[self setPrimitiveIsNewObject:[NSNumber numberWithBool:value_]];
}





@dynamic modifiedAt, queuedAt;






@dynamic modifiedValuesData;






@dynamic originalValuesData;






@dynamic ownerSFID;






@dynamic targetEntity;






@dynamic targetObjectID;






@dynamic targetSalesforceID;











@end
