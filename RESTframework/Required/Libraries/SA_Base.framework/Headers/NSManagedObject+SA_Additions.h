//
//  NSManagedObject+SA_Additions.h
//
//  Created by Ben Gottlieb on 5/25/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObject (NSManagedObject_SA_Additions)

@property (nonatomic, readonly) NSString *objectIDString;
@property (nonatomic, readonly) NSManagedObjectContext *moc;

- (id) objectWithIDString: (NSString *) string;
- (BOOL) didValue: (id) value changeForKey: (NSString *) key;
- (BOOL) hasAttribute: (NSString *) attr;
- (void) deleteFromContext;
- (void) save;

- (void) refreshFromContextMergingChanges: (BOOL) mergeChanges;
- (id) objectInContext: (NSManagedObjectContext *) context;

- (NSAttributeDescription *) descriptionForAttribute: (NSString *) attributeName;
- (NSRelationshipDescription *) descriptionForRelationship: (NSString *) relationshipName;

- (id) objectForKeyedSubscript: (id) key;
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
@end