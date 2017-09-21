//
//  MMSF_MobileAppConfig__c.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "DSARestClient.h"
#import "MMSF_Object.h"
#import "MM_Headers.h"

@class MMSF_CategoryMobileConfig__c, MMSF_Category__c;

@interface MMSF_MobileAppConfig__c : MMSF_Object

@property (nonatomic, strong) NSDate *LastModifiedDate;
@property (nonatomic, strong) NSDate *CreatedDate;
@property (nonatomic, strong) NSNumber *Active__c;
@property (nonatomic, strong) NSString *TitleText__c;
@property (nonatomic, strong) NSString *TitleTextColor__c;
@property (nonatomic, strong) NSNumber *TitleTextAlpha__c;
@property (nonatomic, strong) NSString *TitleBgColor__c;
@property (nonatomic, strong) NSNumber *TitleBgAlpha__c;
@property (nonatomic, strong) NSString *IntroText__c;
@property (nonatomic, strong) NSString *IntroTextColor__c;
@property (nonatomic, strong) NSNumber *IntroTextAlpha__c;
@property (nonatomic, strong) NSString *ButtonTextColor__c;
@property (nonatomic, strong) NSString *ButtonHighlightTextColor__c;
@property (nonatomic, strong) NSNumber *ButtonTextAlpha__c;
@property (nonatomic, strong) NSString *LandscapeAttachmentId__c;
@property (nonatomic, strong) NSString *PortraitAttachmentId__c;
@property (nonatomic, strong) NSString *ButtonDefaultAttachmentId__c;
@property (nonatomic, strong) NSString *ButtonHighlightAttachmentId__c;
@property (nonatomic, strong) NSString *LogoAttachmentId__c;
@property (nonatomic, strong) NSString *Profiles__c;
@property (nonatomic, strong) NSString *Profile_Names__c;
@property (nonatomic, strong) NSNumber *Check_In_Enabled__c;


+ (NSArray*) allActiveMobileConfigurationsInContext:(NSManagedObjectContext*) context;
+ (NSUInteger) activeConfigurationCountInContext:(NSManagedObjectContext*) context;
+ (MMSF_MobileAppConfig__c *) activeMobileConfigInContext:(NSManagedObjectContext *) context;



- (UIColor*) titleBarColor;
- (UIColor*) infoTextColor;
- (UIColor*) titleTextColor;

- (UIImage*) portraitBackgroundImage;
- (UIImage*) landscapeBackgroundImage;

- (UIImage*) buttonDefaultImage;
- (UIImage*) buttonHighlightImage;

- (UIColor*) buttonTextColor;
- (UIColor*) buttonTextHighlightColor;

- (UIImage*) logoImage;

- (NSArray*) sortedCategoryConfigurations;
- (MMSF_CategoryMobileConfig__c *) configForCategory: (MMSF_Category__c *) category;

@end
