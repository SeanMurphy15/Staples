 //
//  MMSF_CategoryMobileConfig__c.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_CategoryMobileConfig__c.h"
#import "MM_ContextManager.h"
#import "MM_SFObjectDefinition.h"
#import "MMSF_MobileAppConfig__c.h"
#import "UIImage+Attachments.h"
#import "UIColor+DSA.h"

@implementation MMSF_CategoryMobileConfig__c

@dynamic LastModifiedDate;
@dynamic CreatedDate;

MMNS_OBJECT_PROPERTY(IsDefault__c);
MMNS_OBJECT_PROPERTY(PortraitX__c);
MMNS_OBJECT_PROPERTY(PortraitY__c);
MMNS_OBJECT_PROPERTY(LandscapeX__c);
MMNS_OBJECT_PROPERTY(LandscapeY__c);
MMNS_OBJECT_PROPERTY(OverlayBgColor__c);
MMNS_OBJECT_PROPERTY(OverlayBgAlpha__c);
MMNS_OBJECT_PROPERTY(OverlayTextColor__c);
MMNS_OBJECT_PROPERTY(GalleryHeadingText__c);
MMNS_OBJECT_PROPERTY(GalleryHeadingTextColor__c);
MMNS_OBJECT_PROPERTY(LandscapeAttachmentId__c);
MMNS_OBJECT_PROPERTY(PortraitAttachmentId__c);
MMNS_OBJECT_PROPERTY(ContentAttachmentId__c);
MMNS_OBJECT_PROPERTY(ContentOverAttachmentId__c);
MMNS_OBJECT_PROPERTY(Button_Text_Align__c);
MMNS_OBJECT_PROPERTY(MobileAppConfigurationId__c);
MMNS_OBJECT_PROPERTY(CategoryId__c);
MMNS_OBJECT_PROPERTY(Sub_Category_Background_Color__c);


////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (CGPoint) portraitButtonPosition
{
    CGPoint pt = CGPointMake([self.PortraitX__c floatValue], [self.PortraitY__c floatValue]);
    return pt;
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (CGPoint) landscapeButtonPosition
{
    CGPoint pt = CGPointMake([self.LandscapeX__c floatValue], [self.LandscapeY__c floatValue]);
    return pt;
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIColor*) overlayBackgroundColor {
    UIColor *color = [UIColor colorWithHexString:self.OverlayBgColor__c alpha:[self.OverlayBgAlpha__c integerValue] / 100.0];
    if (!color) { color = [UIColor groupTableViewBackgroundColor]; }
    
    return color;
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIColor*) overlayTextColor {
    UIColor *color = [UIColor colorWithHexString:self.OverlayTextColor__c alpha:1.0];
    if (!color) { color = [UIColor lightTextColor]; }
    
    return color;
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIColor*) subcategoryBackgroundColor
{
    if ([self.entity.attributesByName objectForKey:  MNSS(@"Sub_Category_Background_Color__c")]) {
        NSString		*hex = self.Sub_Category_Background_Color__c;
		if (hex.length == 0) return nil;
        return [UIColor colorWithHexString:hex alpha:1.0];
    } else {
        return nil;
    }
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIImage*) categoryBackgroundPortraitImage {
    return [UIImage imageWithAttachmentId:self.PortraitAttachmentId__c];
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIImage*) categoryBackgroundLandscapeImage {
    return [UIImage imageWithAttachmentId:self.LandscapeAttachmentId__c];
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIImage*) contentItemBackgroundImage {
    return [UIImage imageWithAttachmentId:self.ContentAttachmentId__c];
}

- (UIImage *) categoryBackgroundImageForOrientation: (UIInterfaceOrientation) orientation {
	return UIInterfaceOrientationIsLandscape(orientation) ? self.categoryBackgroundLandscapeImage : self.categoryBackgroundPortraitImage;
}

- (UIColor *) categoryBackgroundTintColor {
	return self.overlayBackgroundColor;
}

- (UIColor *)galleryHeadingTextColor {
    UIColor *color = [UIColor colorWithHexString:self.GalleryHeadingTextColor__c alpha:1.0];
    if (!color) {
        color = [UIColor lightTextColor];
    }
    
    return color;
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
- (UIImage*) contentItemHighlightBackgroundImage {
    return [UIImage imageWithAttachmentId:self.ContentOverAttachmentId__c];
}

////////////////////////////////////////////////
//
////////////////////////////////////////////////
+ (NSArray*) allActiveCategoryMobileConfigurationsInContext:(NSManagedObjectContext*) context
{
	NSString			*sfidKey = MNSS(@"MobileAppConfigurationId__c_sfid_shadow_mm");
	NSString			*format = $S(@"%@ != nil || %@ != nil", MNSS(@"MobileAppConfigurationId__c"), sfidKey);
    NSPredicate			*pred = [NSPredicate predicateWithFormat: format];
    NSArray				*catconfigArray = [context allObjectsOfType: [MMSF_CategoryMobileConfig__c entityName] matchingPredicate: pred];
        
    
    NSMutableArray				*catConfigMutableArray = [catconfigArray mutableCopy];
    
    for (MMSF_CategoryMobileConfig__c *catConfig in catconfigArray) {
		if (catConfig.MobileAppConfigurationId__c == nil) {
			NSString *sfid = [catConfig valueForKey: sfidKey];
			MMSF_MobileAppConfig__c *config = sfid ? [context anyObjectOfType: [MMSF_MobileAppConfig__c entityName] matchingPredicate: $P(@"Id == %@", sfid)] : nil;
			
			if (![config.Active__c intValue]) [catConfigMutableArray removeObject: catConfig];
		} else {
			MMSF_CategoryMobileConfig__c *catConfigRecord = (MMSF_CategoryMobileConfig__c*)catConfig;
			
			if (![catConfigRecord.MobileAppConfigurationId__c[@"Active__c"] intValue])
				[catConfigMutableArray removeObject:catConfig];
		}
        
    }
    
    return catConfigMutableArray;
    
}

@end
