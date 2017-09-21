//
//  ContactsCache.h
//  ios_dsa
//
//  Created by Guy Umbright on 1/24/13.
//
//

// Usage
//
// Some of the stuff here (the ContactsCache/ContactsCacheLoader split) is primarly to facilitate
// testing.
//
// For normal usage you really only need to do
//
// ContactsCache* cache = [[ContactsCache alloc] init];
// [cache loadCache];
//
// and catch the ContactsLoaded notification to know when its done.

#import <Foundation/Foundation.h>

@class ContactsCacheLoader;

@protocol ContactsCacheLoaderDelegate
- (void) contactsCacheLoader:(ContactsCacheLoader*)loader contactCount:(NSUInteger) count;
- (void) contactsCacheLoader:(ContactsCacheLoader*)loader contactsLoaded:(NSArray*) contacts;
- (void) contactsCacheLoaderLoadComplete:(ContactsCacheLoader*)loader;
@end

@interface ContactsCacheLoader : NSObject
- (id) initWithDelegate:(NSObject<ContactsCacheLoaderDelegate>*) delegate;
- (void) startLoad;
@end

#define ContactsCacheNotification_ContactsLoaded @"ContactsCacheNotification_ContactsLoaded"
#define ContactsCacheNotification_SearchComplete @"ContactsCacheNotification_SearchComplete"

#define ContactsCacheKey_LastName @"LastName"
#define ContactsCacheKey_FirstName @"FirstName"
#define ContactsCacheKey_Email @"Email"
#define ContactsCacheKey_HasEmail @"hasEmail"
#define ContactsCacheKey_AccountName @"AccountName"
#define ContactsCacheKey_SalesforceId @"Id"

@interface ContactsCache : NSObject <ContactsCacheLoaderDelegate>

- (void) loadCache;
- (void) loadCacheWithLoader:(ContactsCacheLoader*) loader;  
- (void) search:(NSString*) searchString;
- (NSString*)nameStringForContact:(NSDictionary*)contactDict;

@property (nonatomic, readonly) NSUInteger contactCount;
@property (nonatomic, readonly) NSUInteger searchContactCount;

- (id) init;  //uses [MM_ContextManager sharedManager].contentContextForReading;
//- (id) initWithContext:(NSManagedObjectContext*) context;

- (NSDictionary*) contactAtIndex:(NSUInteger) index;
- (NSDictionary*) searchContactAtIndex:(NSUInteger) index;
- (void) clearSearch;

@end
