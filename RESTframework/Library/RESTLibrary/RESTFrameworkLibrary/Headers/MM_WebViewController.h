//
//  MM_WebViewController.h
//  Cat MCV
//
//  Created by Ben Gottlieb on 3/31/12.
//  Copyright 2012 Model Metrics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface MM_WebViewController : UIViewController

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

+ (void) setOpenLinksInsideApp: (BOOL) openInside;
+ (void) displayURL: (NSURL *) url inViewController: (UIViewController *) controller animated: (BOOL) animated;
+ (NSURL *) sanitizedURLFromString: (NSString *) string;
+ (id) controllerWithDocumentPath: (NSString *) filePath;

+ (void) setLockedToPortrait: (BOOL) lockedToPortrait;
+ (void) setLockedToLandscape: (BOOL) lockedToLandscape;

- (IBAction) done: (id) sender;

@end


@interface UINavigationController (MM_WebViewController)
@property (nonatomic, readonly) MM_WebViewController *webViewController;
@property (nonatomic, strong) NSURL *url;
@end
