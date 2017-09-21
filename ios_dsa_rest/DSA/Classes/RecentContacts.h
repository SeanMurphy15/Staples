//
//  RecentContacts.h
//  ios_dsa
//
//  Created by Guy Umbright on 6/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMSF_Contact.h"


///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
@interface RecentContact : NSObject <NSCoding>
{
}

@property (nonatomic, strong) NSURL* objectIDURI;
@property (nonatomic, strong) NSDate* dateAdded;
@property (nonatomic, strong) NSDate* dateLastReferenced;

@end

///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
@interface RecentContacts : NSObject 
{
    //keyed by sfid
    NSMutableDictionary* recentContacts;
}

- (void) addContact:(MMSF_Contact*) contact;
- (NSArray*) sortedContacts;
@end
