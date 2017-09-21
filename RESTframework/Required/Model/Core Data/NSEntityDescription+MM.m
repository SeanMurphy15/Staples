//
//  NSEntityDescription.m
//  DynamicCoreData
//
//  Created by Ben Gottlieb on 10/2/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "NSEntityDescription+MM.h"
#import "NSManagedObjectModel+MM.h"
#import "MM_Constants.h"
#import "MM_Log.h"

#define			PENDING_RELATIONSHIPS_ASSOCIATED_KEY					@"PENDING_RELATIONSHIPS_KEY"

#define			DCDAssert(condition, desc, ...)					NSAssert(condition, desc, ##  __VA_ARGS__)

@interface MM_EntityDescription : NSEntityDescription
@end

@implementation MM_EntityDescription
@end


@implementation NSEntityDescription (MM)

- (NSMutableSet *) pendingRelationships {
	NSMutableSet		*pending = [self associatedValueForKey: PENDING_RELATIONSHIPS_ASSOCIATED_KEY];
	if (pending == nil) {
		pending = [NSMutableSet set];
		[self associateValue: pending forKey: PENDING_RELATIONSHIPS_ASSOCIATED_KEY];
	}
	return pending;
}

+ (id) entityDescriptionNamed: (NSString *) name {
	NSEntityDescription			*desc = [[self alloc] init];
	
	desc.name = name;
	return desc;
}

- (NSAttributeDescription *) addAttributeNamed: (NSString *) name ofType: (NSAttributeType) type { return [self addAttributeNamed: name ofType: type indexed: NO updateable: YES  createable: YES]; }
- (NSAttributeDescription *) addAttributeNamed: (NSString *) name ofType: (NSAttributeType) type indexed: (BOOL) indexed updateable: (BOOL) updateable createable: (BOOL) createable {
	NSMutableArray				*properties = [self.properties mutableCopy];
	NSAttributeDescription		*desc = [[NSAttributeDescription alloc] init];
	
	desc.attributeType = type;
	desc.name = name;
	desc.indexed = indexed;
	[properties addObject: desc];
	
	if (!updateable || !createable) {
		NSMutableDictionary			*userInfo = [NSMutableDictionary dictionary];
		
		if (!updateable) [userInfo setObject: (id) kCFBooleanTrue forKey: NOT_UPDATEABLE_KEY];
		if (!createable) [userInfo setObject: (id) kCFBooleanTrue forKey: NOT_CREATABLE_KEY];
		desc.userInfo = userInfo;
	}
	
	self.properties = properties;
	return desc;
}

- (void) removeAttributeNamed: (NSString *) name {
	for (NSAttributeDescription *desc in self.properties) {
		if ([desc.name isEqual: name]) {
			NSMutableArray				*properties = [self.properties mutableCopy];
			[properties removeObject: desc];
			self.properties = properties;
			break;
		}
	}
}

- (NSRelationshipDescription *) addRelationship: (NSString *) name toEntity: (NSEntityDescription *) dest reverseName: (NSString *) reverseName oneToManyType: (mm_oneToManyType) type updateable: (BOOL) updateable  createable: (BOOL) createable {
	NSMutableArray				*myProperties = [self.properties mutableCopy];
	NSRelationshipDescription	*existing = [self.relationshipsByName objectForKey: name], *reverseToRemove = nil;

	//check to see if the relationship already exists. If it does, and the backlink is the same (hopefully) then there's nothing to do
	if (existing) {
		if (existing.maxCount == 1 && type == mm_oneToManyType_one_to_many) {
			[myProperties removeObject: existing];
			reverseToRemove = existing.inverseRelationship;
		} else if (existing.maxCount == 1 && type == mm_oneToManyType_many_to_one) {
			[myProperties removeObject: existing];
			reverseToRemove = existing.inverseRelationship;
		} else if (existing.inverseRelationship.name) {
			DCDAssert([existing.destinationEntity isEqual: dest], @"An existing '%@' relationship already exists in %@, but is linked to a %@, not a %@", name, self.name, existing.destinationEntity.name, dest.name);
			DCDAssert(reverseName == nil || [existing.inverseRelationship.name isEqual: reverseName], @"An existing '%@' relationship already exists in %@, but the reverse relationship is '%@', not '%@'", name, self.name, existing.inverseRelationship.name, reverseName);
			return nil;	
		}
	}

	if (reverseName == nil) reverseName = reverseToRemove.name;

	NSMutableArray				*theirProperties = [dest.properties mutableCopy];
	if ([dest.name isEqual: self.name]) theirProperties = myProperties;
	if (reverseToRemove) [theirProperties removeObject: reverseToRemove];
	
	//we may have created a 'fake' backlink earlier on. Let's check for it; if so, remove it, and add the correct one.
	if (reverseName) {
		existing = [dest.relationshipsByName objectForKey: reverseName];

		if (existing.inverseRelationship.name && IS_GENERATED_BACKLINK(existing.inverseRelationship.name)) {
			[theirProperties removeObject: existing];
			[myProperties removeObject: existing.inverseRelationship];
		}
	}
	
	if (reverseName == nil) reverseName = GENERATED_BACKLINK_NAME(name, self.name);
	
	[self removeAttributeNamed: name];
	[dest removeAttributeNamed: reverseName];
		
	NSRelationshipDescription	*mySide = [[NSRelationshipDescription alloc] init];
	NSRelationshipDescription	*theirSide = [[NSRelationshipDescription alloc] init];
	
	
	
	mySide.name = name;
	mySide.inverseRelationship = theirSide;
	mySide.destinationEntity = dest;
	mySide.maxCount = (type == mm_oneToManyType_many_to_one) ? NSUIntegerMax : 1;
	mySide.deleteRule = NSNullifyDeleteRule;// (type == mm_oneToManyType_one_to_many) ? NSCascadeDeleteRule : NSNullifyDeleteRule;
	
	if (!updateable || !createable) {
		NSMutableDictionary			*userInfo = [NSMutableDictionary dictionary];
		
		if (!updateable) [userInfo setObject: (id) kCFBooleanTrue forKey: NOT_UPDATEABLE_KEY];
		if (!createable) [userInfo setObject: (id) kCFBooleanTrue forKey: NOT_CREATABLE_KEY];
		mySide.userInfo = userInfo;
	}

	theirSide.name = reverseName;
	theirSide.inverseRelationship = mySide;
	theirSide.destinationEntity = self;
	theirSide.maxCount = (type == mm_oneToManyType_one_to_many) ? NSUIntegerMax : 1;
	theirSide.deleteRule = NSNullifyDeleteRule;//(type == mm_oneToManyType_many_to_one) ? NSCascadeDeleteRule : NSNullifyDeleteRule;

	
	NSUInteger			theyAlreadyContainIt = [theirProperties indexOfObjectPassingTest: ^(id obj, NSUInteger idx, BOOL *stop) { return [[obj name] isEqual: reverseName]; }];
	NSUInteger			iAlreadyContainIt = [myProperties  indexOfObjectPassingTest: ^(id obj, NSUInteger idx, BOOL *stop) { return [[obj name] isEqual: name]; }];;
	
	if (theyAlreadyContainIt != NSNotFound || iAlreadyContainIt != NSNotFound) {
		if (theyAlreadyContainIt != NSNotFound) { MMLog(@"%@ already contains a %@ named %@", dest.name, [[theirProperties objectAtIndex: theyAlreadyContainIt] class], reverseName); }
		if (iAlreadyContainIt != NSNotFound) { MMLog(@"%@ already contains a %@ named %@", self.name, [[myProperties objectAtIndex: iAlreadyContainIt] class], name); }
		return nil;
	}

	[myProperties addObject: mySide];
	self.properties = myProperties;
	
	[theirProperties addObject: theirSide];
	dest.properties = theirProperties;
	
	return mySide;
}

- (void) addPendingRelationship: (NSString *) name to: (NSString *) entityDestinationName backLinkName: (NSString *) backLinkName isToMany: (mm_oneToManyType) type updateable: (BOOL) updateable createable: (BOOL) createable {
	if ([backLinkName isEqual: [NSNull null]]) backLinkName = nil;
	if ([name isEqual: [NSNull null]]) name = nil;
	
	if (name.length == 0) return;
	[self.pendingRelationships addObject: $D(name, @"name", entityDestinationName, @"dest", @(type), @"toMany", @(updateable), @"updateable", @(createable), @"createable", backLinkName, @"backLink")];
}

- (NSString *) nameForIncomingRelationshipFrom: (NSString *) sourceEntityName {
	return nil;
}

- (void) resolvePendingRelationshipsInModel: (NSManagedObjectModel *) model {
	BOOL				indexShadowFields = [self.userInfo objectForKey: @"post-sync-link"] ? ![[self.userInfo objectForKey: @"post-sync-link"] boolValue] : NO;
	
	for (NSDictionary *relationship in self.pendingRelationships) {
		NSEntityDescription			*dest = [model entityDescriptionNamed: [relationship objectForKey: @"dest"]];
		
		if (dest) {
			//BOOL						isToMany = [[relationship objectForKey: @"toMany"] boolValue];
			//NSString					*backLink = [relationship objectForKey: @"backLink"];
			
			NSString					*name = [relationship objectForKey: @"name"];
			NSString                    *backLink = $S(@"%@_%@_mm", self.name, name);
			
			//mm_oneToManyType			type = [[relationship objectForKey: @"toMany"] intValue];//isToMany ? mm_oneToManyType_one_to_many : mm_oneToManyType_one_to_one;
			
			if ([[dest attributesByName] objectForKey: RELATIONSHIP_OBJECTID_SHADOW(backLink)]) continue;			//polymorphic back link
			
			//if (type == mm_oneToManyType_one_to_one && [name hasSuffix: @"__r"]) type = mm_oneToManyType_many_to_one;
			if ([self addRelationship: name toEntity: dest reverseName: backLink oneToManyType: mm_oneToManyType_one_to_many updateable: [[relationship objectForKey: @"updateable"] boolValue]  createable: [[relationship objectForKey: @"createable"] boolValue]]) {
				if (![[self attributesByName] objectForKey: RELATIONSHIP_SFID_SHADOW(name)])
					[self addAttributeNamed: RELATIONSHIP_SFID_SHADOW(name) ofType: NSStringAttributeType indexed: indexShadowFields updateable: NO createable: NO];
				//if (backLink && ![[dest attributesByName] objectForKey: RELATIONSHIP_SFID_SHADOW(backLink)]) [dest addAttributeNamed: RELATIONSHIP_SFID_SHADOW(backLink) ofType: NSStringAttributeType];
			}
		} else {
			//MMLog(@"Unable to create link from %@ to %@", self.name, relationship[@"dest"]);
		}
	}
}

@end

@implementation NSString (NSEntityDescription_MM)
- (NSAttributeType) convertToAttributeType {
	if ([self isEqual: @"id"] || [self isEqual: @"string"] || [self isEqual: @"textarea"] || [self isEqual: @"reference"] || 
		[self isEqual: @"picklist"] || [self isEqual: @"phone"] || [self isEqual: @"multipicklist"] || [self isEqual: @"url"] ||
		[self isEqual: @"email"] || [self isEqual: @"combobox"]) return NSStringAttributeType;
	if ([self isEqual: @"boolean"] || [self isEqual: @"bool"]) return NSBooleanAttributeType;
	if ([self isEqual: @"datetime"] || [self isEqual: @"date"]) return NSDateAttributeType;
	if ([self isEqual: @"double"]) return NSDoubleAttributeType;
	if ([self isEqual: @"currency"] || [self isEqual: @"percent"] || [self isEqual: @"float"]) return NSFloatAttributeType;
	if ([self isEqual: @"int"]) return NSInteger32AttributeType;
	if ([self isEqual: @"base64"] || [self isEqual: @"data"]) return NSBinaryDataAttributeType;
	if ([self isEqual: @"transform"]) return NSTransformableAttributeType;
	
	return NSUndefinedAttributeType;
}

@end
