//
//  DSA_CategoryContentsViewController.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/31/13.
//
//

#import "DSA_MediaDisplayViewController.h"

@class MMSF_Category__c, MMSF_CategoryMobileConfig__c;

@interface DSA_CategoryContentsViewController : UIViewController <DSA_MediaDisplayViewControllerDelegate>

+ (id) browserForCategory: (MMSF_Category__c *) category withConfig: (MMSF_CategoryMobileConfig__c *) config;
+ (id) showBrowserForCategory: (MMSF_Category__c *) category withConfig: (MMSF_CategoryMobileConfig__c *) config inParent: (UIViewController *) parent withLandcapeInsets: (UIEdgeInsets) landscapeInsets andPortraitInsets: (UIEdgeInsets) portraitInsets;

@property (nonatomic, strong) IBOutlet UIWebView *webview;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *categoryNameLabel, *categoryHeadingLabel;
@property (nonatomic, strong) MMSF_Category__c *category;
@property (nonatomic, strong) NSArray *categoryContents;
@property (nonatomic, strong) MMSF_CategoryMobileConfig__c *categoryConfiguration;
@property (nonatomic) UIEdgeInsets landscapeInsets, portraitInsets;

- (void) removeFroMParentAnimated: (BOOL) animated;

@end
