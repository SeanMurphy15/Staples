//
//  NSManagedObjectContext+SA_Additions.h
//
//  Created by Ben Gottlieb on 12/23/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <CoreData/CoreData.h>
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#endif

#define kNotification_SA_ErrorWhileGeneratingFetchRequest			@"kNotification_SA_ErrorWhileGeneratingFetchRequest"

typedef void (^managedObjectBlock)(NSManagedObject *object);
typedef void (^contextUpdatedBlock)(NSManagedObjectContext *context, NSString *tag);

extern NSString *kNotification_PersistentStoreResetDueToSchemaChange;

@interface NSManagedObjectContext (SA_ConvenienceAdditions)

@property (nonatomic, readwrite, weak) NSDictionary *primaryStoreMetadata;
@property (nonatomic, strong) NSThread *saveThread;

- (void) setObjectInPrimaryStoreMetadata: (id) object forKey: (id) key;
- (id) objectInPrimaryStoreMetadataForKey: (id) key;
- (NSURL *) primaryStoreURL;
- (NSArray *) objectsWithIDs: (NSArray *) objectIDs;

+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator;
+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator concurrencyType: (int) type;
+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator model: (NSManagedObjectModel *) model concurrencyType: (int) type;
+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator modelPath: (NSString *) modelPath concurrencyType: (int) type;

- (id) copy;
- (id) insertNewEntityWithName: (NSString *) name;
- (id) objectWithIDString: (NSString *) string;

- (NSFetchRequest *) fetchRequestWithEntityName: (NSString *) entityName predicate: (NSPredicate *) predicate sortBy: (NSArray *) sortBy fetchLimit: (int) fetchLimit;
- (id) anyObjectOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate;
- (id) firstObjectOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors;
- (NSArray *) allObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors fetchLimit: (int) fetchLimit;
- (NSArray *) allObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate;
- (NSArray *) allObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors;
- (NSArray *) nObjects: (int) n ofType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors;
- (NSUInteger) numberOfObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate;

- (void) deleteObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate;
- (void) deleteObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate withFetchLimit: (int) fetchLimit;
- (void) save;
- (BOOL) isSaveNecessary;
- (void) saveIfNecessary;
- (void) queueSave;
- (void) queueSaveIn: (float) seconds;
- (void) cancelQueuedSave;
- (Class) classFromEntityName: (NSString *) entityName;
- (NSManagedObjectContext *) createChildContext;
- (void) saveToDisk;		//saves the current context, and all parent contexts, all the way up the chain
- (void) saveOnMainThread;

- (void) unregisterForContextUpdates: (NSString *) tag;
- (void) registerForContextUpdatesUsingBlock: (contextUpdatedBlock) block withTag: (NSString *) tag;
- (void) performBlock: (managedObjectBlock) block withObject: (NSManagedObject *) object onThread: (NSThread *) thread;

#if TARGET_OS_IPHONE
	- (NSFetchedResultsController *) fetchedResultsControllerForEntityNamed: (NSString *) entityName predicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors sectionNameKeyPath: (NSString *) sectionNameKeyPath cacheName: (NSString *) cacheName;
	- (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request inTable: (UITableView *) table withSectionNameKeyPath: (NSString *) sectionKeyPath cacheName: (NSString *) cacheName;
	//- (void) clearFetchedResultsController: (NSFetchedResultsController *) controller;
#endif
@end
