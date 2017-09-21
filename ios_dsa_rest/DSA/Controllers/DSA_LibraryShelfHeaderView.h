//
//  ZM_LibraryShelfHeaderView.h
//  Zimmer
//
//  Created by Ben Gottlieb on 5/12/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OBGradientView.h"

@interface DSA_LibraryShelfHeaderView : OBGradientView <UIActionSheetDelegate> {
    
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic) BOOL isFavoriteShelfHeader, isCreateNewShelfHeader; 
@property (nonatomic, assign) UIButton *addButton, *deleteButton;
@property (nonatomic, assign) UIViewController *viewController;
@end
 