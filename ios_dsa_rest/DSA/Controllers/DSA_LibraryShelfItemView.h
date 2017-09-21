//
//  ZM_LibraryShelfItemView.h
//  Zimmer
//
//  Created by Ben Gottlieb on 5/7/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_ContentVersion.h"
@class MMSF_ContentVersion, DSA_LibraryShelfView;

@interface DSA_LibraryShelfItemView : SA_LazyLoadingScrollViewPage <UIActionSheetDelegate>
{
    
}

@property (nonatomic, assign) DSA_LibraryShelfView *parent;
@property (nonatomic, retain) MMSF_ContentVersion *contentItem;
@property (nonatomic, assign) UIViewController *viewController;

+ (id) viewWithContentItem: (MMSF_ContentVersion *) item;
+ (id) viewWithParent: (DSA_LibraryShelfView *) parent;
+ (CGSize) size;

@end
