//
//  ContactsCache.m
//  ios_dsa
//
//  Created by Guy Umbright on 1/24/13.
//
//

#import "ContactsCache.h"
#import "MM_ContextManager.h"
#import "MMSF_Contact.h"

@class ContactsCacheLoader;


@interface ContactsCacheLoader ()
@property (nonatomic, strong) NSManagedObjectContext* context;
@property (nonatomic, strong) NSPredicate* fetchPredicate;
@property (nonatomic, strong) NSFetchRequest* request;
@property (nonatomic, assign) NSUInteger fetchBlockSize;
@property (nonatomic, assign) NSUInteger contactCount;
@property (nonatomic, assign) NSUInteger currentFetchPos;

@property (nonatomic, unsafe_unretained) NSObject<ContactsCacheLoaderDelegate>* delegate;

- (void) startLoad;

@end

@implementation ContactsCacheLoader

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) commonInit
{
    self.fetchPredicate = [NSPredicate predicateWithFormat: @"hasEmail = YES"];
    self.request = [[[NSFetchRequest alloc] initWithEntityName: [MMSF_Contact entityName]] autorelease];
    self.request.resultType = NSDictionaryResultType;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.context];
    
    NSDictionary *entityProperties = [entityDescription propertiesByName];
    
    [self.request setPropertiesToFetch:[NSArray arrayWithObjects:[entityProperties objectForKey:ContactsCacheKey_LastName],
                                        [entityProperties objectForKey:ContactsCacheKey_FirstName],
                                        [entityProperties objectForKey:ContactsCacheKey_Email],
                                        [entityProperties objectForKey:ContactsCacheKey_HasEmail],
                                        [entityProperties objectForKey:ContactsCacheKey_AccountName],
                                        [entityProperties objectForKey:ContactsCacheKey_SalesforceId],
                                        [entityProperties objectForKey:@"objectId"],nil]];
    
    //this value was selected by trying values and find the best performing, so I am leaving this hard-coded here rather
    //than making it a more configurable looking constant so that if you want to change it, you will see this and either
    //think twice or only change it based on performance testing.  And it is tuned for on device.
    self.fetchBlockSize = 60000;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (id) initWithDelegate:(NSObject<ContactsCacheLoaderDelegate>*) delegate
{
    if (self = [super init])
    {
        self.delegate = delegate;
        self.context = [MM_ContextManager sharedManager].contentContextForReading;
        [self commonInit];
    }
    
    return self;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) updateContactCount
{
    NSError* error=nil;
    
    //    NSLog(@"start cc load");
    self.request.predicate = nil;
    self.contactCount = [self.context countForFetchRequest: self.request error: &error];
    
    [self.delegate contactsCacheLoader:self contactCount:self.contactCount];
    
//    self.contacts = [NSMutableArray arrayWithCapacity:self.contactCount];
    self.currentFetchPos = 0;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self requestChunk];
    });
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) requestChunk
{
    NSError* error;
    
    if (self.currentFetchPos < self.contactCount)
    {
        self.request.fetchLimit = self.fetchBlockSize;
        self.request.fetchOffset = self.currentFetchPos;
        
        NSArray* result = [self.context executeFetchRequest: self.request error: &error];
        
        [self.delegate contactsCacheLoader:self contactsLoaded:result];
        
//        for (NSDictionary* dict in result)
//        {
//            if ([[dict objectForKey:ContactsCacheKey_HasEmail] boolValue])
//            {
//                [self.contacts addObject:dict];
//            }
//        }
        
        self.currentFetchPos += self.fetchBlockSize;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self requestChunk];
        });
    }
    else
    {
        [self.delegate contactsCacheLoaderLoadComplete:self];
        //we are done so should do the post processing
//        STATIC_CONSTANT(NSArray, sortBy, $A([NSSortDescriptor SA_descWithKey: ContactsCacheKey_LastName ascending: YES selector:@selector(caseInsensitiveCompare:)],
//                                            [NSSortDescriptor SA_descWithKey: ContactsCacheKey_FirstName ascending: YES selector:@selector(caseInsensitiveCompare:)]));
//        //        NSLog(@"@begin cc sort");
//        [self.contacts sortUsingDescriptors:sortBy];
//        //        NSLog(@"end cc load");
//        
//        self.contactsLoaded = YES;
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.loadInProgress = NO;
//            [[NSNotificationCenter defaultCenter] postNotificationName:ContactsCacheNotification_ContactsLoaded object:self];
//        });
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) startLoad
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateContactCount];});
}
@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ContactsCache () <ContactsCacheLoaderDelegate>

@property (nonatomic, assign) BOOL contactsLoaded;
@property (nonatomic, strong) NSMutableArray* contacts;

@property (nonatomic, copy) NSString* searchTerm;
@property (nonatomic, strong) NSArray* searchContacts;
@property (nonatomic, assign) BOOL searchCompleted;

@property (nonatomic, assign) BOOL loadInProgress;

@property (nonatomic, strong) ContactsCacheLoader* loader;
@end

@implementation ContactsCache

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) commonInit
{
//    self.fetchPredicate = [NSPredicate predicateWithFormat: @"hasEmail = YES"];
//    self.request = [[[NSFetchRequest alloc] initWithEntityName: [MMSF_Contact entityName]] autorelease];
//    self.request.resultType = NSDictionaryResultType;
//    
//    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.context];
//    
//    NSDictionary *entityProperties = [entityDescription propertiesByName];
//    
//    [self.request setPropertiesToFetch:[NSArray arrayWithObjects:[entityProperties objectForKey:ContactsCacheKey_LastName],
//                                        [entityProperties objectForKey:ContactsCacheKey_FirstName],
//                                        [entityProperties objectForKey:ContactsCacheKey_Email],
//                                        [entityProperties objectForKey:ContactsCacheKey_HasEmail],
//                                        [entityProperties objectForKey:ContactsCacheKey_AccountName],
//                                        [entityProperties objectForKey:ContactsCacheKey_SalesforceId],nil]];
//    
//    //this value was selected by trying values and find the best performing, so I am leaving this hard-coded here rather
//    //than making it a more configurable looking constant so that if you want to change it, you will see this and either
//    //think twice or only change it based on performance testing.  And it is tuned for on device.
//    self.fetchBlockSize = 60000;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(loadCache)
                                                 name: kNotification_ObjectReloaded
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(loadCache)
                                                 name: kNotification_ObjectCreated
                                               object: nil];
    
    self.loadInProgress = NO;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (id) init
{
    
    if (self = [super init])
    {
//        self.context = [MM_ContextManager sharedManager].contentContextForReading;
        [self commonInit];
    }
    
    return self;
}

/**
 *
 */
- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kNotification_ObjectReloaded object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: kNotification_ObjectCreated object: nil];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
//- (id) initWithContext:(NSManagedObjectContext*) context
//{
//    if (self = [super init])
//    {
//        self.context = context;
//        [self commonInit];
//    }
//
//    return self;
//}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) loadCacheWithLoader:(ContactsCacheLoader*) loader
{
    if (!self.loadInProgress)
    {
        self.loadInProgress = YES;
        self.contactsLoaded = NO;
        
        self.loader = loader;
        [self.loader startLoad];
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) loadCache
{
    [self loadCacheWithLoader: [[ContactsCacheLoader alloc] initWithDelegate:self]];
}

///////////////////////////////////////////////////////
////
///////////////////////////////////////////////////////
//- (void) updateContactCount
//{
//    NSError* error=nil;
// 
////    NSLog(@"start cc load");
//    self.request.predicate = nil;
//    self.contactCount = [self.context countForFetchRequest: self.request error: &error];
//    self.contacts = [NSMutableArray arrayWithCapacity:self.contactCount];
//    self.currentFetchPos = 0;
//    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self requestChunk];
//    });
//}
//
///////////////////////////////////////////////////////
////
///////////////////////////////////////////////////////
//- (void) requestChunk
//{
//    NSError* error;
//    
//    if (self.currentFetchPos < self.contactCount)
//    {
//        self.request.fetchLimit = self.fetchBlockSize;
//        self.request.fetchOffset = self.currentFetchPos;
//        
//        NSArray* result = [self.context executeFetchRequest: self.request error: &error];
//        
//        for (NSDictionary* dict in result)
//        {
//            if ([[dict objectForKey:ContactsCacheKey_HasEmail] boolValue])
//            {
//                [self.contacts addObject:dict];
//            }
//        }
//        
//        self.currentFetchPos += self.fetchBlockSize;
//        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [self requestChunk];
//        });
//    }
//    else
//    {
//        //we are done so should do the post processing
//        STATIC_CONSTANT(NSArray, sortBy, $A([NSSortDescriptor SA_descWithKey: ContactsCacheKey_LastName ascending: YES selector:@selector(caseInsensitiveCompare:)],
//                                            [NSSortDescriptor SA_descWithKey: ContactsCacheKey_FirstName ascending: YES selector:@selector(caseInsensitiveCompare:)]));
////        NSLog(@"@begin cc sort");
//        [self.contacts sortUsingDescriptors:sortBy];
////        NSLog(@"end cc load");
//        
//        self.contactsLoaded = YES;
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.loadInProgress = NO;
//            [[NSNotificationCenter defaultCenter] postNotificationName:ContactsCacheNotification_ContactsLoaded object:self];
//        });
//    }
//}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) search:(NSString*) searchString
{
    if (searchString.length)
    {
        self.searchCompleted = NO;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //NSDate* started = [NSDate date];
            self.searchTerm = [searchString lowercaseString]; //really needed?
            NSPredicate				*predicate = [NSPredicate predicateWithFormat: @"LastName beginswith[cd] %@ OR FirstName beginswith[cd] %@ OR Email contains[cd] %@", self.searchTerm,self.searchTerm,self.searchTerm];
            
            NSPredicate *firstPredicate = [NSPredicate predicateWithFormat:@"FirstName beginswith[cd] %@", self.searchTerm];
            NSPredicate *lastPredicate = [NSPredicate predicateWithFormat:@"LastName beginswith[cd] %@", self.searchTerm];
            NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"Email contains[cd] %@", self.searchTerm];
            NSPredicate *namePredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                BOOL matched = NO;
                NSString *nameString = [NSString stringWithFormat:@"%@ %@", evaluatedObject[@"FirstName"], evaluatedObject[@"LastName"]];
                NSString *lowerCaseNameString = [nameString lowercaseString];
                matched = [lowerCaseNameString hasPrefix:self.searchTerm];
                return matched;
            }];
            NSPredicate *accountPredicate = [NSPredicate predicateWithFormat:@"AccountName contains[cd] %@", self.searchTerm];
            
            // optimize filter with the simplest first
            NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[firstPredicate, lastPredicate, emailPredicate, namePredicate, accountPredicate]];
            self.searchContacts = [self.contacts filteredArrayUsingPredicate:compoundPredicate];
            self.searchCompleted = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchCompleted = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:ContactsCacheNotification_SearchComplete object:self];
            });
        });
    }
    else
    {
        self.searchCompleted = YES;
        [self clearSearch];
    }
}

#pragma mark external
/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (NSDictionary*) contactAtIndex:(NSUInteger) index
{
    NSDictionary* result=nil;
    
    if (self.contactsLoaded)
    {
        if (index < self.contactCount)
        {
            result = [self.contacts objectAtIndex:index];
        }
    }
    
    return result;
}

/////////////////////////////////////////////////////
// Returns the name and email string to be displayed on contact selection views.
/////////////////////////////////////////////////////

- (NSString*)nameStringForContact:(NSDictionary*)contactDict{

    NSString* s = [contactDict objectForKey:ContactsCacheKey_FirstName];
    NSString *nameString;
    if (s.length == 0)
    {
        nameString = [NSString stringWithFormat:@"%@",[contactDict objectForKey:ContactsCacheKey_LastName]];
    }
    else
    {
        nameString = [NSString stringWithFormat:@"%@ %@",s,[contactDict objectForKey:ContactsCacheKey_LastName]];
    }
   
    return ([NSString stringWithFormat:@"%@ <%@>",nameString,[contactDict objectForKey:ContactsCacheKey_Email]?:NSLocalizedString(@"NO_EMAIL_ADDRESS_MESSAGE", nil)]);
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (NSDictionary*) searchContactAtIndex:(NSUInteger) index
{
    NSDictionary* result=nil;
    
    if (self.searchContacts)
    {
        if (self.searchCompleted)
        {
            if (index < self.searchContacts.count)
            {
                result = [self.searchContacts objectAtIndex:index];
            }
        }
    }
    else
    {
        result = [self contactAtIndex:index];
    }
    
    return result;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) clearSearch
{
    self.searchCompleted = NO;
    self.searchContacts = nil;
    self.searchTerm = nil;
}

#pragma mark properties
/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (NSUInteger) searchContactCount
{
    NSUInteger result = 0;
    
    if (self.searchContacts && self.searchCompleted)
    {
        result = self.searchContacts.count;
    }
    else
    {
        result = self.contactCount;
    }
    return result;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (NSUInteger) contactCount
{
    return self.contacts.count;
}

#pragma mark ContactsCacheLoaderDelegate
/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) contactsCacheLoader:(ContactsCacheLoader*)loader contactCount:(NSUInteger) count
{
    self.contacts = [NSMutableArray arrayWithCapacity:count];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) contactsCacheLoader:(ContactsCacheLoader*)loader contactsLoaded:(NSArray*) loadedContacts
{
    for (NSDictionary* dict in loadedContacts)
    {
        [self.contacts addObject:dict];
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) contactsCacheLoaderLoadComplete:(ContactsCacheLoader*)loader
{
    STATIC_CONSTANT(NSArray, sortBy, $A([NSSortDescriptor SA_descWithKey: ContactsCacheKey_LastName ascending: YES selector:@selector(caseInsensitiveCompare:)],
                                        [NSSortDescriptor SA_descWithKey: ContactsCacheKey_FirstName ascending: YES selector:@selector(caseInsensitiveCompare:)]));
    //        NSLog(@"@begin cc sort");
    [self.contacts sortUsingDescriptors:sortBy];
    //        NSLog(@"end cc load");
    
    self.contactsLoaded = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadInProgress = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:ContactsCacheNotification_ContactsLoaded object:self];
    });
    
    self.loader = nil;
}
@end
