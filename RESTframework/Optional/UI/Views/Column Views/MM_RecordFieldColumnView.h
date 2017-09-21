//
//  MM_RecordFieldColumnView.h
//
//  Created by Ben Gottlieb on 12/22/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MM_Headers.h"
#import <MessageUI/MessageUI.h>

/*******************************************************************************************************************
 
	When assigning fields to a column view, use an array of dictionaries. Available keys are:
 
	key				The key to pull out of the assigned record, using -stringForKeyPath.
					If this is an array, the first element will be used as a format string,
					and remaining elements will be filled using -stringForKeyPath.
 
	block			an SA_BlockWrapper containing a block which takes a single argument, the 
					column's MMSF_Object (record), and returns a string to display.
 
	label			the label to use next to the field contents. If none is provided, the key is used
	
	max-label-width	maximum width, in points, of the label
	
	lines			a fixed number of lines to display. Defaults to 1 if not present
 
	max-lines		for dynamic height fields, the maximum number of lines to display
 
	min-lines		for dynamic height fields, the minimum number of lines to display

	format			one of the constants listed below. Forces the field to display in a given format.
					email and website fields are underlined, percentage fields are displayed with 
					2 decimal places and a % sign, and currency fields include the localized currency,
					but no decimal places
 
	editable		a boolean. If set, will convert the field to editable when the -setEditing: method fires.
	tappable		a boolean. If set, will send -columnView:didTapField:withFrame: when the field is touched with editing turned on.
 
	rightAdornment	an image to stick on the right of a tappable field
 
 *******************************************************************************************************************/

#define FIELD_FORMAT_EMAIL				@"email"
#define FIELD_FORMAT_PERCENTAGE			@"percentage"
#define FIELD_FORMAT_CURRENCY			@"currency"
#define FIELD_FORMAT_WEBSITE			@"website"
#define FIELD_FORMAT_INTEGER			@"integer"
#define FIELD_FORMAT_BOOLEAN			@"boolean"

@class MM_RecordFieldColumnView;

@protocol MM_RecordFieldColumnViewDelegate <NSObject>
@optional
- (void) columnView: (MM_RecordFieldColumnView *) view didChangeField: (NSString *) key toBooleanValue: (BOOL) value;
- (void) columnView: (MM_RecordFieldColumnView *) view didTapField: (NSString *) key withFrame: (CGRect) frame;
- (BOOL) columnView: (MM_RecordFieldColumnView *) view textFieldShouldBeginEditing: (UITextField *) textField withKey: (NSString *) key;
- (BOOL) columnView: (MM_RecordFieldColumnView *) view textFieldShouldEndEditing: (UITextField *) textField withKey: (NSString *) key;
- (void) columnView: (MM_RecordFieldColumnView *) view textFieldDidEndEditing: (UITextField *) textField withKey: (NSString *) key;
- (BOOL) columnView: (MM_RecordFieldColumnView *) view shouldChangeTextField: (UITextField *) textField charactersInRange: (NSRange) range replacementString: (NSString *) string withKey: (NSString *) key;
@end

@interface MM_RecordFieldColumnView : UIView <MFMailComposeViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) MMSF_Object *record;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, weak) id <MM_RecordFieldColumnViewDelegate> columnViewDelegate;
@property (nonatomic, strong) UIFont *labelFont, *contentFont;
@property (nonatomic, strong) UIColor *labelColor, *contentColor;
@property (nonatomic) BOOL showMultipleLines, noFixedDivider, autoCalculateDivider, useCenterAlignedLabels;
@property (nonatomic) CGFloat dividerPosition, contentHeight, labelContentSpacing, lineHeight;
@property (nonatomic) NSTextAlignment labelTextAlignment, contentTextAlignment;
@property (nonatomic, weak) IBOutlet UIViewController *viewController;
@property (nonatomic) BOOL editing;

- (void) reloadData;
- (void) setEditing: (BOOL) editing animated: (BOOL) animated;
- (void) saveCurrentField;
- (void) updateField: (NSString *) field;
@end
