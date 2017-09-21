//
//  NSArray+SA_Additions.h
//
//  Created by Ben Gottlieb on 3/8/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+SA_Additions.h"

@class NSPredicate;

@interface NSArray (NSArray_SA_Additions)
@property (nonatomic, readonly) NSUInteger SA_md5Hash;

- (NSArray *) subarrayWithObjectsSatisfyingPredicate: (NSPredicate *) pred;
- (NSUInteger) indexOfFirstObjectMatchingPredicate: (NSPredicate *) pred;
- (id) firstObjectMatchingPredicate: (NSPredicate *) pred;

- (NSArray *) arrayWithIndexesFromSet: (NSIndexSet *) indexeSet;
//- (NSMutableArray *) deepMutableCopy;
- (NSArray *) SA_randomizedCopy;
- (NSArray *) arrayWithCollectedResultsOfMethod: (SEL) method;
- (NSArray *) arrayWithCollectedResultsOfBlock: (idArgumentBlockReturningID) block;
- (NSUInteger) countObjectsOfClass: (Class) classToCount;
- (NSArray *) arrayWithReversedObjects;
- (id) SA_anyRandomObject;
- (id) SA_previousObjectRelativeTo: (id) object;
- (id) SA_nextObjectRelativeTo: (id) object;
- (id) SA_firstObject;
- (NSArray *) SA_arrayByRemovingObject: (id) object;
- (NSString *) SA_checksumString;
- (void) map: (idArgumentBlock) block;
@end
