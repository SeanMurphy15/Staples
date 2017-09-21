//
//  MMSF_Contact.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Contact.h"
#import "MMSF_Object.h"
#import "MM_ContextManager.h"
#import "MM_RestOperation.h"
#import "MM_SFObjectDefinition.h"

@implementation MMSF_Contact
@dynamic LastModifiedDate;
@dynamic Name;
@dynamic FirstName;
@dynamic LastName;
@dynamic Email;
@dynamic OwnerId;
@dynamic AccountId;
@dynamic Phone;

- (id) importRecord: (NSDictionary *) record includingDataBlobs: (BOOL) includingDataBlobs
{
    MMSF_Object		*result = [super importRecord: record includingDataBlobs:includingDataBlobs];
    
    NSString* email = [record objectForKey:@"Email"];
    BOOL hasEmail = (email != nil && (email != (NSString*)[NSNull null]) && email.length > 0);
    [self setValue:[NSNumber numberWithBool:hasEmail] forKey:@"hasEmail"];
	
	return result;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (NSInteger) countOfContactsWithEmail
{
    NSFetchRequest* request = [[[NSFetchRequest alloc] initWithEntityName: [MMSF_Contact entityName]] autorelease];
    NSPredicate* fetchPredicate = [NSPredicate predicateWithFormat: @"hasEmail = YES"];
    request.predicate = fetchPredicate;
    
    NSError* error;
    
    return [[MM_ContextManager sharedManager].contentContextForReading countForFetchRequest: request error: &error];
}

+ (void) syncWithQuery: (MM_SOQLQueryString *) query {
	MM_SOQLQueryString		*query1 = [MM_SOQLQueryString queryWithObjectName: @"Contact"];
	MM_SOQLQueryString		*query2 = [MM_SOQLQueryString queryWithObjectName: @"Contact"];
	MMSF_Object				*user = [MM_SyncManager currentUserInContext: nil];
	id						userID = [user valueForKey: @"Id"];
	NSMutableSet			*currentRecordIDs;
	
	//get all existing contact IDs
	
	@autoreleasepool {
		NSManagedObjectContext	*moc = [MM_ContextManager sharedManager].contentContextForReading;
		currentRecordIDs = [NSMutableSet setWithArray: [[moc allObjectsOfType: [self entityName] matchingPredicate: nil] valueForKey: @"Id"]];
	}
	
	query1.fields = query.fields;
	query1.predicate = query.predicate;
	query1.shouldSearchForExistingRecordsWhenImporting = true;
	
	query2.fields = query.fields;
	query2.predicate = [MM_SOQLPredicate predicateWithString: $S(@"AccountId IN (SELECT AccountId from AccountTeamMember where UserID = '%@') AND Active__c = 'Yes'", userID)];
	query2.shouldSearchForExistingRecordsWhenImporting = true;

	for (MM_SOQLQueryString *q in @[ query1, query2 ]) {
		MM_RestOperation	*op = [MM_RestOperation operationWithQuery: q
																  groupTag: nil
														   completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
															   query.shouldSearchForExistingRecordsWhenImporting = true;
															   [[MM_SFObjectDefinition objectNamed: @"Contact" inContext: nil] parseJSONResponse: json forQuery: query headerDate: nil withError: error completion: nil];
															   
															   //remove newly downloaded IDs from our list of current IDs
															   NSArray		*newIDs = [json[@"records"] valueForKey: @"Id"];
															   
															   [currentRecordIDs minusSet: [NSSet setWithArray: newIDs]];
															   if (q == query2) {
																   //now we can remove any contacts that are no longer visible to us.
																   NSManagedObjectContext	*moc = [MM_ContextManager sharedManager].contentContextForWriting;
																   NSPredicate		*pred = [NSPredicate predicateWithFormat: @"%@ contains Id", currentRecordIDs];
																   NSArray			*orphans = [moc allObjectsOfType: [MMSF_Contact entityName] matchingPredicate: pred];
																   
																   for (MMSF_Contact *contact in orphans) {
																	   [contact deleteFromContext];
																   }
																   [moc save];
															   }
															   
															   return NO;
														   }
														  sourceTag: @""];
		[[MM_SyncManager sharedManager] queueOperation: op];
	}
	
}

@end
