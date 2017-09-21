//
//  NSEntityDescription.h
//  DynamicCoreData
//
//  Created by Ben Gottlieb on 10/2/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

/**************************************************
 *
 *	A subclass of NSEntityDescription with a few convenience
 *	methods for building a model from scratch
 *
 **************************************************/

#define			NOT_UPDATEABLE_KEY				@"NOT_UPDATEABLE"
#define			NOT_CREATABLE_KEY				@"NOT_CREATABLE"


typedef enum {
	mm_oneToManyType_one_to_one,
	mm_oneToManyType_one_to_many,
	mm_oneToManyType_many_to_one
} mm_oneToManyType;

@interface NSEntityDescription (MM)
@property (nonatomic, readonly) NSMutableSet *pendingRelationships;

+ (id) entityDescriptionNamed: (NSString *) name;

- (NSAttributeDescription *) addAttributeNamed: (NSString *) name ofType: (NSAttributeType) type;
- (NSAttributeDescription *) addAttributeNamed: (NSString *) name ofType: (NSAttributeType) type indexed: (BOOL) indexed updateable: (BOOL) updateable createable: (BOOL) createable;
- (NSRelationshipDescription *) addRelationship: (NSString *) name toEntity: (NSEntityDescription *) dest reverseName: (NSString *) reverseName oneToManyType: (mm_oneToManyType) type updateable: (BOOL) updateable createable: (BOOL) createable;
- (void) addPendingRelationship: (NSString *) name to: (NSString *) entityDestinationName backLinkName: (NSString *) backLinkName isToMany: (mm_oneToManyType) type updateable: (BOOL) updateable createable: (BOOL) createable;

- (void) resolvePendingRelationshipsInModel: (NSManagedObjectModel *) model;
- (NSString *) nameForIncomingRelationshipFrom: (NSString *) sourceEntityName;
@end


@interface NSString (NSEntityDescription_MM)
- (NSAttributeType) convertToAttributeType;

@end