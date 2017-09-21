//
//  DSA_PreviewViewController.h
//  DSA
//
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

#import "DSA_ContactSelectionController.h"

@class MMSF_ContentVersion;

@interface DSA_PreviewViewController:QLPreviewController<DSA_ContactSelectionControllerDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) MMSF_ContentVersion *item;
@property (nonatomic, strong) UINavigationItem *privateItem;

- (instancetype)initWithItem:(MMSF_ContentVersion *)item;

@end
