//
//  DSA_ContentShelvesConfig.h
//  DSA
//
//  Created by Mike Close on 7/24/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DSA_ContentShelfConfig;

typedef enum DSAContentShelvesErrorCode {
    DSAContentShelvesErrorInvalidKey = 0,
    DSAContentShelvesErrorInvalidDataStructure
} DSAContentShelvesErrorCode;

@interface DSA_ContentShelvesConfig : NSObject

@property (nonatomic, strong) NSArray       *customShelfConfigs;
@property (nonatomic, strong) id             defaultShelfConfig;
@property (nonatomic, strong) NSString      *configName;
@property (nonatomic, strong) NSString      *navBarTitle;

/*
 *
 * Designated initializer - used by the DSA_ContentShelvesController
 *
 */
- (id)initWithConfigPath:(NSString *)path;

/*
 *
 * Convenience method for getting the setter selector for a particular property name.
  * ex. the string "bigGiantRobot" would return the equivalent of @selector(setBigGiantRobot:)
 *
 */
+ (SEL)setterSelectorForConfigKey:(NSString *)key;

/*
 *
 * Returns the section config for the section index.  Will either be the default section or a custom section with a matching index.
 *
 */
- (DSA_ContentShelfConfig *)shelfConfigForSection:(NSUInteger)section;

@end


@interface DSA_ContentShelfConfig : NSObject

@property (nonatomic)           NSUInteger     shelfIndex;
@property (nonatomic, strong)   NSString      *shelfName;
@property (nonatomic)           BOOL           synchronizeWithPlaylists;
@property (nonatomic, strong)   NSString      *shelfNameSubtext;
@property (nonatomic)           NSUInteger     minimumLineSpacing;
@property (nonatomic)           NSUInteger     itemsPerRowLandscape;
@property (nonatomic)           NSUInteger     itemsPerRowPortrait;
@property (nonatomic, strong)   NSArray       *sectionPadding;
@property (nonatomic)           UIEdgeInsets   sectionInset;
@property (nonatomic)           NSUInteger     headerHeight;
@property (nonatomic, strong)   NSArray       *headerColors;
@property (nonatomic, strong)   NSArray       *headerColorLocations;
@property (nonatomic, strong)   NSString      *configurationId;
@property (nonatomic)           BOOL           canAddContent;
@property (nonatomic)           BOOL           canRemoveContent;
@property (nonatomic)           BOOL           canDeleteShelf;
@property (nonatomic)           BOOL           canRenameShelf;
@property (nonatomic)           BOOL           confirmItemDelete;
@property (nonatomic, strong)   NSArray       *headerBorderThickness;
@property (nonatomic, strong)   id             headerBorderColor;
@property (nonatomic, strong)   id             headerLabelColor;
@property (nonatomic, strong)   NSString      *headerLabelFontName;
@property (nonatomic, strong)   NSString      *headerLabelFontWeight;
@property (nonatomic)           NSUInteger     headerLabelFontSize;
@property (nonatomic)           BOOL           headerLabelForceUpperCase;
@property (nonatomic, strong)   id             headerLabelIconImage;
@property (nonatomic, strong)   NSArray       *sectionBackgroundColors;
@property (nonatomic, strong)   NSArray       *sectionBackgroundColorLocations;
@property (nonatomic, strong)   NSArray       *thumbnailSize;
@property (nonatomic, strong)   id             thumbnailLabelColor;
@property (nonatomic, strong)   id             thumbnailBackgroundColor;
@property (nonatomic, strong)   id             thumbnailBorderColor;
@property (nonatomic, strong)   NSArray       *thumbnailBorderThickness;
@property (nonatomic)           UIEdgeInsets   thumbnailBorderOutsets;
@property (nonatomic, strong)   NSString      *thumbnailLabelFontName;
@property (nonatomic, strong)   NSString      *thumbnailLabelFontWeight;
@property (nonatomic)           NSUInteger     thumbnailLabelFontSize;
@property (nonatomic, strong)   id             thumbnailUnavailableIcon;
@property (nonatomic)           NSUInteger     thumbnailUnavailableFontSize;
@property (nonatomic, strong)   NSString      *thumbnailUnavailableFontName;
@property (nonatomic, strong)   id             thumbnailUnavailableFontColor;
@property (nonatomic, strong)   NSString      *thumbnailUnavailableFontWeight;
@property (nonatomic, strong)   NSString      *thumbnailUnavailableFontStyle;
@property (nonatomic, strong)   NSString      *emptyShelfBackgroundHeader;
@property (nonatomic, strong)   NSString      *emptyShelfBackgroundMessage;

- (CGSize)thumbnailCGSize;
- (CGSize)cellCGSize;
- (id)initWithDictionary:(NSDictionary *)dict error:(NSError**)error;
@end



// Configuration Keys
extern NSString *const kContentShelvesConfigKey_HeaderColors;
extern NSString *const kContentShelvesConfigKey_HeaderBorderColor;
extern NSString *const kContentShelvesConfigKey_HeaderLabelColor;
extern NSString *const kContentShelvesConfigKey_SectionBackgroundColors;
extern NSString *const kContentShelvesConfigKey_ThumbnailLabelColor;
extern NSString *const kContentShelvesConfigKey_ThumbnailBackgroundColor;
extern NSString *const kContentShelvesConfigKey_ThumbnailBorderColor;
extern NSString *const kContentShelvesConfigKey_ThumbnailUnavailableFontColor;

extern NSString *const kContentShelvesErrorDomain;