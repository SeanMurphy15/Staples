#import "DSA_FavoriteShelf.h"
#import "MMSF_ContentVersion.h"
#import "MM_ContextManager.h"

static NSMutableDictionary			*s_shelves = nil;
#define kShelvesDictPath		[@"~/Library/Shelves.dat" stringByExpandingTildeInPath]

@implementation DSA_FavoriteShelf

+ (void) initialize {
	@autoreleasepool {
        @try {
            if ([[NSFileManager defaultManager] fileExistsAtPath: kShelvesDictPath]) {
                s_shelves = [[NSMutableDictionary alloc] initWithContentsOfFile: kShelvesDictPath];
            }
        } @catch (id e) {
            [SA_AlertView showAlertWithException: e];
        }
        if (s_shelves == nil) s_shelves = [[NSMutableDictionary alloc] init];

    }
}

+ (NSArray *) favoritesForItem: (MMSF_ContentVersion *) item {
	NSMutableArray			*faves = [NSMutableArray array];
	
	for (NSString *shelfName in s_shelves) {
		NSArray			*shelf = [s_shelves objectForKey: shelfName];
		if ([shelf containsObject: item.Id]) [faves addObject: shelfName];
	}
	
	return faves;
}

+ (BOOL) createShelfNamed: (NSString *) name {
	if (name.length == 0) {
        [SA_AlertView showAlertWithTitle: @"Shelf name can't be empty" message: @"Please enter a shelf name."];
		return NO;
	}

	if ([s_shelves objectForKey: name]) {
		[SA_AlertView showAlertWithTitle: @"A shelf with this name already exists" message: @"Please enter a different name."];
		return NO;
	}
	
	[s_shelves setObject: [NSMutableArray array] forKey: name];
	[s_shelves writeToFile: kShelvesDictPath atomically: YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_FavoriteShelfCreated object: name];
	return YES;
}

+ (void) setFavoriteShelves: (NSSet *) shelves forItem: (MMSF_ContentVersion *) item {
	for (NSString *shelfName in s_shelves) {
		NSMutableArray			*members = [s_shelves objectForKey: shelfName];
		
		if ([shelves containsObject: shelfName]) {
			if (![members containsObject: item.Id]) [members addObject: item.Id];
		} else {
			[members removeObject: item.Id];
		}
	}
	[s_shelves writeToFile: kShelvesDictPath atomically: YES];
}

+ (NSArray *) allShelfNames {
	return [s_shelves allKeys];
}

+ (NSArray *) itemsForShelfName: (NSString *) shelf {
	NSMutableArray			*items = [NSMutableArray array];
	//NSManagedObjectContext	*context = [SF_Store store].context;
    NSManagedObjectContext *context = [MM_ContextManager sharedManager].contentContextForReading;
	
	for (NSString *itemID in [s_shelves objectForKey: shelf]) {
		MMSF_ContentVersion			*item = [context anyObjectOfType: [MMSF_ContentVersion entityName] matchingPredicate: $P(@"Id == %@", itemID)];
		
		if (item) [items addObject: item];
	}
	return items;
}

+ (void) deleteShelf: (NSString *) shelfName {
	[s_shelves removeObjectForKey: shelfName];
	[s_shelves writeToFile: kShelvesDictPath atomically: YES];
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_FavoriteShelfDeleted object: shelfName];
}

+ (BOOL) shelf: (NSString *) name containsContentItem: (MMSF_ContentVersion *) item {
	NSArray						*ids = [s_shelves objectForKey: name];
	
	return [ids containsObject: item.Id];
}

+ (void) addContentItem: (MMSF_ContentVersion *) item toShelf: (NSString *) name {
	NSMutableArray				*ids = [s_shelves objectForKey: name];
	if (ids == nil) {
		ids = [NSMutableArray array];
		[s_shelves setObject: ids forKey: name];
	} else if (![ids respondsToSelector: @selector(addObject:)]) {
		ids = [[ids mutableCopy] autorelease];
		[s_shelves setObject: ids forKey: name];
	}
	
	if ([ids containsObject: item.Id]) return;
	
	if (item.Id) {
        [ids addObject: item.Id];
        [s_shelves writeToFile: kShelvesDictPath atomically: YES];
        [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_FavoriteItemCreated object: nil];
    }
}

+ (void) removeContentItem: (MMSF_ContentVersion *) item fromShelf: (NSString *) name {
	NSMutableArray				*ids = [s_shelves objectForKey: name];
	
	if (![ids containsObject: item.Id]) return;
	
	if (![ids respondsToSelector: @selector(addObject:)]) {
		ids = [[ids mutableCopy] autorelease];
		[s_shelves setObject: ids forKey: name];
	}
	[ids removeObject: item.Id];
	[s_shelves writeToFile: kShelvesDictPath atomically: YES];
    [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_FavoriteItemDeleted object: nil];
}

+ (BOOL) isItemFavorited: (MMSF_ContentVersion *) item {
 
    for(id key in s_shelves) {
        NSMutableArray *ids = [s_shelves objectForKey:key];
        if (ids == nil) continue;
        if ([ids containsObject: item.Id]) return YES;
    }
    
    return NO;
}


+ (void) removeContentItem: (MMSF_ContentVersion *) item {

    for(id key in s_shelves) {
        NSMutableArray *ids = [s_shelves objectForKey:key];
        if (ids == nil) continue;
        if ([ids containsObject: item.Id]) {
            [ids removeObject:item.Id];
            [s_shelves writeToFile: kShelvesDictPath atomically: YES];
            [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_FavoriteItemDeleted object: nil];
        }
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (BOOL) contentItem:(MMSF_ContentVersion*) item isOnShelfNamed:(NSString*) shelfName
{
	NSArray	*ids = [s_shelves objectForKey: shelfName];
    
    return [ids containsObject:item.Id];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
+ (BOOL) renameShelf:(NSString*) originalName to:(NSString*) newName
{
    BOOL renamed = NO;
    
	NSMutableArray				*ids = [s_shelves objectForKey: originalName];
    if (ids)
    {
        [s_shelves setObject:ids forKey:newName];
        [s_shelves removeObjectForKey:originalName];
        [s_shelves writeToFile: kShelvesDictPath atomically: YES];
        renamed = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_FavoriteShelfRenamed object: newName];
    }
    
    return renamed;
}

@end
