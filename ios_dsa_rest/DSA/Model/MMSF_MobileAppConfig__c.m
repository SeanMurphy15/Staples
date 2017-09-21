//
//  MMSF_MobileAppConfig__c.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_MobileAppConfig__c.h"
//#import "MM_SOQLQueryString.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "MM_ContextManager.h"
#import "MMSF_Category__c.h"
#import "UIColor+DSA.h"
#import "MMSF_Attachment.h"
#import "UIImage+Attachments.h"

@implementation MMSF_MobileAppConfig__c

@dynamic LastModifiedDate;
@dynamic CreatedDate;


MMNS_OBJECT_PROPERTY(TitleText__c);
MMNS_OBJECT_PROPERTY(TitleTextColor__c);
MMNS_OBJECT_PROPERTY(TitleTextAlpha__c);
MMNS_OBJECT_PROPERTY(TitleBgColor__c);
MMNS_OBJECT_PROPERTY(TitleBgAlpha__c);
MMNS_OBJECT_PROPERTY(IntroText__c);
MMNS_OBJECT_PROPERTY(IntroTextColor__c);
MMNS_OBJECT_PROPERTY(IntroTextAlpha__c);
MMNS_OBJECT_PROPERTY(ButtonTextColor__c);
MMNS_OBJECT_PROPERTY(ButtonHighlightTextColor__c);
MMNS_OBJECT_PROPERTY(ButtonTextAlpha__c);
MMNS_OBJECT_PROPERTY(LandscapeAttachmentId__c);
MMNS_OBJECT_PROPERTY(PortraitAttachmentId__c);
MMNS_OBJECT_PROPERTY(ButtonDefaultAttachmentId__c);
MMNS_OBJECT_PROPERTY(ButtonHighlightAttachmentId__c);
MMNS_OBJECT_PROPERTY(LogoAttachmentId__c);
MMNS_OBJECT_PROPERTY(Profiles__c);
MMNS_OBJECT_PROPERTY(Profile_Names__c);
MMNS_OBJECT_PROPERTY(Check_In_Enabled__c);
MMNS_OBJECT_PROPERTY(Active__c);


////////////////////////////////////////////////
//
////////////////////////////////////////////////
+ (NSArray*) allActiveMobileConfigurationsInContext:(NSManagedObjectContext*) context
{
    NSString	*format = $S(@"%@ == %%d", MNSS(@"Active__c"));
    NSPredicate *pred = [NSPredicate predicateWithFormat: format, YES];
    
    NSArray *configArray =  [context allObjectsOfType: [MMSF_MobileAppConfig__c entityName]
                                    matchingPredicate: pred sortedBy: [NSSortDescriptor SA_arrayWithDescWithKey: MNSS(@"TitleText__c") ascending: YES]];
    
    return configArray;
    
}



////////////////////////////////////////////////
//
////////////////////////////////////////////////
+ (NSUInteger) activeConfigurationCountInContext:(NSManagedObjectContext*) context
{
    NSString	*format = $S(@"%@ == %%d", MNSS(@"Active__c"));
    NSPredicate *pred = [NSPredicate predicateWithFormat: format, YES];
    NSUInteger n = [context numberOfObjectsOfType: [MMSF_MobileAppConfig__c entityName]
                                matchingPredicate: pred];
    return n;
}


+ (MMSF_MobileAppConfig__c *) activeMobileConfigInContext:(NSManagedObjectContext *) context
{
    NSString	*format = $S(@"%@ == %%d", MNSS(@"Active__c"));
    NSPredicate *pred = [NSPredicate predicateWithFormat: format, YES];
    if (context == nil) context = [[MM_ContextManager sharedManager] threadContentContext];
    MMSF_MobileAppConfig__c* config = [context anyObjectOfType: [self entityName] matchingPredicate: pred];
    return config;
}

- (UIColor*) titleBarColor {
    UIColor *color = [UIColor colorWithHexString:self.TitleBgColor__c
                                           alpha:[self.TitleTextAlpha__c integerValue]/100.0];
    if (!color) { color = [UIColor blackColor]; }
    
    return color;
}

- (UIColor*) infoTextColor {
    UIColor *color = [UIColor colorWithHexString:self.IntroTextColor__c
                                           alpha:[self.IntroTextAlpha__c integerValue]/100.0];
    if (!color) { color = [UIColor lightTextColor]; }
    
    return color;
}

- (UIColor*) buttonTextColor {
    UIColor *color = [UIColor colorWithHexString:self.ButtonTextColor__c
                                           alpha:[self.ButtonTextAlpha__c integerValue]/100.0];
    if (!color) { color = [UIColor lightTextColor]; }
    
    return color;
}

- (UIColor*) buttonTextHighlightColor {
    UIColor *color = [UIColor colorWithHexString:self.ButtonHighlightTextColor__c
                                           alpha:[self.ButtonTextAlpha__c integerValue]/100.0];
    if (!color) { color = [UIColor lightGrayColor]; }
    
    return color;
}

- (UIImage*) portraitBackgroundImage
{
    return loadImageFromAttachmentWithSalesforceId(self.PortraitAttachmentId__c);
}

- (UIImage*) landscapeBackgroundImage
{
    return loadImageFromAttachmentWithSalesforceId(self.LandscapeAttachmentId__c);
}

- (UIImage*) buttonDefaultImage {
    return loadImageFromAttachmentWithSalesforceIdScaled(self.ButtonDefaultAttachmentId__c, 1.0f);
}

- (UIImage*) buttonHighlightImage {
    return loadImageFromAttachmentWithSalesforceIdScaled(self.ButtonHighlightAttachmentId__c, 1.0f);
}

- (UIImage*) logoImage
{
    return loadImageFromAttachmentWithSalesforceId(self.LogoAttachmentId__c);
}

- (UIColor*) titleTextColor {
    NSString* s = self.TitleTextColor__c;
    BOOL isString = [s isKindOfClass:[NSString class]];
    
    if (!s || isString == NO) {
        s = @"FFFFFF";
    }
    
    NSInteger alpha = [self.TitleTextAlpha__c integerValue]/100.0;
    if (alpha == 0) {
        alpha = 1.0;
    }
    
    return [UIColor colorWithHexString:s alpha:alpha];
}

- (NSArray*) sortedCategoryConfigurations
{
    
    NSString	*format = $S(@"%@ == %%@", MNSS(@"MobileAppConfigurationId__c"));
    NSPredicate *pred = [NSPredicate predicateWithFormat: format, self];
    
    NSArray *catMobileConfigArray = [self.moc allObjectsOfType: [MMSF_CategoryMobileConfig__c entityName] matchingPredicate:pred sortedBy:nil];
    
    catMobileConfigArray = [catMobileConfigArray sortedArrayUsingDescriptors:[NSSortDescriptor arrayWithDescriptorWithKey:@"CreatedDate" ascending:NO]];
    
    return catMobileConfigArray;
    
}

- (MMSF_CategoryMobileConfig__c *) configForCategory: (MMSF_Category__c *) category {
    while (category) {
        NSString				*format = $S(@"%@ = %%@ && %@ == %%@", MNSS(@"MobileAppConfigurationId__c"), MNSS(@"CategoryId__c"));
        
        NSPredicate *pred = [NSPredicate predicateWithFormat: format,self, category];
        
        MMSF_CategoryMobileConfig__c	*config = [self.moc anyObjectOfType: [MMSF_CategoryMobileConfig__c entityName] matchingPredicate: pred];
        if (config) return config;
        
        category = category.Parent_Category__c;
    }
    return nil;
}

UIImage* loadImageFromAttachmentWithSalesforceId(NSString* salesforceId)
{
    CGFloat imageScale = [UIScreen mainScreen].scale;
    return loadImageFromAttachmentWithSalesforceIdScaled(salesforceId, imageScale);  //Will Accomodate Retina Display
}

UIImage* loadImageFromAttachmentWithSalesforceIdScaled (NSString* salesforceId, CGFloat deviceScale)
{
    UIImage* img = nil;
    if (salesforceId == nil) return img;
    MMSF_Attachment* attach = [MMSF_Attachment attachmentWithSalesforceId:salesforceId];
    if (attach != nil)
    {
        img = [UIImage imageWithData:[NSData dataWithContentsOfFile:[attach filepath]] scale:deviceScale];
    }
    return img;
}

@end
