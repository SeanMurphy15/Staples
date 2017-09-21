//
//  DSA_Playlist__c.m
//  ios_dsa
//

#import "MMSF_DSA_Playlist__c.h"
#import "MMSF_ContentVersion.h"
#import "MMSF_Playlist_Content_Junction__c.h"
#import "MMSF_EntitySubscription.h"

@implementation MMSF_DSA_Playlist__c
+ (MMSF_DSA_Playlist__c*) playlistBySalesforceId:(NSString*) sfid {
    //FIXME: should probably pass a context in here
    MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;    
    return [moc anyObjectOfType:@"DSA_Playlist__c" matchingPredicate:[NSPredicate predicateWithFormat:@"Id = %@",sfid]];
}

+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs
{
    
    NSManagedObjectContext  *metaContext = [MM_ContextManager sharedManager].threadMetaContext;
    MM_SFObjectDefinition   *def = [MM_SFObjectDefinition objectNamed:@"DSA_Playlist__c" inContext: metaContext];
    
//    NSManagedObjectContext  *mainContext = [MM_ContextManager sharedManager].threadContentContext;
    
    //Get the Query object from the definition and add the filters
    MM_SOQLQueryString *query = [def baseQueryIncludingData:NO];
//OwnerId = //current_user// OR StaplesDSA__IsFeatured__c = true
    
    [query setPredicate:[MM_SOQLPredicate predicateWithString:@"OwnerId = //current_user//"]];
    [query addOrPredicate:[MM_SOQLPredicate predicateWithString:@"StaplesDSA__IsFeatured__c = true"]];
    NSArray* followedIds = [MMSF_EntitySubscription allParentIds];
    if (followedIds.count)
    {
        [query addOrPredicate:[MM_SOQLPredicate predicateWithFilteredIDs:followedIds forField:@"Id"]];
    }
    return query;
}

- (void)addJunctionForContentDocumentId:(NSString *)contentDocumentId atIndex:(NSUInteger)index {
    MMSF_Playlist_Content_Junction__c *junction = nil;
    
    if(contentDocumentId) {
        MM_ManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
        
        junction = [moc insertNewEntityWithName:[MMSF_Playlist_Content_Junction__c entityName]];
        [junction beginEditing];
        junction[MNSS(@"Playlist__c")] = self;
        junction[MNSS(@"ContentId__c")] = contentDocumentId;
        junction[MNSS(@"Order__c")] = @(index);
        junction[MNSS(@"ExternalId__c")] = [NSString stringWithFormat:@"%@%@", self[@"Id"], contentDocumentId];
        [junction finishEditingSavingChanges:YES];
    }
}

- (void)addJunctionForContentVersionId:(NSString *)contentVersionId atIndex:(NSUInteger)index {
    MMSF_ContentVersion *contentVersion = [MMSF_ContentVersion contentItemBySalesforceId:contentVersionId];
    if(contentVersion) {
        [self addJunctionForContentDocumentId:[contentVersion documentID] atIndex:index];
    }
}

- (MMSF_Playlist_Content_Junction__c*)junctionForContentVersionId:(NSString*)contentVersionId {
    MMSF_Playlist_Content_Junction__c *junction = nil;
    MMSF_ContentVersion *contentVersion = [MMSF_ContentVersion contentItemBySalesforceId:contentVersionId];
    if(contentVersion) {
        NSPredicate *junctionPredicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K = %@", MNSS(@"Playlist__c.Id"), self[@"Id"], MNSS(@"ContentId__c"), [contentVersion documentID]];
        MM_ManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
        junction = [moc anyObjectOfType:[MMSF_Playlist_Content_Junction__c entityName] matchingPredicate:junctionPredicate];
    }

    return junction;
}

- (MMSF_Playlist_Content_Junction__c*)junctionForContentDocumentId:(NSString*)contentDocumentId {
    NSPredicate *junctionPredicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K = %@", MNSS(@"Playlist__c.Id"), self[@"Id"], MNSS(@"ContentId__c"), contentDocumentId];
    MM_ManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    MMSF_Playlist_Content_Junction__c *junction = [moc anyObjectOfType:[MMSF_Playlist_Content_Junction__c entityName] matchingPredicate:junctionPredicate];
    return junction;
}

- (void)removeJunctionForContentVersionId:(NSString *)contentVersionId {
    MMSF_Playlist_Content_Junction__c *junction = [self junctionForContentVersionId:contentVersionId];
    if(junction ) {
        [junction deleteFromSalesforceAndLocal];
    }
}

- (void)removeJunctionForContentDocumentId:(NSString *)contentDocumentId
{
    MMSF_Playlist_Content_Junction__c *junction = [self junctionForContentDocumentId:contentDocumentId];
    if(junction ) {
        [junction deleteFromSalesforceAndLocal];
    }
}

- (BOOL) isFollowedPlaylist
{
    NSArray* subs = [MMSF_EntitySubscription entitySubscriptionsForPlaylist:self];
    return (subs.count > 0);
}

+ (NSArray*) followedPlaylists
{
    MM_ManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    NSArray* playlists = [moc allObjectsOfType:[self entityName] matchingPredicate:nil];
    
    __block NSMutableArray* followedPlaylists = [NSMutableArray arrayWithCapacity:playlists.count];
    [playlists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MMSF_DSA_Playlist__c* playlist = obj;
        if ([playlist isFollowedPlaylist])
        {
            [followedPlaylists addObject:playlist];
        }
    }];
    
    return followedPlaylists;
}
@end
