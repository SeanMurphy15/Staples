//
//  DSA_CategoryContentsViewController.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/31/13.
//
//

#import "DSA_CategoryContentsViewController.h"
#import "MMSF_Category__c.h"
#import "DSA_MediaDisplayViewController.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "DSA_DocumentDetailsView.h"
#import "DSA_AppDelegate.h"

@interface DSA_CategoryContentsViewController ()
@property (nonatomic, strong) UIImage *cellBackgroundImage, *cellHighlightedBackgroundImage;
@end

@implementation DSA_CategoryContentsViewController

+ (id) browserForCategory: (MMSF_Category__c *) category withConfig: (MMSF_CategoryMobileConfig__c *) config {
	DSA_CategoryContentsViewController			*controller = [[self alloc] init];
	
	controller.category = category;
	controller.categoryConfiguration = config;
    
	return controller;
}

+ (id) showBrowserForCategory: (MMSF_Category__c *) category withConfig: (MMSF_CategoryMobileConfig__c *) config inParent: (UIViewController *) parent withLandcapeInsets: (UIEdgeInsets) landscapeInsets andPortraitInsets: (UIEdgeInsets) portraitInsets {
	if (category == nil) return nil;
	DSA_CategoryContentsViewController			*browser = [self browserForCategory: category withConfig: config];
	
	browser.portraitInsets = portraitInsets;
	browser.landscapeInsets = landscapeInsets;
	
	browser.view.center = CGPointMake(browser.view.center.x + browser.view.bounds.size.width, browser.view.center.y);
	[parent addChildViewController: browser];
	[parent.view addSubview: browser.view];
	browser.view.frame = [browser calculateFrame];
	
	[UIView animateWithDuration: 0.2 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations: ^{
		browser.view.frame = [browser calculateFrame];
	} completion:^(BOOL finished) { }];
	
	return browser;
}

- (CGRect) calculateFrame {
	UIEdgeInsets		insets = UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? self.landscapeInsets : self.portraitInsets;
	return CGRectMake(insets.left, insets.top, self.view.superview.bounds.size.width - (insets.left + insets.right), self.view.superview.bounds.size.height - (insets.top + insets.bottom));
}

- (void) removeFroMParentAnimated: (BOOL) animated {
	[UIView animateWithDuration: animated ? 0.2 : 0.0 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations: ^{
		self.view.center = CGPointMake(self.view.superview.bounds.size.width + self.view.bounds.size.width / 2, self.view.center.y);
	} completion:^(BOOL finished) {
		[self.view removeFromSuperview];
		[self removeFromParentViewController];
	}];
}

- (void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation duration: (NSTimeInterval) duration {
	self.view.frame = [self calculateFrame];
}

#pragma mark - View Lifecycle

- (void) viewDidLoad {
	[super viewDidLoad];
	    
	self.tableView.accessibilityLabel = @"Category Contents Table";
	self.tableView.accessibilityIdentifier = @"Category Contents Table";
	self.categoryContents = self.category.sortedContents;
	
	self.cellBackgroundImage = self.categoryConfiguration.contentItemHighlightBackgroundImage;
	self.cellHighlightedBackgroundImage = self.categoryConfiguration.contentItemBackgroundImage;
		
	self.webview.backgroundColor = [UIColor clearColor];
	self.webview.opaque = NO;
	self.categoryNameLabel.text = self.category.Name;
	self.categoryHeadingLabel.text = self.categoryConfiguration.GalleryHeadingText__c;
    
    NSString * colString = self.categoryConfiguration.GalleryHeadingTextColor__c;
    
    self.categoryHeadingLabel.textColor = colString ? [UIColor colorWithSA_HexString:colString] : [UIColor whiteColor];
    
	self.categoryNameLabel.textColor = self.categoryConfiguration.overlayTextColor ?: [UIColor blackColor];
	self.view.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundView = nil;
	
	[self.tableView registerClass: [UITableViewCell class] forCellReuseIdentifier: @"cell"];
	
	NSError *error = nil;
	NSString *HTMLTemplatePath = [[NSBundle mainBundle] pathForResource:@"VisualBrowserTemplate" ofType:@"html"];
	NSString *HTMLTemplate = [NSString stringWithContentsOfFile:HTMLTemplatePath encoding:NSUTF8StringEncoding error:&error];
	
	NSString *htmlString = nil;
	if (!error && self.category.Description__c) {
		htmlString = [HTMLTemplate stringByReplacingOccurrencesOfString:@"__CONTENT__" withString:self.category.Description__c];

      //  MMSF_CategoryMobileConfig__c *config = [g_appDelegate.selectedMobileAppConfig configForCategory:self.category];
      //  if (config) {
      //      htmlString = [htmlString stringByReplacingOccurrencesOfString:@"__COLOR__" withString:config.GalleryHeadingTextColor__c];
      //  }
        
		[self.webview loadHTMLString:htmlString baseURL: nil];
	}
	else {
		[self.webview loadHTMLString:@"" baseURL:nil];
	}

}

#pragma mark - Table DataSource/Delegate

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSString								*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	MMSF_ContentVersion						*doc = self.categoryContents[indexPath.section];

	for (UIView *view in cell.subviews) {
		view.backgroundColor = [UIColor clearColor];
	}
	cell.backgroundColor = [UIColor clearColor];

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#if 1
    CGSize thumbSize = CGSizeMake(40.f, 40.f);
    
    [doc generateThumbnailSize:thumbSize completionBlock:^(UIImage *image) {
        cell.imageView.image = image;
    }];
        
    if (cell.imageView.image == nil) cell.imageView.image = [doc tableCellImage];
	
    cell.textLabel.text = doc[@"Title"];
#else
	cell.imageView.image = [doc tableCellImage];
	cell.textLabel.text = doc[@"Title"];
#endif
    cell.backgroundViewColor = [UIColor colorWithWhite: 0.0 alpha: 0.52];
	cell.textLabel.font = [UIFont systemFontOfSize: 20]; // [UIFont fontWithName: @"AmericanTypewriter" size: 20];
	cell.textLabel.textColor = [UIColor colorWithWhite: 0.94 alpha: 1.0];
	
	if (self.cellHighlightedBackgroundImage) {
		UIImageView					*backgroundView = [[UIImageView alloc] initWithFrame: cell.contentView.frame];
		
		backgroundView.contentMode = UIViewContentModeScaleToFill;
		backgroundView.image = self.cellHighlightedBackgroundImage;
		cell.backgroundView = backgroundView;
	}
	if (self.cellBackgroundImage) {
		UIImageView					*backgroundView = [[UIImageView alloc] initWithFrame: cell.contentView.frame];
		
		backgroundView.contentMode = UIViewContentModeScaleToFill;
		backgroundView.image = self.cellBackgroundImage;
		cell.selectedBackgroundView = backgroundView;
	}

    UIButton				*infoButton = [UIButton buttonWithType: UIButtonTypeInfoLight];
	
	#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
		if (RUNNING_ON_70) infoButton.tintColor = [UIColor whiteColor];
	#endif
	infoButton.tag = indexPath.section;
	[infoButton addTarget: self action: @selector(showDocumentInfo:) forControlEvents: UIControlEventTouchUpInside];
	cell.accessoryView = infoButton;
	
	return cell;
}

- (void) showDocumentInfo: (UIView *) view {
	MMSF_ContentVersion		*doc = self.categoryContents[view.tag];
	[DSA_DocumentDetailsView showInfoForDocument: doc fromView: view];
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
//	return 1;
	return self.categoryContents.count;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
//    return self.categoryContents.count;
	return 1;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    MMSF_ContentVersion *contentVersion = self.categoryContents[indexPath.section];
    UIViewController *controller = [DSA_MediaDisplayViewController controllerForItem:contentVersion withDelegate:self];
	
    [self presentViewController:controller animated:YES completion:nil];
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) sectionIndex {
	UIView			*view = [[UIView alloc] initWithFrame: CGRectZero];
	view.backgroundColor = [UIColor clearColor];
	return view;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section {
	return 20;
}

#pragma mark - DSA_MediaDisplayViewControllerDelegate

- (void)donePressed:(DSA_MediaDisplayViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
