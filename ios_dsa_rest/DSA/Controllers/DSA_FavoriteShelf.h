#import <Foundation/Foundation.h>

@class MMSF_ContentVersion;

#define kNotification_FavoriteShelfCreated			@"FavoriteShelfCreated"
#define kNotification_FavoriteShelfDeleted			@"FavoriteShelfDeleted"
#define kNotification_FavoriteShelfRenamed			@"FavoriteShelfRenamed"
#define kNotification_FavoriteAssigned				@"FavoriteShelfAssigned"
#define kNotification_FavoriteItemDeleted           @"FavoriteItemDeleted"
#define kNotification_FavoriteItemCreated           @"FavoriteItemCreated"

@interface DSA_FavoriteShelf : NSObject {

}

+ (NSArray *) favoritesForItem: (MMSF_ContentVersion *) item;
+ (BOOL) createShelfNamed: (NSString *) name;
+ (NSArray *) allShelfNames;
+ (void) setFavoriteShelves: (NSSet *) shelves forItem: (MMSF_ContentVersion *) item;
+ (NSArray *) itemsForShelfName: (NSString *) shelf;

+ (void) deleteShelf: (NSString *) shelfName;
+ (void) addContentItem: (MMSF_ContentVersion *) item toShelf: (NSString *) name;
+ (void) removeContentItem: (MMSF_ContentVersion *) item fromShelf: (NSString *) name;
+ (BOOL) isItemFavorited: (MMSF_ContentVersion *) item;
+ (void) removeContentItem: (MMSF_ContentVersion *) item;
+ (BOOL) contentItem:(MMSF_ContentVersion*) item isOnShelfNamed:(NSString*) shelfName;
+ (BOOL) renameShelf:(NSString*) originalName to:(NSString*) newName;
@end
