//
//  DSA_ContentShelvesModel.m
//  DSA
//
//  Created by Mike Close on 7/6/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelvesModel.h"
#import "MMSF_ContentVersion.h"
#import "MMSF_User.h"
#import "MMSF_DSA_Playlist__c.h"
#import "MMSF_Playlist_Content_Junction__c.h"


#define kShelvesDictPath [@"~/Library/" stringByExpandingTildeInPath]

@interface DSA_ContentShelvesModel()
@property (nonatomic, strong) NSMutableArray        *displayShelves;
@property (nonatomic, strong) NSMutableArray        *rawShelves;
@property (nonatomic, strong) NSMutableArray        *addableShelves;
@property (nonatomic, strong) NSString              *contentFilter;
@property (nonatomic, strong) NSMutableDictionary   *contentItems;
@property (nonatomic) BOOL isAlertShown;

@property (nonatomic, strong) NSArray *playlistIdArray;

@end

@implementation DSA_ContentShelvesModel

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(DSA_ContentShelvesModel, sharedModel);

+ (NSString *)state {
    return [DSA_ContentShelvesModel sharedModel].state;
}

- (id)init {
    if (self = [super init]) {
        [self setupNotifications];
        _state = kContentShelvesStateNormal;
    }
    
    return self;
}

- (void)setConfig:(DSA_ContentShelvesConfig *)config {
    if (config == _config) return;
    _config = config;
    
    [self loadShelves];
}

- (void)setContentItems:(NSMutableDictionary *)contentItems {
    _contentItems = contentItems;
}

- (void)setupNotifications {
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter addObserver:self selector:@selector(afterShelfChange:) name:kNotification_ContentShelfItemCreated object:nil];
    [noteCenter addObserver:self selector:@selector(afterShelfChange:) name:kNotification_ContentShelfItemDeleted object:nil];
    [noteCenter addObserver:self selector:@selector(noticeContentChanged:) name:kNotification_SyncComplete object:nil];
    [noteCenter addObserver:self selector:@selector(noticeContentChanged:) name:kDSAInternalModeNotificationKey object:nil];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Shelves Collection Modification Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (DSA_ContentShelfModel *)createShelfNamed:(NSString *)name updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    name = [name uppercaseString];
	if (name.length == 0) {
        [self showAlertWithTitle:@"Shelf name cannot be empty" message:@"Please enter a shelf name."];
		return nil;
	}
    
    if (name.length > kShelfNameMaxLength) {
        [self showAlertWithTitle:@"Shelf name too long" message:@"Shelf name must be less than 80 characters"];
        return nil;
    }
    
	if ([self rawShelfNamed:name] != nil) {
		[self showAlertWithTitle:@"A shelf with this name already exists" message:@"Please enter a different name."];
		return [self rawShelfNamed:name];
	}
	
    DSA_ContentShelfModel *newShelf = [[DSA_ContentShelfModel alloc] initWithShelfName:name];
    newShelf.shelfConfig = self.config.defaultShelfConfig;
    
	[self.rawShelves addObject:newShelf];
    if (animated) {
        [[self delegate] insertSections:[NSIndexSet indexSetWithIndex:[[self indexOfShelfNamed:[newShelf shelfName]] integerValue]]];
    }
    else {
        [self.delegate reloadData];
    }
    
    self.addableShelves = nil;
    [self commitChanges];
    if (updateLayout)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ContentShelfCreated object: name];
    }
    
    return newShelf;
}

- (void)deleteShelf:(DSA_ContentShelfModel *)shelf {
    // remove from shelf array
    [self.rawShelves removeObject:shelf];
    self.addableShelves = nil;
    [self commitChanges];
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ContentShelfDeleted object:[shelf shelfName]];
}

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    DSA_ContentShelfModel *shelf = [self shelfAtIndex:indexPath.section];
    [shelf deleteItemAtIndex:indexPath.item updateLayout:updateLayout animated:animated];
}

- (void)insertItem:(NSString *)itemId atIndexPath:(NSIndexPath *)indexPath updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    DSA_ContentShelfModel *shelf = [self shelfAtIndex:indexPath.section];
    
    [shelf insertItem:itemId atIndex:indexPath.item updateLayout:updateLayout animated:animated showPersonalShelfAlert:![[[shelf shelfConfig] configurationId] isEqualToString:kContentShelfConfiguration_PersonalLibrary]];
}

- (void)setItems:(NSArray *)items forSpecialShelf:(NSString *)configurationId {
    __block NSUInteger shelfIndex = 0;
    [[[self config] customShelfConfigs] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(DSA_ContentShelfConfig*)obj configurationId] isEqualToString:configurationId]) {
            shelfIndex = [(DSA_ContentShelfConfig*)obj shelfIndex];
            *stop = YES;
        }
    }];
    DSA_ContentShelfModel *shelfModel = [self shelfAtIndex:shelfIndex];
    [shelfModel setItemIds:[items mutableCopy]];
}

- (void)moveItem:(NSString *)itemId fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    NSLog(@"f: %@ -> t:%@",fromIndexPath,toIndexPath);
    if (fromIndexPath.section == toIndexPath.section) {
        [[self shelfAtIndex:fromIndexPath.section] moveItem:itemId fromIndex:fromIndexPath.item toIndex:toIndexPath.item updateLayout:updateLayout animated:animated showPersonalShelfAlert:toIndexPath.section != 0];
    } else {
        [self insertItem:itemId atIndexPath:toIndexPath updateLayout:updateLayout animated:animated];
        [self deleteItemAtIndexPath:fromIndexPath updateLayout:updateLayout animated:animated];
    }
}

- (BOOL)addContentItemId:(NSString *)itemId toShelf:(NSString *)name updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    DSA_ContentShelfModel *shelf = [self rawShelfNamed:name];
    if (shelf == nil) {
        [self createShelfNamed:name updateLayout:NO animated:NO];
        shelf = [self rawShelfNamed:name];
    }
    if ([shelf canInsertItem:itemId atIndex:[shelf itemCount] showPersonalShelfAlert:YES]) {
        [shelf insertItem:itemId atIndex:[shelf itemCount] updateLayout:updateLayout animated:animated showPersonalShelfAlert:YES];
        return YES;
    }
    return NO;
}

- (BOOL)renameShelf:(NSString*)originalName to:(NSString*)newName {
    BOOL renamed = NO;
    
    DSA_ContentShelfModel *shelf = [self rawShelfNamed:originalName];
    if (shelf) {
        shelf.shelfName = newName;
        [self commitChanges];
        
        MMSF_DSA_Playlist__c *playlist = shelf.playlist;
        if(playlist) {
            [playlist beginEditing];
            playlist[@"Name"] = newName;
            [playlist finishEditingSavingChanges:YES andPushingToServer:YES];
        }
    }
    
    return renamed;
}

- (BOOL)deleteContentItemById:(NSString *)itemId {
    if ([self contentItems] == nil) return NO;
    
    MMSF_ContentVersion *contentItem = [[self contentItems] objectForKey:itemId];
    
    if (contentItem == nil) return NO;
    
    [[self contentItems] removeObjectForKey:itemId];
   
    return YES;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Shelves Collection Accessor Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (DSA_ContentShelfModel *)shelfAtIndex:(NSUInteger)shelfIndex {
    if ([self dataSource].count == 0) {
        return  nil;
    }
    DSA_ContentShelfModel *model = [[self dataSource] objectAtIndex:shelfIndex];
    [model setShelfConfig:[[self config] shelfConfigForSection:shelfIndex]];
    
    return model;
}

- (DSA_ContentShelfModel *)addableShelfAtIndex:(NSUInteger)shelfIndex {
    //if ([self dataSource].count == 0) {
    //    return  nil;
    //}
    DSA_ContentShelfModel *model = [[self addableShelves] objectAtIndex:shelfIndex];
    //[model setShelfConfig:[[self config] shelfConfigForSection:shelfIndex]];
    
    return model;
}

- (NSString *)itemAtIndexPath:(NSIndexPath *)indexPath {
    DSA_ContentShelfModel *shelf = [[self dataSource] objectAtIndex:indexPath.section];
    NSString *itemId = [shelf itemAtIndex:indexPath.item];
    
    return itemId;
}

- (MMSF_ContentVersion *)contentItemAtIndexPath:(NSIndexPath *)indexPath {
    DSA_ContentShelfModel *shelfModel = [self shelfAtIndex:indexPath.section];
    
    return [shelfModel contentItemAtIndex:indexPath.item];
}

- (NSNumber *)indexOfShelfNamed:(NSString *)shelfName {
    __block NSNumber *shelfIndex = nil;
    [[self rawShelves] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(DSA_ContentShelfModel *)obj shelfName] isEqualToString:shelfName]) {
            shelfIndex = @(idx);
            *stop = YES;
        }
    }];
    
    return shelfIndex;
}

- (NSUInteger)shelfCount {
    NSUInteger count = [self.rawShelves count];
    
    return count;
}

- (NSUInteger)addableShelfCount
{
    return self.addableShelves.count;
}

- (NSMutableArray*) addableShelves
{
    if (_addableShelves == nil)
    {
        _addableShelves = [NSMutableArray arrayWithCapacity:self.rawShelves.count];
        [self.rawShelves enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            DSA_ContentShelfModel* model = (DSA_ContentShelfModel*) obj;
            if (model.shelfConfig.canAddContent && model.canModifyShelf)
            {
                [_addableShelves addObject:model];
            }
        }];
    }
    
    return _addableShelves;
}
         
- (BOOL)contentItemId:(NSString *)itemId isOnShelfNamed:(NSString*)shelfName {
    DSA_ContentShelfModel *shelf = [self displayShelfNamed:shelfName];
    
    return [shelf containsItemId:itemId];
}

- (NSString *)shelfNameForIndex:(NSUInteger)index {
    NSString *shelfName = nil;
    
    if (index < [self shelfCount]) {
        shelfName = [[self shelfNames] objectAtIndex:index];
    }
    
    return shelfName;
}

- (NSString *)addableShelfNameForIndex:(NSUInteger)index {
    NSString *shelfName = nil;
    
    if (index < [self addableShelfCount]) {
        shelfName = [[self addableShelfNames] objectAtIndex:index];
    }
    
    return shelfName;
}


- (NSMutableArray *)dataSource {
    [self filterDisplayShelves:[self contentFilter]];
    
    return self.displayShelves;
}

- (DSA_ContentShelfModel *)displayShelfNamed:(NSString *)shelfName {
    return [self shelfNamed:shelfName inArray:[self displayShelves]];
}

- (DSA_ContentShelfModel *)rawShelfNamed:(NSString *)shelfName {
    return [self shelfNamed:shelfName inArray:[self rawShelves]];
}

- (DSA_ContentShelfModel *)shelfNamed:(NSString *)shelfName inArray:(NSArray *)shelfSource {
    __block DSA_ContentShelfModel *returnShelf = nil;
    __weak typeof(self) weakSelf = self;
    [shelfSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[(DSA_ContentShelfModel *)obj shelfName] isEqualToString:shelfName]) {
            returnShelf = (DSA_ContentShelfModel *)obj;
            [returnShelf setShelfConfig:[[weakSelf config] shelfConfigForSection:idx]];
            *stop = YES;
        }
    }];
    
    return returnShelf;
}

- (NSArray *)shelfNames {
    __block NSMutableArray *keys = [NSMutableArray array];
    [[self rawShelves] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [keys addObject:[(DSA_ContentShelfModel*)obj shelfName]];
    }];
    if ([keys count] < 1) return nil;
    
    return keys;
}

- (NSArray *)addableShelfNames {
    __block NSMutableArray *keys = [NSMutableArray array];
    [[self addableShelves] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [keys addObject:[(DSA_ContentShelfModel*)obj shelfName]];
    }];
    if ([keys count] < 1) return nil;
    
    return keys;
}


- (MMSF_ContentVersion *)contentItemById:(NSString *)itemId {
    if ([self contentItems] == nil)
        [self setContentItems:[NSMutableDictionary dictionary]];
    
    MMSF_ContentVersion *contentItem = [[self contentItems] objectForKey:itemId];
    
    if (contentItem == nil) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"Id = %@",itemId];
        MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
        contentItem = (id) [moc anyObjectOfType:@"ContentVersion" matchingPredicate:pred];
        if (contentItem) {
            [[self contentItems] setObject:contentItem forKey:itemId];
        }
    }
    
    return contentItem;
}

#pragma mark - State 

- (void)setState:(NSString *)state {
    _state = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ContentShelvesStateChanged object:self userInfo:@{@"state": state}];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notification Handlers
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)afterShelfChange:(NSNotification *)note {
    [self commitChanges];
}

- (void)noticeContentChanged:(NSNotification *)note {
    [self.rawShelves removeAllObjects];
    [self loadShelves];
    [[self contentItems] removeAllObjects];
    self.addableShelves = nil;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Shelves Collection Management
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (DSA_ContentShelfModel*)createShelfWithPlaylist:(MMSF_DSA_Playlist__c*)playlist {
    DSA_ContentShelfModel *shelf = [[DSA_ContentShelfModel alloc] initWithPlaylist:playlist];
    shelf.shelfConfig = self.config.defaultShelfConfig;
    
    [self.rawShelves addObject:shelf];
    
    [self commitChanges];
    [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ContentShelfCreated object:playlist[@"Name"]];
    
    return shelf;
}

- (NSString *)configPath {
    NSString *path = [NSString stringWithFormat:@"%@%@%@",kShelvesDictPath,@"/",[[self config] configName]];
    
    return path;
}

- (void) filterDisplayShelves:(NSString *)newFilter {
    // TODO someday?  Apparently broken version of this was in original code.
    // for now, this is the critical link between rawShelves and displayShelves.
    self.displayShelves = [self.rawShelves mutableCopy];
}

- (void)loadShelves {
    @synchronized(self) {
        self.displayShelves = [NSMutableArray array];
        self.contentFilter = @"";
        
        if (!self.rawShelves || self.rawShelves.count == 0) {
            self.rawShelves = [NSMutableArray array];
            // Personal Library is first shelf
            [self setUpSpecialShelves];
        }
        
        // get all Playlists
        NSManagedObjectContext *moc = [MM_ContextManager sharedManager].contentContextForReading;
        NSSortDescriptor *featuredSort = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"IsFeatured__c") ascending:YES];
        NSSortDescriptor *orderSort = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Order__c") ascending:YES];
        NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"Name" ascending:YES];
        //NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:@"LastModifiedDate" ascending:NO];
        NSSortDescriptor* followedSort = [NSSortDescriptor sortDescriptorWithKey:@"isFollowedPlaylist" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
            //MMSF_DSA_Playlist__c *pl1 = (MMSF_DSA_Playlist__c*) obj1, *pl2 = (MMSF_DSA_Playlist__c*) obj2;
            //BOOL pl1Followed = pl1.isFollowedPlaylist, pl2Followed = pl2.isFollowedPlaylist;
            NSNumber *n1 = (NSNumber*) obj1, *n2 = (NSNumber*) obj2;
            if (n1.boolValue == n2.boolValue) return NSOrderedSame;
            if (n1.boolValue < n2.boolValue)
            {
                return NSOrderedAscending;
            }
            return NSOrderedDescending;
        }];
#if 0
        NSArray *playlists = [moc allObjectsOfType:[MMSF_DSA_Playlist__c entityName] matchingPredicate:nil sortedBy:@[featuredSort, orderSort, nameSort]];
#else
        NSArray *playlists = [moc allObjectsOfType:[MMSF_DSA_Playlist__c entityName] matchingPredicate:nil sortedBy:nil];
        playlists = [playlists sortedArrayUsingDescriptors:@[followedSort, featuredSort, orderSort, nameSort]];
#endif
        ///
        BOOL isInternalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
        
        for (MMSF_DSA_Playlist__c *playlist in playlists) {
            // create a shelf for each playlist
            DSA_ContentShelfModel *shelf = [self createShelfWithPlaylist:playlist];

            // for the matching Junctions, add Content
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Order__c") ascending:YES];
            NSPredicate *junctionPredicate = [NSPredicate predicateWithFormat:@"%K == %@", RELATIONSHIP_SFID_SHADOW(MNSS(@"Playlist__c")), playlist[@"Id"]];
            NSArray * junctions = [moc allObjectsOfType:[MMSF_Playlist_Content_Junction__c entityName] matchingPredicate:junctionPredicate sortedBy:@[sort]];
            for (MMSF_Playlist_Content_Junction__c *junction in junctions) {
                BOOL shouldAdd = YES;
                NSString *contentDocumentId = junction[MNSS(@"ContentId__c")];
                MMSF_ContentVersion *contentVersion = [MMSF_ContentVersion versionMatchingDocumentID:contentDocumentId inContext:moc];
                
                if(contentVersion) {
                    BOOL internalContent = [contentVersion[MNSS(@"Internal_Document__c")] boolValue];
                    if (!isInternalMode && internalContent) {
                        shouldAdd = NO;
                    }
                    if (shouldAdd) {
                        [shelf.itemIds addObject:contentVersion[@"Id"]];
                    }
                }
            }
        }
        [self filterDisplayShelves:[[DSA_ContentShelvesModel sharedModel] contentFilter]];
    }
}

- (void)commitChanges {
    [self filterDisplayShelves:[self contentFilter]];
}

- (void)clearTheModel {
    [self setDisplayShelves:[NSMutableArray array]];
    [self setRawShelves:[NSMutableArray array]];
}

- (void)setUpSpecialShelves {
    [[[self config] customShelfConfigs] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DSA_ContentShelfConfig *config = (DSA_ContentShelfConfig*)obj;
        DSA_ContentShelfModel *shelfModel = [self createShelfNamed:kPersonalLibraryTitle updateLayout:NO animated:NO];
        [shelfModel setShelfConfig:config];
        if ([[self delegate] respondsToSelector:@selector(itemIdsForSpecialShelf:)]) {
            NSArray *itemIds = [[self delegate] itemIdsForSpecialShelf:config.configurationId];
            [shelfModel setItemIds:[itemIds mutableCopy]];
        }
    }];
}

- (void)synchronizePlaylistsAndShelves
{
    // first, get all playlists and eliminate those that don't have a shelf.
    [self eliminatePlaylistsForMissingShelves];
    // then, add junctions that don't exist, remove junctions that do exist
    [self synchronizeAllJunctions];
    // then, get all junctions for each shelf and eliminate junctions whose content is no longer on the shelf
}

- (void)eliminatePlaylistsForMissingShelves
{
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    NSArray *playlists = [moc allObjectsOfType:[MMSF_DSA_Playlist__c entityName] matchingPredicate:nil];
    for (MMSF_DSA_Playlist__c *playlist in playlists)
    {
        NSString *playlistName = playlist.Name;
        if (![self.shelfNames containsObject:[playlistName uppercaseString]])
        {
            MMLog(@"We don't have a shelf named %@ anymore.  Delete the Playlist.", playlistName);
            // delete the playlist from SFDC
            if(playlist) {
                [playlist deleteFromSalesforceAndLocal];
            }
        }
    }
}

- (void)synchronizeAllJunctions
{
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    
    for (int shelfIndex = 0; shelfIndex < [self shelfCount]; shelfIndex ++)
    {
        DSA_ContentShelfModel *shelf = [self shelfAtIndex:shelfIndex];
        if (!shelf.shelfConfig.synchronizeWithPlaylists) continue;
        if (!shelf.canModifyShelf) continue;
        
        NSMutableArray *documentIds = [NSMutableArray new];
        for (NSString *contentVersionId in shelf.itemIds)
        {
            MMSF_ContentVersion *contentVersion = [MMSF_ContentVersion contentItemBySalesforceId:contentVersionId];
            [documentIds addObject:contentVersion.documentID];
        }
        
        // use relationship shadow to get same set of data as in loadShelves method
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", RELATIONSHIP_SFID_SHADOW(MNSS(@"Playlist__c")), shelf.playlist[@"Id"]];
        NSArray *junctions = [moc allObjectsOfType:[MMSF_Playlist_Content_Junction__c entityName] matchingPredicate:predicate];
        NSArray *junctionContentIds = [junctions valueForKey:MNSS(@"ContentId__c")];
        NSSet *junctionContentSet = [NSSet setWithArray:junctionContentIds];
        NSSet *shelfContentSet = [NSSet setWithArray:documentIds];
        NSMutableSet *junctionExtraIds = [NSMutableSet setWithArray:junctionContentIds];
        [junctionExtraIds minusSet:shelfContentSet];
        NSMutableSet *shelfExtraIds = [NSMutableSet setWithArray:documentIds];
        [shelfExtraIds minusSet:junctionContentSet];
        
        MMLog(@"%d of %d junctions were extras", junctionExtraIds.count, junctionContentSet.count);
        MMLog(@"%d of %d content items didn't have junctions", shelfExtraIds.count, shelfContentSet.count);
        
        for (NSString *documentId in shelfExtraIds)
        {
            MMLog(@"Adding junction for %@", documentId);
            [shelf.playlist addJunctionForContentDocumentId:documentId atIndex:shelfIndex];
        }
        
        for (NSString *documentId in junctionExtraIds)
        {
            MMLog(@"removing junction for %@ on %@", documentId, shelf.shelfName);
            [shelf.playlist removeJunctionForContentDocumentId:documentId];
        }
        
        [shelf orderJunctions];
    }
}

- (void)addJunctionForItemId:(NSString*)itemId atIndexPath:(NSIndexPath*)indexPath;
{
    DSA_ContentShelfModel *model = [self shelfAtIndex:indexPath.section];
    MMLog(@"Adding junction for %@ to %@ at index %d", itemId, model.shelfName, indexPath.row);
    [model addJunctionForItemId:itemId];
}

- (void)removeJunctionForItemId:(NSString*)itemId atShelfIndex:(int)shelfIndex;
{
    DSA_ContentShelfModel *model = [self shelfAtIndex:shelfIndex];
    MMLog(@"removing junction for %@ on %@", itemId, model.shelfName);
    [model removeJunctionForItemId:itemId];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Shelves Collection Rules Enforcement
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    DSA_ContentShelfModel *shelf = [self shelfAtIndex:indexPath.section];
    
    return [shelf canDeleteItemAtIndex:indexPath.item];
}

- (BOOL)canInsertItem:(NSString *)itemId atIndexPath:(NSIndexPath *)indexPath {
    DSA_ContentShelfModel *shelf = [self shelfAtIndex:indexPath.section];
    
    return [shelf canInsertItem:itemId atIndex:indexPath.item showPersonalShelfAlert:YES];
}

- (BOOL)canMoveItem:(NSString *)itemId fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    // We always allow items to be moved within a shelf.
    if ( (fromIndexPath.section == toIndexPath.section) && (toIndexPath.item < [[self shelfAtIndex:toIndexPath.section] itemCount]) ) {
        MMLog(@"yes from %d, %d to %d, %d", fromIndexPath.section, fromIndexPath.item, toIndexPath.section, toIndexPath.item);
        return YES;
    }
    
    // We aren't deleting yet, so we don't need to check whether or not we're allowed to remove the source item. We will
    // remove the item from the source now, and when the user drops the cell, we determine whether or not the user has the
    // choice to "Move" the cell or "Copy" it based on whether or not items can be removed from the source shelf.
    return [self canInsertItem:itemId atIndexPath:toIndexPath];
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Wrapped dependencies for simplified testing
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)showAlertWithTitle:(NSString*)title message:(NSString*)message
{
    [SA_AlertView showAlertWithTitle:title message:message];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - DSA_ContentShelfModel

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DSA_ContentShelfModel ()

@property (nonatomic) BOOL rearrangingSameShelf;

@end

@implementation DSA_ContentShelfModel

@synthesize shelfName = _shelfName;

- (instancetype)initWithShelfName:(NSString*)shelfName {
    self = [super init];
    if(self) {
        _itemIds = [NSMutableArray new];
        
        if([shelfName caseInsensitiveCompare:kPersonalLibraryTitle] != NSOrderedSame) {
            // create playlist
            NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
            MMSF_DSA_Playlist__c *playlist = [moc insertNewEntityWithName:[MMSF_DSA_Playlist__c entityName]];
            [playlist beginEditing];
            playlist[@"Name"] = shelfName;
            [playlist finishEditingSavingChanges:YES andPushingToServer:YES];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistSaved:) name:kNotification_ObjectCreated object:nil];
        }
        _shelfName = shelfName;
    }
    
    return self;
}

- (instancetype)initWithPlaylist:(MMSF_DSA_Playlist__c*)playlist {
    self = [super init];
    if(self) {
        _playlistId = playlist[@"Id"];
        _shelfName = playlist[@"Name"];
        _itemIds = [NSMutableArray new];
    }
    
    return self;
}

- (BOOL)canInsertItem:(NSString *)itemId atIndex:(NSUInteger)index showPersonalShelfAlert:(BOOL)showAlert {
    if ([itemId length] < 1) {
        MMLog(@"WARNING: The itemId \"%@\" is not a valid MMSF_ContentVersion Id", itemId);
        return NO;
    }
    
    if ([self itemCount] < index) {
        MMLog(@"WARNING: The index %d cannot exist on this shelf", index);
        return NO;
    }
    
    if (showAlert && ![[self shelfConfig] canAddContent]) {
        [SA_AlertView showAlertWithTitle:@"" message:@"Sorry, files can only be added to the Personal Library shelf in Salesforce.com."];
        MMLog(@"WARNING: You can't add content to %@", [self shelfName]);
        return NO;
    }
    
    if ([[self itemIds] containsObject: itemId]) {
        MMLog(@"WARNING: That item already exists on %@", [self shelfName]);
        return NO;
    }
    
    return YES;
}

- (BOOL)canDeleteItemAtIndex:(NSUInteger)index {
    
    if (![[self shelfConfig] canRemoveContent]) {
        MMLog(@"WARNING: You can't remove content from %@", [self shelfName]);
        return NO;
    }
    
    if ([self itemCount] <= index) {
        MMLog(@"WARNING: There is no item to move from index %d", index);
        return NO;
    }
    
    return YES;
}

//- (BOOL) canDeleteItemsFromShelf
//{
//    return [self canModifyShelf];
//}
//
//- (BOOL) canAddItemsToShelf
//{
//    return [self canModifyShelf];
//}

- (BOOL) canModifyShelf
{
    MMSF_DSA_Playlist__c* playlist = [MMSF_DSA_Playlist__c playlistBySalesforceId:self.playlistId];
    NSNumber* n = [playlist valueForKey:MNSS(@"IsFeatured__c")];
    BOOL followed = [playlist isFollowedPlaylist];
    return (!n.boolValue && !followed);
}

- (void)insertItem:(NSString *)itemId atIndex:(NSUInteger)index updateLayout:(BOOL)updateLayout animated:(BOOL)animated showPersonalShelfAlert:(BOOL)showAlert {
    if (![self canInsertItem:itemId atIndex:index showPersonalShelfAlert:showAlert]) {
        MMLog(@"WARNING: Are you sure you wanted to insert \"%@\" into the shelf \"%@\" at index %d.", itemId, [self shelfName], index);
    }
    
	NSMutableArray *ids = self.itemIds;
	if (ids == nil)
        self.itemIds = ids = [NSMutableArray array];
    
    NSNumber *shelfIndex = [[DSA_ContentShelvesModel sharedModel] indexOfShelfNamed:[self shelfName]];
    if (shelfIndex == nil) {
        MMLog(@"ERROR:  Couldn't retrieve the index for %@", [self shelfName]);
        return;
    }
    
    if (updateLayout) {
        [ids insertObject:itemId atIndex:index];

        [self setItemIds:ids];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:[shelfIndex integerValue]];

        if (animated) {
            [[[DSA_ContentShelvesModel sharedModel] delegate] insertItemsAtIndexPaths:@[indexPath]];
        }
        else {
            [[[DSA_ContentShelvesModel sharedModel] delegate] reloadData];
        }
    }
    else {
        [ids insertObject:itemId atIndex:index];
        [self setItemIds:ids];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ContentShelfItemCreated object: nil];
}

- (void)deleteItemAtIndex:(NSUInteger)index updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    [self.itemIds removeObjectAtIndex:index];

    if (updateLayout) {
        NSNumber *shelfIndex = [[DSA_ContentShelvesModel sharedModel] indexOfShelfNamed:[self shelfName]];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:[shelfIndex floatValue]];
        if (animated) {
            [[[DSA_ContentShelvesModel sharedModel] delegate] deleteItemsAtIndexPaths:@[indexPath]];
        }
        else {
            [[[DSA_ContentShelvesModel sharedModel] delegate] reloadData];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ContentShelfItemDeleted object:nil];
}

- (BOOL)addContentItemId:(NSString *)itemId updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    if ([self canInsertItem:itemId atIndex:[self itemCount] showPersonalShelfAlert:YES]) {
        [self insertItem:itemId atIndex:[self itemCount] updateLayout:updateLayout animated:animated showPersonalShelfAlert:YES];
        if (!animated)
        {
            // since this isn't animated, the ContentShelvesController won't update the junction for us.
            [self addJunctionForItemId:itemId];
        }
        return YES;
    }
    return NO;
}

- (BOOL)removeContentItemId:(NSString *)itemId updateLayout:(BOOL)updateLayout animated:(BOOL)animated {
    NSUInteger itemIndex = [[self itemIds] indexOfObject:itemId];
    if (![self canDeleteItemAtIndex:itemIndex]) return NO;
    
    [self deleteItemAtIndex:itemIndex updateLayout:updateLayout animated:animated];
    
    if (!animated)
    {
        // since this isn't animated, the ContentShelvesController won't update the junction for us.
        [self removeJunctionForItemId:itemId];
    }
    
    return YES;
}

//  make the junction order match item ordering
- (void)orderJunctions {
    __block BOOL orderUpdated = NO;
    
    [self.itemIds enumerateObjectsUsingBlock:^(id itemId, NSUInteger index, BOOL *stop) {
        MMSF_Playlist_Content_Junction__c *junction = [self.playlist junctionForContentVersionId:itemId];
        if(junction && ![junction[MNSS(@"Order__c")] isEqualToNumber:@(index)]) {
            [junction beginEditing];
            junction[MNSS(@"Order__c")] = @(index);
            [junction finishEditingSavingChanges:YES andPushingToServer:NO];
            orderUpdated = YES;
        }
    }];
    
    if(orderUpdated) {
        [MM_SFChange pushPendingChangesWithCompletionBlock: nil];
    }
}

- (void)addJunctionForItemId:(NSString*)itemId
{
    // item is already in our shelf model
    uint index = [self.itemIds indexOfObject:itemId];
    MMLog(@"Adding junction for %@ to %@ at index %d", itemId, self.shelfName, index);
    [self.playlist addJunctionForContentVersionId:itemId atIndex:index];
}

- (void)removeJunctionForItemId:(NSString*)itemId
{
    // item has already been removed from our shelf model
    MMLog(@"removing junction for %@ on %@", itemId, self.shelfName);
    [self.playlist removeJunctionForContentVersionId:itemId];
}

- (void)addJunctionForIndex:(int)index
{
    [self.playlist addJunctionForContentVersionId:self.itemIds[index] atIndex:index];
}

- (void)moveItem:(NSString *)itemId fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex updateLayout:(BOOL)updateLayout animated:(BOOL)animated showPersonalShelfAlert:(BOOL)showPersonalShelfAlert {
    NSUInteger fromIndexOffset = (toIndex < fromIndex) ? 1 : 0;
    NSUInteger toIndexOffset = (toIndex > fromIndex) ? 1 : 0;
    fromIndex += fromIndexOffset;
    toIndex += toIndexOffset;
    
    self.rearrangingSameShelf = YES;
    
    [self insertItem:itemId atIndex:toIndex updateLayout:updateLayout animated:animated showPersonalShelfAlert:showPersonalShelfAlert];
    [self deleteItemAtIndex:fromIndex updateLayout:updateLayout animated:animated];
    
    self.rearrangingSameShelf = NO;
}

- (NSString *)itemAtIndex:(NSUInteger)index {
    if (index >= self.itemCount)
    {
        MMLog(@"Requested index, %d, was out of bounds", index);
        return nil;
    }
    NSString *itemId = [[self itemIds] objectAtIndex:index];
    return itemId;
}

- (MMSF_ContentVersion *)contentItemAtIndex:(NSUInteger)index {
    NSString *itemId = [self itemAtIndex:index];
    
    return [[DSA_ContentShelvesModel sharedModel] contentItemById:itemId];
}

- (BOOL)deleteContentItemAtIndex:(NSUInteger)index {
    NSString *itemId = [self itemAtIndex:index];
    
    return [[DSA_ContentShelvesModel sharedModel] deleteContentItemById:itemId];
}

- (NSString *)shelfName {
    NSString *name = _shelfName;
    if ([[self shelfConfig] shelfName] != nil && ![[[self shelfConfig] shelfName] isEqualToString:name]) {
        name = [[self shelfConfig] shelfName];
    }
    
    if ([[self shelfConfig] headerLabelForceUpperCase]) {
        name = [name uppercaseString];
    }
    if (![_shelfName isEqualToString:name]) {
        MMVerboseLog(@"Had to correct shelf name from \"%@\" to \"%@\" in getter. Fix this?", _shelfName, name);
        _shelfName = name;
    }
    
    return name;
}

- (void)setShelfName:(NSString *)shelfName
{
    if ([[self shelfConfig] headerLabelForceUpperCase]) {
        shelfName = [shelfName uppercaseString];
    }
    
    _shelfName = shelfName;
}

- (NSUInteger)itemCount {
    return self.itemIds.count;
}

- (BOOL)containsItemId:(NSString *)itemId {
    return [[self itemIds] containsObject:itemId];
}

- (BOOL)isEmpty {
    return ([[self itemIds] count] == 0);
}


#pragma mark - Playlist Accessors

- (MMSF_DSA_Playlist__c *)playlist {
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    NSPredicate *playlistIdPredicate = [NSPredicate predicateWithFormat:@"Id = %@", self.playlistId];
    MMSF_DSA_Playlist__c *playlist = [moc anyObjectOfType:[MMSF_DSA_Playlist__c entityName] matchingPredicate:playlistIdPredicate];
    
    return playlist;
}

- (void)setPlaylist:(MMSF_DSA_Playlist__c*)playlist {
    self.playlistId = playlist[@"Id"];
}

#pragma mark - Notifications

- (void)playlistSaved:(NSNotification*)note {
    if([note.userInfo[@"type"] isEqualToString:[MMSF_DSA_Playlist__c entityName]]) {
        NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
        MMSF_DSA_Playlist__c *playlist = [moc objectWithRobustIDString:note.userInfo[@"robustID"]];
        if(playlist) {
            NSLog(@"Updating id for playlist: %@ = %@", playlist[@"Name"], playlist[@"Id"]);
            self.playlistId = playlist[@"Id"];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotification_ObjectCreated object:nil];
        }
    }
}

@end

NSString *const kNotification_ContentShelfCreated = @"ContentShelfCreated";
NSString *const kNotification_ContentShelfDeleted = @"ContentShelfDeleted";
NSString *const kNotification_ContentShelfItemDeleted = @"ContentShelfItemDeleted";
NSString *const kNotification_ContentShelfItemCreated = @"ContentShelfItemCreated";
NSString *const kNotification_ContentShelvesStateChanged = @"ContentShelvesStateChanged";

NSString *const kContentShelfConfiguration_PersonalLibrary = @"personalLibrary";
NSString *const kContentShelfConfiguration_Default = @"default";
NSString *const kPersonalLibraryTitle = @"overridden by value defined in config";

NSInteger const kShelfNameMaxLength = 80;

NSString *const kContentShelvesStateEdit = @"ContentShelvesStateEdit";
NSString *const kContentShelvesStateNormal = @"ContentShelvesStateNormal";

