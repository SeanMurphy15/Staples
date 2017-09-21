//
//  MMSF_DSA_Playlist__c.h
//  ios_dsa
//

#import "MMSF_Object.h"

@class MMSF_Playlist_Content_Junction__c;

@interface MMSF_DSA_Playlist__c : MMSF_Object

@property (nonatomic, readonly) BOOL isFollowedPlaylist;

- (MMSF_Playlist_Content_Junction__c*)junctionForContentVersionId:(NSString*)contentVersionId;

- (void)addJunctionForContentDocumentId:(NSString *)contentDocumentId atIndex:(NSUInteger)index;
- (void)addJunctionForContentVersionId:(NSString *)contentVersionId atIndex:(NSUInteger)index;
- (void)removeJunctionForContentVersionId:(NSString *)contentVersionId;
- (void)removeJunctionForContentDocumentId:(NSString *)contentDocumentId;

+ (MMSF_DSA_Playlist__c*) playlistBySalesforceId:(NSString*) sfid;
+ (NSArray*) followedPlaylists;
@end
