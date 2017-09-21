//
//  MMSF_ContentVersion.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"
#import <MessageUI/MessageUI.h>
#import "MMSF_Cat_Content_Junction__c.h"
#import <QuickLook/QuickLook.h>

@class MMSF_MobileAppConfig__c;
@class MMSF_Category__c;

extern NSString * const DSA_EmailBodyString;

@interface MMSF_ContentVersion : MMSF_Object <QLPreviewItem>

@property (nonatomic, strong) NSString *documentsPath,*contentItemsPath;

@property (nonatomic, strong) NSDate *ContentModifiedDate;
@property (nonatomic, strong) NSNumber *ContentSize;
@property (nonatomic, strong) NSString *ContentUrl;
@property (nonatomic, strong) NSDate *CreatedDate;
@property (nonatomic, strong) NSString *Description;
@property (nonatomic, strong) NSNumber *FeaturedContentBoost;
@property (nonatomic, strong) NSDate *FeaturedContentDate;
@property (nonatomic, strong) NSString *FileType;
@property (nonatomic, strong) NSDate *LastModifiedDate;
@property (nonatomic, strong) NSString *Document_Type__c;
@property (nonatomic, strong) MMSF_Category__c *ModelM_Category__c;
@property (nonatomic, strong) NSNumber *NegativeRatingCount;
@property (nonatomic, strong) NSString *PathOnClient;
@property (nonatomic, strong) NSString *Title;
@property (nonatomic, strong) NSString *TagCsv;
@property (nonatomic, strong) NSString *VersionNumber;
@property (nonatomic, strong) MMSF_Object *ContentDocumentId;
@property (nonatomic, strong) NSMutableDictionary *thumbnailMemCache;

@property (nonatomic, strong) MMSF_MobileAppConfig__c *MobileAppConfigId__c;

@property (nonatomic, readonly) NSString *documentID;

@property (nonatomic,readonly, assign) BOOL isProtectedContent;
@property (nonatomic, readonly,assign) BOOL isMovieFile;
@property (nonatomic, readonly,assign) BOOL isZipFile;
@property (nonatomic, readonly,assign) BOOL canEmail;
@property (nonatomic, readonly,strong) NSString *fullPath, *titleForMailing, *filenameForMailing;

@property (nonatomic, readonly,strong) NSString *breadcrumbPathString;
@property (nonatomic, strong) NSString *mimeType;

@property (nonatomic, readonly) BOOL requiresQuicklook;
@property (readonly) NSString* previewItemTitle;
@property (readonly) NSURL* previewItemURL;

@property (nonatomic, readonly) UIImage *thumbnailImage;
@property (nonatomic, readonly) BOOL  thumbnailImageExists;
@property (unsafe_unretained, nonatomic, readonly) NSString  *thumbnailImagePath;  //???
           
- (UIImage *) tableCellImage;
+ (MMSF_ContentVersion*) contentItemBySalesforceId:(NSString*) sfid;

+ (MFMailComposeViewController *) controllerForMailing;
- (MFMailComposeViewController *) controllerForMailingTo: (NSArray *) addresses;
- (NSString *)contentBodyForMailing;

- (NSData*) contentItemAsData;
+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs;
+ (MMSF_ContentVersion *) versionMatchingDocumentID: (NSString *) docID inContext: (NSManagedObjectContext *) moc;

- (NSString*)categoryLocationPath;

- (BOOL) isLinkContent;
- (BOOL) isFileDownloaded;

+ (NSArray*)personalLibraryContentVersions;
- (void)generateThumbnailSize:(CGSize)size completionBlock:(void(^)(UIImage*))completionBlock;
- (void)generateThumbnailSize:(CGSize)size backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets completionBlock:(void(^)(UIImage*))completionBlock;

@end
