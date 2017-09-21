//
//  DSA_ContentShelvesModel.h
//  DSA
//
//  Created by Mike Close on 7/6/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSA_ContentShelvesConfig.h"

@class MMSF_ContentVersion;
@class DSA_ContentShelfModel;
@class MMSF_DSA_Playlist__c;

@protocol DSAContentShelvesModelDelegate

@optional
- (NSArray *)itemIdsForSpecialShelf:(NSString *)configurationId;

@required
- (void)reloadData;
- (void)insertSections:(NSIndexSet *)sections;
- (BOOL)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (BOOL)deleteItemsAtIndexPaths:(NSArray *)indexPaths;

@end

@interface DSA_ContentShelvesModel : NSObject

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(DSA_ContentShelvesModel, sharedModel);

/**
 * The filename to use when saving the shelf config.
 **/
@property (strong, nonatomic) DSA_ContentShelvesConfig *config;

@property (weak, nonatomic) NSObject<DSAContentShelvesModelDelegate> *delegate;

@property (nonatomic, copy) NSString *state;

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canInsertItem:(NSString *)itemId atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canMoveItem:(NSString *)itemId fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath updateLayout:(BOOL)updateLayout animated:(BOOL)animated;
- (void)insertItem:(NSString *)itemId atIndexPath:(NSIndexPath *)indexPath updateLayout:(BOOL)updateLayout animated:(BOOL)animated;
- (void)moveItem:(NSString *)itemId fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath updateLayout:(BOOL)updateLayout animated:(BOOL)animated;
- (NSString *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void)setItems:(NSArray *)items forSpecialShelf:(NSString *)configurationId;
- (MMSF_ContentVersion*)contentItemById:(NSString *)itemId;
- (BOOL)deleteContentItemById:(NSString *)itemId;
- (MMSF_ContentVersion *)contentItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)synchronizePlaylistsAndShelves;
- (void)addJunctionForItemId:(NSString*)itemId atIndexPath:(NSIndexPath*)indexPath;
- (void)removeJunctionForItemId:(NSString*)itemId atShelfIndex:(int)index;

/**
 * The current state of the Content shelf interface, either kContentShelvesStateEdit or kContentShelvesStateNormal.
 **/
+ (NSString *)state;

/**
 * A convenience method for retrieving the DSA_ContentShelfModel instance that is exists at a particular index.
 **/
- (DSA_ContentShelfModel *)shelfAtIndex:(NSUInteger)shelfIndex;
- (DSA_ContentShelfModel *)addableShelfAtIndex:(NSUInteger)shelfIndex;

/**
 * A convenience method for retrieving the shelf count.
 **/
- (NSUInteger)shelfCount;
- (NSUInteger)addableShelfCount;

/**
 * A convenience method for retrieving the names of all of the shelves as an array of strings.
 **/
- (NSArray *)shelfNames;
- (NSArray *)addableShelfNames;

/**
 * A convenience method for determining whether or not a particular content item is on a particular shelf.
 **/
- (BOOL)contentItemId:(NSString *)itemId isOnShelfNamed:(NSString*)shelfName;

/**
 * A convenience method for retrieving the name of the shelf at a particular index.
 **/
- (NSString *)shelfNameForIndex:(NSUInteger)index;
- (NSString *)addableShelfNameForIndex:(NSUInteger)index;

/**
 * Creates a new shelf
 **/
- (DSA_ContentShelfModel *)createShelfNamed:(NSString *)name updateLayout:(BOOL)updateLayout animated:(BOOL)animated;

/**
 * Deletes a shelf by reference.
 **/
- (void)deleteShelf:(DSA_ContentShelfModel *)shelf;

/**
 * Renames a shelf.
 **/
- (BOOL)renameShelf:(NSString*)originalName to:(NSString*)newName;

/**
 * Adds a content item (by id) to a shelf (by name)
 **/
- (BOOL)addContentItemId:(NSString *)itemId toShelf:(NSString *)name updateLayout:(BOOL)updateLayout animated:(BOOL)animated;

/**
 * Removes a content item from all shelves.
 **/
//- (BOOL)removeContentItemId:(NSString *)itemId updateLayout:(BOOL)updateLayout animated:(BOOL)animated;

@end





@interface DSA_ContentShelfModel : NSObject

@property (weak, nonatomic) id<DSAContentShelvesModelDelegate> delegate;

/**
 * The configuration object for this shelf.
 **/
@property (nonatomic, strong) DSA_ContentShelfConfig *shelfConfig;

/**
 * Transient value, set when the shelf is assigned to a cell, header, or background. Lets the item renderers know their current index.
 **/
@property (nonatomic) NSUInteger shelfIndex;

/**
 * The name of the shelf.
 **/
@property (nonatomic, copy) NSString *shelfName;

/**
 * An array of MMSF_ContentVersion Ids, representing the list of content on the shelf.
 **/
@property (nonatomic, strong) NSMutableArray *itemIds;

/**
 * Playlist associated with shelf, if any.
 **/
@property (nonatomic, copy) NSString *playlistId;

@property (nonatomic, weak) MMSF_DSA_Playlist__c *playlist;

- (instancetype)initWithPlaylist:(MMSF_DSA_Playlist__c*)playlist;
- (instancetype)initWithShelfName:(NSString*)shelfName;

- (BOOL)canInsertItem:(NSString *)itemId atIndex:(NSUInteger)index showPersonalShelfAlert:(BOOL)showPersonalShelfAlert;
- (BOOL)canDeleteItemAtIndex:(NSUInteger)index;
- (void)insertItem:(NSString *)itemId atIndex:(NSUInteger)index updateLayout:(BOOL)updateLayout animated:(BOOL)animated showPersonalShelfAlert:(BOOL)showPersonalShelfAlert;
- (void)deleteItemAtIndex:(NSUInteger)index updateLayout:(BOOL)updateLayout animated:(BOOL)animated;
- (BOOL)addContentItemId:(NSString *)itemId updateLayout:(BOOL)updateLayout animated:(BOOL)animated;
- (BOOL)removeContentItemId:(NSString *)itemId updateLayout:(BOOL)updateLayout animated:(BOOL)animated;
- (void)moveItem:(NSString *)itemId fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex updateLayout:(BOOL)updateLayout animated:(BOOL)animated showPersonalShelfAlert:(BOOL)showPersonalShelfAlert;
- (NSString *)itemAtIndex:(NSUInteger)index;
- (MMSF_ContentVersion*)contentItemAtIndex:(NSUInteger)index;
- (BOOL)deleteContentItemAtIndex:(NSUInteger)index;
- (NSUInteger)itemCount;
- (BOOL)containsItemId:(NSString *)itemId;
- (BOOL)isEmpty;
- (void)orderJunctions;
- (void)addJunctionForItemId:(NSString*)itemId;
- (void)removeJunctionForItemId:(NSString*)itemId;

//- (BOOL) canDeleteItemsFromShelf;
//- (BOOL) canAddItemsToShelf;
- (BOOL) canModifyShelf;

@end


// Notification Names
extern NSString *const kNotification_ContentShelfCreated;
extern NSString *const kNotification_ContentShelfDeleted;
extern NSString *const kNotification_ContentShelfItemDeleted;
extern NSString *const kNotification_ContentShelfItemCreated;
extern NSString *const kNotification_ContentShelvesStateChanged;

extern NSString *const kContentShelfConfiguration_PersonalLibrary;
extern NSString *const kContentShelfConfiguration_Default;
extern NSString *const kPersonalLibraryTitle;

extern NSInteger const kShelfNameMaxLength;

// Shelf States
extern NSString *const kContentShelvesStateEdit;
extern NSString *const kContentShelvesStateNormal;


