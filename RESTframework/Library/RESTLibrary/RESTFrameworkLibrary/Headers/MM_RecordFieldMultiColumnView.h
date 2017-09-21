//
//  MM_RecordFieldMultiColumnView.h
//
//  Created by Ben Gottlieb on 12/23/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MM_Headers.h"
#import "MM_RecordFieldColumnView.h"

/*******************************************************************************************************************

	This is merely a container for a given number of MM_RecordFieldColumnViews. 
	
	the Fields property is an array of arrays. Each array represents a column. All fields within
	are as defined in MM_RecordFieldsColumnView.h
 
 
*******************************************************************************************************************/

//fields is an array of arrays, each aimed at an MM_RecordFieldColumnView

@interface MM_RecordFieldMultiColumnView : UIScrollView

@property (nonatomic, strong) MMSF_Object *record;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong, readonly) NSArray *columnViews;
@property (nonatomic, strong) UIFont *labelFont, *contentFont;
@property (nonatomic, strong) UIColor *labelColor, *contentColor, *columnBackgroundColor;
@property (nonatomic) BOOL showMultipleLines, noFixedDivider, autoCalculateDivider;
@property (nonatomic) CGFloat dividerPosition, horizontalSpacing, labelContentSpacing, lineHeight;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) NSTextAlignment labelTextAlignment, contentTextAlignment;
@property (nonatomic) BOOL useCenterAlignedLabels;
@property (nonatomic) CGRect contentFrame;
@property (nonatomic, weak) IBOutlet UIViewController *viewController;
@property (nonatomic) BOOL editing;
@property (nonatomic, weak) id <MM_RecordFieldColumnViewDelegate> columnViewDelegate;

- (void) postInitSetup;
- (void) reloadData;

- (void) setEditing: (BOOL) editing animated: (BOOL) animated;
- (void) saveCurrentField;
- (void) updateField: (NSString *) field;
@end
