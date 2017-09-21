//
//  NSManagedObjectModel+MM.h
//  DynamicCoreData
//
//  Created by Ben Gottlieb on 10/2/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

/**************************************************
 *
 *	A subclass of NSManagedObjectModel with a few convenience
 *	methods for building a model from scratch
 *
 *	Also handles migrating an existing database when the underlying
 *	model has changed
 *
 **************************************************/


@interface NSManagedObjectModel (MM)

+ (id) createModel;
+ (id) modelWithContentsOfFile: (NSString *) path;
- (void) addEntities: (NSEntityDescription *) entity, ...;
- (NSManagedObjectContext *) generateContextAtPath: (NSString *) path ofType: (NSInteger) type;
- (void) writeToFile: (NSString *) path;
+ (id) modelWithObjects: (NSArray *) objects;
- (BOOL) attemptMigrationOfContextAtPath: (NSString *) contextPath fromOldModel: (NSManagedObjectModel *) oldModel;
- (NSEntityDescription *) entityDescriptionNamed: (NSString *) name;
- (void) resolveAllPendingRelationships;
@end

@interface NSManagedObjectContext (MM)
- (id) objectWithRobustIDString: (NSString *) robustIDString;
@end


@interface NSManagedObject (MM)
@property (readonly) NSString *robustIDString, *generatedMMID;

+ (void) clearRobustObjectIDs;
+ (void) cleanUpRobustObjectIDCache;
+ (void) saveRobustObjectIDsCache;
+ (void) loadRobustObjectIDsCache;
@end
