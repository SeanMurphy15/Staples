//
//  UIActionSheet+SA_Additions.h
//
//  Created by Ben Gottlieb on 11/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^actionSheetButtonSelectedBlock)(NSInteger buttonIndex);


@interface UIActionSheet (SA_AdditionsForButtons)

@property (nonatomic, copy) actionSheetButtonSelectedBlock SA_buttonSelectBlock;
@property (nonatomic) BOOL shouldRunBlockAfterDismissal;

- (void) addButtonWithTitle: (NSString *) title andSA_Tag: (NSInteger) tag;
- (NSInteger) SA_TagForButtonAtIndex: (NSUInteger) index;
- (void) clearSA_Tags;
- (void) showFromView: (UIView *) view withSA_ButtonSelectedBlock: (intArgumentBlock) block;
- (void) showFromBarButtonItem: (UIBarButtonItem *) item withSA_ButtonSelectedBlock: (intArgumentBlock) block;

- (void) SA_showFromView: (UIView *) view;
@end
