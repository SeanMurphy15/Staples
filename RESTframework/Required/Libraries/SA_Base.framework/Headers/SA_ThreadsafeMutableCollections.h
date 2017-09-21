//
//  SA_ThreadsafeMutableCollections.h
//
//  Created by Ben Gottlieb on 5/3/14.
//
//

#import <Foundation/Foundation.h>

typedef void (^simpleMutableArrayBlock)(NSMutableArray *array);
typedef void (^simpleMutableDictionaryBlock)(NSMutableDictionary *dictionary);
typedef void (^simpleMutableSetBlock)(NSMutableSet *set);


@interface SA_ThreadsafeMutableArray : NSObject <NSFastEnumeration>
+ (instancetype) array;
+ (instancetype) arrayWithObject: (id) object;

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len;
- (id) objectAtIndexedSubscript: (NSUInteger) idx;
- (void) setObject: (id) object atIndexedSubscript: (NSUInteger) idx;
- (void) addObject: (id) object;
- (void) removeObject: (id) object;
- (id) firstObject;
- (id) lastObject;
- (void) removeAllObjects;
- (void) safelyAccessInBlock: (simpleMutableArrayBlock) block;

@property (nonatomic, readonly) NSArray *allObjects;
@property (nonatomic, readonly) NSUInteger count;

@end



@interface SA_ThreadsafeMutableSet : NSObject <NSFastEnumeration>
+ (instancetype) set;

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len;
- (void) addObject: (id) object;
- (void) removeObject: (id) object;
- (void) removeAllObjects;
- (void) safelyAccessInBlock: (simpleMutableSetBlock) block;

@property (nonatomic, readonly) NSArray *allObjects;
@property (nonatomic, readonly) NSUInteger count;

@end



@interface SA_ThreadsafeMutableDictionary : NSObject <NSFastEnumeration>
+ (instancetype) dictionary;

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len;
- (id) objectForKeyedSubscript: (id) key;
- (id) objectForKey: (id) key;
- (void) setObject: (id) obj forKeyedSubscript: (id <NSCopying>) key;
- (void) setObject: (id) object forKey: (id <NSCopying>) key;
- (void) removeObjectForKey: (id) key;
- (void) safelyAccessInBlock: (simpleMutableDictionaryBlock) block;

@property (nonatomic, readonly) NSArray *allObjects;
@property (nonatomic, readonly) NSUInteger count;

@end

