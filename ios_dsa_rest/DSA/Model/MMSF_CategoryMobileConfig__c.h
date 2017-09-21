//
//  MMSF_CategoryMobileConfig__c.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"

@class MMSF_Category__c;

@interface MMSF_CategoryMobileConfig__c : MMSF_Object

@property (nonatomic, strong) NSDate *LastModifiedDate;
@property (nonatomic, strong) NSDate *CreatedDate;
@property (nonatomic, strong) NSNumber *IsDefault__c;
@property (nonatomic, strong) NSNumber *PortraitX__c;
@property (nonatomic, strong) NSNumber *PortraitY__c;
@property (nonatomic, strong) NSNumber *LandscapeX__c;
@property (nonatomic, strong) NSNumber *LandscapeY__c;
@property (nonatomic, strong) NSString *OverlayBgColor__c;
@property (nonatomic, strong) NSNumber *OverlayBgAlpha__c;
@property (nonatomic, strong) NSString *OverlayTextColor__c;
@property (nonatomic, strong) NSString *GalleryHeadingText__c;
@property (nonatomic, strong) NSString *GalleryHeadingTextColor__c;
@property (nonatomic, strong) MMSF_Category__c *CategoryId__c;
@property (nonatomic, strong) NSString *LandscapeAttachmentId__c;
@property (nonatomic, strong) NSString *PortraitAttachmentId__c;
@property (nonatomic, strong) NSString *ContentAttachmentId__c;
@property (nonatomic, strong) NSString *ContentOverAttachmentId__c;
@property (nonatomic, strong) NSString *Button_Text_Align__c;
@property (nonatomic, strong) MMSF_Object *MobileAppConfigurationId__c;
@property (nonatomic, strong) NSString *Sub_Category_Background_Color__c;

@property (nonatomic, readonly) UIColor *categoryBackgroundTintColor;


//+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs;


- (CGPoint) portraitButtonPosition;
- (CGPoint) landscapeButtonPosition;

- (UIColor*) overlayBackgroundColor;
- (UIColor*) overlayTextColor;

- (UIColor *)galleryHeadingTextColor;

- (UIImage*) categoryBackgroundPortraitImage;
- (UIImage*) categoryBackgroundLandscapeImage;
- (UIImage *) categoryBackgroundImageForOrientation: (UIInterfaceOrientation) orientation;

- (UIImage*) contentItemBackgroundImage;
- (UIImage*) contentItemHighlightBackgroundImage;
- (UIColor*) subcategoryBackgroundColor;

+ (NSArray*) allActiveCategoryMobileConfigurationsInContext:(NSManagedObjectContext*) context;


@end
