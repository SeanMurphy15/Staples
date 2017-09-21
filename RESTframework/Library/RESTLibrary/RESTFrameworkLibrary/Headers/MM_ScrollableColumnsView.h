//
//  MM_ScrollableColumnsView.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/29/11.
//  Copyright (c) 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MM_Headers.h"


@interface MM_ScrollableColumnsView : UIScrollView <UIScrollViewDelegate>

+ (id) headerViewWithFrame: (CGRect) frame displayingObjectType: (MM_SFObjectDefinition *) object;
+ (id) viewWithFrame: (CGRect) frame displayingObject: (MMSF_Object *) object ofType: (MM_SFObjectDefinition *) objectType;

@property (nonatomic, strong) MM_SFObjectDefinition *objectDefinition;
@property (nonatomic, strong) MMSF_Object *object;
@property (nonatomic) BOOL isHeader;
@property (nonatomic, retain) UIColor *evenColumnBackgroundColor, *oddColumnBackgroundColor, *evenColumnTextColor, *oddColumnTextColor;
@property (nonatomic, retain) UIFont *headerFont, *contentFont;
@end
