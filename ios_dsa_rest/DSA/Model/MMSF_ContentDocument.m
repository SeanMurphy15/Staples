//
//  MMSF_ContentDocument.m
//  ios_dsa
//
//  Created by Guy Umbright on 11/20/12.
//
//

#import "MMSF_ContentDocument.h"

@implementation MMSF_ContentDocument

@dynamic publishStatus;

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (NSInteger) countOfPersonalContent
{
    NSFetchRequest* request = [[[NSFetchRequest alloc] initWithEntityName: [MMSF_ContentDocument entityName]] autorelease];
    NSPredicate* fetchPredicate = [NSPredicate predicateWithFormat: @"PublishStatus = 'R'"];
    request.predicate = fetchPredicate;
    
    NSError* error;
    
    return [[MM_ContextManager sharedManager].contentContextForReading countForFetchRequest: request error: &error];
}

+ (NSArray*)personalLibraryContentDocuments {
    //NSPredicate* pred = [NSPredicate predicateWithFormat: @"PublishStatus = 'R'"];
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].contentContextForReading;
    NSArray *contentDocs = [moc allObjectsOfType:[MMSF_ContentDocument entityName] matchingPredicate: nil];
    
    return contentDocs;
}

@end
