//
//  UIBarButtonItem+SA_Additions.h
//
//  Created by Ben Gottlieb on 3/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^barButtonItemArgumentBlock)(UIBarButtonItem *button);


@interface UIBarButtonItem (SA_SA_Additions)

+ (id) SA_itemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) SA_itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) SA_itemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) SA_borderlessItemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) SA_borderlessItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) SA_borderlessItemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) SA_itemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block;
+ (id) SA_itemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block;
+ (id) SA_itemWithImage: (UIImage *) image block: (barButtonItemArgumentBlock) block;

+ (id) SA_doneItemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) SA_doneItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) SA_doneItemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) SA_doneItemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block;
+ (id) SA_doneItemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block;
+ (id) SA_doneItemWithImage: (UIImage *) image block: (barButtonItemArgumentBlock) block;

+ (id) SA_itemWithTitle: (NSString *) title target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style;
+ (id) SA_itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style;
+ (id) SA_itemWithImage: (UIImage *) image target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style;

+ (id) SA_flexibleSpacer;
+ (id) SA_spacer;
+ (id) SA_spacerOfWidth: (float) width;

+ (id) SA_itemWithView: (UIView *) view;
+ (id) SA_activityIndicatorItemWithStyle: (UIActivityIndicatorViewStyle) style forToolbar: (BOOL) forToolbar;
@end
