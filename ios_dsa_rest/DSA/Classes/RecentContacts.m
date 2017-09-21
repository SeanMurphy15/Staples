//
//  RecentContacts.m
//  ios_dsa
//
//  Created by Guy Umbright on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RecentContacts.h"

#define MAX_ENTRIES 25
#define SAVE_FILE_NAME @"RecentContacts.save"
#define ARCHIVER_KEY @"recentContacts"

#define CoderKey_ObjectIdURI @"objectidURI"
#define CoderKey_DateAdded      @"dateadded"
#define CoderKey_DateLastReferenced  @"datelastreferenced"

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
@implementation RecentContact

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil)
    {
        self.objectIDURI = [decoder decodeObjectForKey:CoderKey_ObjectIdURI];
        self.dateAdded = [decoder decodeObjectForKey:CoderKey_DateAdded];
        self.dateLastReferenced = [decoder decodeObjectForKey:CoderKey_DateLastReferenced];
    }
    return self;
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.objectIDURI forKey:CoderKey_ObjectIdURI];
    [encoder encodeObject:self.dateAdded forKey:CoderKey_DateAdded];
    [encoder encodeObject:self.dateLastReferenced forKey:CoderKey_DateLastReferenced];
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
@end

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
@implementation RecentContacts


///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void) loadRecentContacts
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    NSString* path = [basePath stringByAppendingPathComponent:SAVE_FILE_NAME];

    NSData* data = [NSData dataWithContentsOfFile:path];
    if (data == nil)
    {
        recentContacts = [NSMutableDictionary dictionary];
    }
    else
    {
    NSKeyedUnarchiver* archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    recentContacts = [archiver decodeObjectForKey:ARCHIVER_KEY];
        
    [archiver finishDecoding];
    }
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void) saveRecentContacts
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    NSString* path = [basePath stringByAppendingPathComponent:SAVE_FILE_NAME];


	NSMutableData* data = [NSMutableData data];
	NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
	[archiver encodeObject:recentContacts forKey:ARCHIVER_KEY];
	
	[archiver finishEncoding];
    
    NSError* err = nil;
    [data writeToFile:path 
              options:0
                error:&err];
    NSAssert(err == nil,@"recentContacts write failed");
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (id) init
{
    self = [super init];
    if (self != nil)
    {
        [self loadRecentContacts];
    }
    return self;
}


///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void) addContact:(MMSF_Contact*) contact
{
    RecentContact* recent = [recentContacts objectForKey:[contact.objectID URIRepresentation]];
    if (recent == nil)
    {
        recent = [[[RecentContact alloc] init] autorelease];
        recent.objectIDURI = [[contact objectID] URIRepresentation];
        recent.dateAdded = [NSDate date];
        recent.dateLastReferenced = recent.dateAdded;
        
        [recentContacts setObject:recent forKey:[[contact objectID] URIRepresentation]];
        if ([recentContacts count] > MAX_ENTRIES)
        {
            NSSortDescriptor* sd = [NSSortDescriptor sortDescriptorWithKey:@"dateLastReferenced" 
                                                                 ascending:YES];
            
            NSArray* sortResult = [[recentContacts allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
            RecentContact* oldest = [sortResult objectAtIndex:0];
            [recentContacts removeObjectForKey:oldest.objectIDURI];
        }
    }
    else
    {
        recent.dateLastReferenced = [NSDate date];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{[self saveRecentContacts];});    
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (NSArray*) sortedContacts		//FIXME: pass in a context
{
    
    NSMutableArray* contacts = [NSMutableArray arrayWithCapacity:[recentContacts count]];
    MMSF_Contact* contact;
	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
 
    for (RecentContact* rc in [recentContacts allValues])
    {
        contact = [moc objectWithIDString:[[rc objectIDURI] absoluteString]] ;
        
        if (contact != nil)
        {
            [contacts addObject:contact];
            
        }
    }
    
    return [contacts sortedArrayUsingDescriptors:[NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"lastName" 
                                                                                                          ascending:YES],
                                                  [NSSortDescriptor sortDescriptorWithKey:@"firstName" 
                                                                                ascending:YES],nil]];
    
}@end
