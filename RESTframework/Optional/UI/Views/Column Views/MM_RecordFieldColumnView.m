//
//  MM_RecordFieldColumnView.m
//
//  Created by Ben Gottlieb on 12/22/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_RecordFieldColumnView.h"
#import "NSString+MM_String.h"
#import "MM_WebViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface MM_ColumnEditTextField : UITextField
@property (nonatomic, strong) NSString *key;
@end

@interface MM_ColumnEditSwitch : UISwitch
@property (nonatomic, strong) NSString *key;
@end

@interface MM_RecordFieldColumnView ()
@property (nonatomic) CGFloat calculatedDividerPosition;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) MM_SFObjectDefinition *objectDefinition;
@property (nonatomic, strong) NSString *lastFirstResponderKey;
@property (nonatomic, strong) NSMutableDictionary *modifiedFields;
@property (nonatomic) BOOL settingFirstResponder;
@property (nonatomic, strong) NSMutableDictionary *textFields;
- (void) postInitSetup;
- (void) setupSubviews;
@end


@implementation MM_RecordFieldColumnView
@synthesize showMultipleLines, labelFont = _labelFont, contentFont = _contentFont, record = _record, fields = _fields, labelColor = _labelColor, contentColor = _contentColor, dividerPosition = _dividerPosition, noFixedDivider, autoCalculateDivider, calculatedDividerPosition;
@synthesize labelTextAlignment = _labelTextAlignment, contentTextAlignment = _contentTextAlignment, contentHeight = _contentHeight, labelContentSpacing = _labelContentSpacing, useCenterAlignedLabels = _useCenterAlignedLabels, viewController;
@synthesize buttons, objectDefinition = _objectDefinition, columnViewDelegate, editing = _editing, lastFirstResponderKey, lineHeight = _lineHeight;
@synthesize textFields,modifiedFields,settingFirstResponder;


- (id) initWithFrame: (CGRect) frame {
    if ((self = [super initWithFrame: frame])) [self postInitSetup];
    return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder {
	if ((self = [super initWithCoder: aDecoder])) [self postInitSetup];
	return self;
}

- (void) postInitSetup {
	self.labelFont = [UIFont boldSystemFontOfSize: 15];
	self.contentFont = [UIFont systemFontOfSize: 15];
	self.labelColor = [UIColor blackColor];
	self.contentColor = [UIColor darkGrayColor];
	self.autoCalculateDivider = YES;
	self.labelTextAlignment = NSTextAlignmentLeft;
	self.contentTextAlignment = NSTextAlignmentRight;
	self.clipsToBounds = YES;
}

//=============================================================================================================================
#pragma mark Layout
- (void) reloadData {
	[self setNeedsLayout];
}

- (void) setNeedsLayout {
	self.lastFirstResponderKey = nil;
	for (MM_ColumnEditTextField *field in self.subviews) {
		if ([field isKindOfClass: [MM_ColumnEditTextField class]] && field.isFirstResponder) {
			self.lastFirstResponderKey = field.key;
			break;
		}
	}

	[super setNeedsLayout];
}

- (void) layoutSubviews {
	[self setupSubviews];
}

- (MM_SFObjectDefinition *) objectDefinition {
	if (_objectDefinition == nil) {
		_objectDefinition = self.record.definition;
	}
	return _objectDefinition;
}


- (NSString *) labelForField: (NSDictionary *) field {
	NSString				*label = [field objectForKey: @"label"];
	NSString				*key = [field objectForKey: @"key"];

	if (label == nil) {
        if ([key rangeOfString: @"."].location != NSNotFound) key = [[key componentsSeparatedByString: @"."] objectAtIndex: 0];
        
		label = [self.objectDefinition labelForField: key];
		if (label == nil && [key isKindOfClass: [NSString class]]) label = key;
	}
	return label;
}

- (BOOL) fieldIsReadOnly: (NSString *) field {
	NSDictionary						*info = [self.objectDefinition infoForField: field];
	
	if (self.record.existsOnSalesforce && ![[info objectForKey: @"updateable"] boolValue]) return YES;
	if (!self.record.existsOnSalesforce && ![[info objectForKey: @"createable"] boolValue]) return YES;
	return NO;
}

- (void) setupSubviews {
	for (UIView *view in self.subviews.copy) {
		if ([view isKindOfClass: [MM_ColumnEditTextField class]]) {
			view.hidden = YES;
		} else {
			[view removeFromSuperview];
		}
	}

	self.buttons = [NSMutableArray array];
	
	CGFloat					top = 0.0, lineHeight = MAX(self.labelFont.lineHeight, self.contentFont.lineHeight);
	CGFloat					width = self.bounds.size.width - self.labelContentSpacing, interFieldSpacing = 2;
	
	if (self.lineHeight) lineHeight = self.lineHeight;
	
	if (self.autoCalculateDivider || self.dividerPosition == 0.0) {
		self.calculatedDividerPosition = 0;
		
		for (NSDictionary *dictionary in self.fields) {
			NSString				*label = [self labelForField: dictionary];
			CGFloat					labelWidth = [label sizeWithFont: self.labelFont].width + 5;
			
			if (labelWidth > self.calculatedDividerPosition) self.calculatedDividerPosition = labelWidth;
		}
		
		CGFloat				maxLabelWidth = width * 0.75;
		if (self.calculatedDividerPosition > maxLabelWidth) self.calculatedDividerPosition = maxLabelWidth;
	} else 
		self.calculatedDividerPosition = self.dividerPosition;
	
	MM_ColumnEditTextField			*focusedField = nil;
	
	for (NSDictionary *dictionary in self.fields) {
		NSString				*key = [dictionary objectForKey: @"key"];
		NSString				*label = [self labelForField: dictionary];
		UILabel					*labelLabel, *contentLabel;
		CGFloat					labelWidth = self.noFixedDivider ? width : self.calculatedDividerPosition;
		NSInteger				maxLines = self.showMultipleLines ? 1000 : 1;
		CGFloat					fieldHeight = 0;
		NSString				*content = nil, *format = [dictionary objectForKey: @"format"];
		NSTextAlignment			alignment = _contentTextAlignment;
		UIFont					*labelFont = self.labelFont, *contentFont = self.contentFont;
		BOOL					editable = [[dictionary objectForKey: @"editable"] boolValue] && ![self fieldIsReadOnly: key] && self.editing;
		
		if ([dictionary objectForKey: @"max-label-width"]) labelWidth = MIN(labelWidth, [[dictionary objectForKey: @"max-label-width"] floatValue]);
		
		if ([dictionary objectForKey: @"alignment"]) alignment = [[dictionary objectForKey: @"alignment"] intValue];
		if ([dictionary objectForKey: @"contentFont"]) contentFont = [dictionary objectForKey: @"contentFont"];
		if ([dictionary objectForKey: @"labelFont"]) labelFont = [dictionary objectForKey: @"labelFont"];
		
#if 0
        if (/* DISABLES CODE */ (0) && [dictionary objectForKey: @"fixed"] == nil && [dictionary objectForKey: @"block"] == nil && format == nil && key) {
			NSAttributeType				type = [self.objectDefinition typeOfField: key];
			if (type == NSBooleanAttributeType) format = FIELD_FORMAT_BOOLEAN;
		}
#endif
		
		if ([self.record hasValueForKeyPath: key]) {
			if ([self.modifiedFields objectForKey: key]) {
				content = [self.modifiedFields objectForKey: key];
			} else if ([format isEqual: FIELD_FORMAT_INTEGER]) {
				NSInteger					value = [[self.record stringForKeyPath: key] intValue];
				content = $S(@"%d", (UInt16) value);
			} else 		if ([format isEqual: FIELD_FORMAT_PERCENTAGE]) {
				CGFloat					value = [[self.record stringForKeyPath: key] floatValue];
				content = (value == floorf(value)) ? $S(@"%.0f%%", value) : $S(@"%.2f%%", value);
			} else if ([format isEqual: FIELD_FORMAT_CURRENCY]) {
				float					value = [[self.record stringForKeyPath: key] floatValue];
				content = [NSString currencyStringForAmountWithoutDecimal: value];
			} else if ([dictionary objectForKey: @"block"]) {
				//FIXME
				//content = ((recordFieldCalculationBlock) ([[dictionary objectForKey: @"block"] block]))(self.record);
			} else if ([dictionary objectForKey: @"fixed"])
				content = [dictionary objectForKey: @"fixed"];
			else if (key)
				content = [self.record stringForKeyPath: key];
		} else {
			content = $S(@"Missing <%@> Key", key);
		}
		
		if ([dictionary objectForKey: @"max-lines"]) maxLines = [[dictionary objectForKey: @"max-lines"] intValue];
		else if ([dictionary objectForKey: @"lines"]) maxLines = [[dictionary objectForKey: @"lines"] intValue];
		
		labelLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, top, labelWidth - self.labelContentSpacing / 2, 1000.0)];
		labelLabel.text = label;
		labelLabel.textColor = self.labelColor;
		labelLabel.font = labelFont;
		labelLabel.backgroundColor = self.backgroundColor;
		labelLabel.numberOfLines = 100;
		labelLabel.textAlignment = _labelTextAlignment;
		labelLabel.lineBreakMode = NSLineBreakByWordWrapping;
		[labelLabel autosizeForExistingWidth: labelWidth];
		fieldHeight = labelLabel.bounds.size.height + interFieldSpacing;
		
		if (self.noFixedDivider) labelWidth = labelLabel.bounds.size.width;

		contentLabel = [[UILabel alloc] initWithFrame: CGRectMake(labelWidth + self.labelContentSpacing / 2, top, (width - labelWidth) - self.labelContentSpacing, MAX(1, maxLines) * lineHeight)];
		contentLabel.text = content;
		contentLabel.textAlignment = alignment;
		contentLabel.textColor = self.contentColor;
		contentLabel.font = contentFont;
		contentLabel.numberOfLines = maxLines;
		contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
		contentLabel.backgroundColor = self.backgroundColor;

		CGRect				frame = contentLabel.frame;
		frame.size.height = MIN(maxLines * lineHeight, MAX(contentLabel.sizeOfCurrentTextInExistingWidth.height, lineHeight));
		contentLabel.frame = frame;
		
		if ([dictionary objectForKey: @"lines"] || [dictionary objectForKey: @"min-lines"]) {
			CGFloat				labelHeight = [dictionary objectForKey: @"lines"] ? [[dictionary objectForKey: @"lines"] intValue] : [[dictionary objectForKey: @"min-lines"] intValue];
			CGRect				frame = contentLabel.frame;
			
			labelHeight *= self.labelFont.lineHeight;
			
			if ([dictionary objectForKey: @"lines"] && frame.size.height > labelHeight) {
				frame.size.height = labelHeight;
				contentLabel.frame = frame;
			}
			fieldHeight = MAX(fieldHeight, labelHeight + interFieldSpacing);
		}
		
		fieldHeight = MAX(fieldHeight, contentLabel.bounds.size.height + interFieldSpacing);
		
		//if ((top + fieldHeight) > self.bounds.size.height) break;
		
		[self addSubview: labelLabel];
		
		if ([format isEqual: FIELD_FORMAT_BOOLEAN]) {
			MM_ColumnEditSwitch					*boolSwitch = [[MM_ColumnEditSwitch alloc] initWithFrame: contentLabel.frame];
			
			boolSwitch.center = CGPointMake(CGRectGetMaxX(contentLabel.frame) - boolSwitch.bounds.size.width / 2, boolSwitch.center.y);
			boolSwitch.key = key;
			[boolSwitch addTarget: self action: @selector(fieldSwitchToggled:) forControlEvents: UIControlEventValueChanged];
			boolSwitch.on = [[self.record stringForKeyPath: key] boolValue];
			boolSwitch.enabled = editable;
			if (!editable) boolSwitch.onTintColor = [UIColor grayColor];
			[self addSubview: boolSwitch];
		} else if (editable) {
			CGRect						frame = contentLabel.frame;
			CGFloat						width = [[dictionary objectForKey: @"width"] floatValue] ?: frame.size.width;
			
			frame.origin.x += (frame.size.width - width);
			frame.size.width = width;
			
			MM_ColumnEditTextField		*field = [self.textFields objectForKey: key];
			
			if (field == nil) {
				field = [[MM_ColumnEditTextField alloc] initWithFrame: CGRectInset(frame, 0, 0)];
				field.key = key;
				field.delegate = self;
				field.borderStyle = UITextBorderStyleNone;
				field.layer.borderColor = [UIColor grayColor].CGColor;
				field.layer.borderWidth = 1.0;
				field.autoresizingMask = contentLabel.autoresizingMask;
				field.textAlignment = contentLabel.textAlignment;
				field.textColor = contentLabel.textColor;
				field.font = contentLabel.font;
				
				if (self.textFields == nil) self.textFields = [NSMutableDictionary dictionary];
				[self.textFields setObject: field forKey: key];
				[self addSubview: field];
			}
			field.hidden = NO;
			field.text = contentLabel.text;
			
			if ([key isEqual: self.lastFirstResponderKey]) focusedField = field;
		} else
			[self addSubview: contentLabel];

		if (self.editing && [[dictionary objectForKey: @"tappable"] boolValue]) {
			__weak MM_RecordFieldColumnView	*view = self;
			SA_BlockButton					*blocker = [SA_BlockButton buttonWithType: UIButtonTypeCustom];
			
			blocker.frame = CGRectUnion(labelLabel.frame, contentLabel.frame);
			CGRect							contentFrame = blocker.frame;
			[blocker addBlock: ^{
				if ([view.columnViewDelegate respondsToSelector: @selector(columnView:didTapField:withFrame:)]) {
					[view saveCurrentField];
					[view.columnViewDelegate columnView: view didTapField: key withFrame: contentFrame];
				}
			} forControlEvent: UIControlEventTouchUpInside];
			
			blocker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
			blocker.backgroundColor = [UIColor clearColor];
			[self addSubview: blocker];
			
			if ([dictionary objectForKey: @"rightAdornment"]) {
				CGRect				newContentFrame = contentLabel.frame;
				UIImage				*image = [dictionary objectForKey: @"rightAdornment"];
				
				[blocker setImage: image forState: UIControlStateNormal];;
				newContentFrame.size.width -= (image.size.width + 5);
				blocker.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
				contentLabel.frame = newContentFrame;
			}
		}
		
		if ([format isEqual: FIELD_FORMAT_EMAIL] || [format isEqual: FIELD_FORMAT_WEBSITE]) {
			SA_BlockButton				*button = [SA_BlockButton buttonWithType: UIButtonTypeCustom];
			
			if (self.viewController == nil && [format isEqual: FIELD_FORMAT_EMAIL]) {
				MMLog(@"****** You MUST connect the viewController outlet on your column view in order to use email formats %@", @"");
			}

			button.frame = contentLabel.frame;
			button.showsTouchWhenHighlighted = YES;
			[button addBlock: ^{
				if ([format isEqual: FIELD_FORMAT_EMAIL]) {
					if (![MFMailComposeViewController canSendMail]) return;
					MFMailComposeViewController				*controller = [[MFMailComposeViewController alloc] init];
					
					[controller setToRecipients: $A(content)];
					controller.mailComposeDelegate = self;
					[self.viewController presentViewController: controller animated: YES completion: nil];
				} else if ([format isEqual: FIELD_FORMAT_WEBSITE]) {
					NSURL				*url = [MM_WebViewController sanitizedURLFromString: content];
					[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_DisplayWebpage object: url];
				}
			} forControlEvent: UIControlEventTouchUpInside];
			[self addSubview: button];
			
			UIView					*underline = [[UIView alloc] initWithFrame: CGRectMake(0, contentLabel.bounds.size.height - 1, [contentLabel.text sizeWithFont: contentLabel.font].width, 1)];
			underline.backgroundColor = [UIColor blackColor];
			[contentLabel addSubview: underline];
		}
		
		top += fieldHeight;
	}
	CGRect			frame = self.frame;
	
	frame.size.height = top;
	self.frame = frame;
	self.contentHeight = top;
	self.userInteractionEnabled = YES;
	
	if (focusedField) [focusedField becomeFirstResponder];
}

//=============================================================================================================================
#pragma mark Email delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissViewControllerAnimated: YES completion: nil];
}

//=============================================================================================================================
#pragma mark Editing
- (void) setEditing: (BOOL) editing animated: (BOOL) animated {
	[self resignFirstResponderForAllChildren];
	self.editing = editing;
}

- (void) setEditing: (BOOL) editing {
	if (!editing) {
		for (MM_ColumnEditTextField *field in self.textFields) { [[self.textFields objectForKey: field] removeFromSuperview]; }
		self.textFields = nil;
		self.modifiedFields = nil;
	}
	_editing = editing;
	[self reloadData];
}


//=============================================================================================================================
/*
#pragma mark Responder stuff
- (BOOL) canBecomeFirstResponder {
	return self.editing;
}

- (BOOL) becomeFirstResponder {
	[super becomeFirstResponder];
	self.settingFirstResponder = YES;
	for (UITextView *textView in self.subviews) {
		if ([textView isKindOfClass: [MM_ColumnEditTextField class]] && [textView canBecomeFirstResponder]) {
			if ([textView becomeFirstResponder]) {
				self.settingFirstResponder = NO;
				return YES;
			}
		}
	}
	self.settingFirstResponder = NO;
	return NO;
}

- (BOOL) resignFirstResponder {
	if (self.settingFirstResponder) return NO;
	
	for (UITextField *textField in self.subviews) {
		if ([textField isKindOfClass: [MM_ColumnEditTextField class]]) {
			if (!textField.isFirstResponder) continue;
			if (![self textFieldShouldEndEditing: textField]) return NO;
			textField.delegate = nil;
			[textField resignFirstResponder];
			[self textFieldDidEndEditing: textField];
			textField.delegate = self;
		}
	}
	return [super resignFirstResponder];
}
*/

- (BOOL) resignFirstResponder {
	for (UITextField *textField in self.subviews) {
		if ([textField isKindOfClass: [MM_ColumnEditTextField class]]) {
			if (!textField.isFirstResponder) continue;
			if (![self textFieldShouldEndEditing: textField]) return NO;
			textField.delegate = nil;
			[textField resignFirstResponder];
			[self textFieldDidEndEditing: textField];
			textField.delegate = self;
		}
	}
	return [super resignFirstResponder];
}

//=============================================================================================================================
#pragma mark Properties
- (void) setFields: (NSArray *) fields {
	_fields = fields;
	self.modifiedFields = nil;
}

- (void) setRecord: (MMSF_Object *) record {
	_record = record;
	self.modifiedFields = nil;
}

- (CGFloat) contentHeight {
	if (_contentHeight) return _contentHeight;
	[self setupSubviews];
	return _contentHeight;
}

- (void) setLabelFont: (UIFont *) labelFont {
	_labelFont = labelFont;
	[self setNeedsLayout];
}

- (void) setLabelColor: (UIColor *) labelColor {
	_labelColor = labelColor;
	[self setNeedsLayout];
}

- (void) setContentFont: (UIFont *) contentFont {
	_contentFont = contentFont;
	[self setNeedsLayout];
}

- (void) setContentColor: (UIColor *) contentColor {
	_contentColor = contentColor;
	[self setNeedsLayout];
}

- (void) setLabelTextAlignment: (NSTextAlignment) labelTextAlignment {
	_labelTextAlignment = labelTextAlignment;
	[self setNeedsLayout];
}

- (void) setContentTextAlignment: (NSTextAlignment) contentTextAlignment {
	_contentTextAlignment = contentTextAlignment;
	[self setNeedsLayout];
}

- (void) setLabelContentSpacing:(CGFloat)labelContentSpacing {
	_labelContentSpacing = labelContentSpacing;
	[self setNeedsLayout];
}

- (void) setUseCenterAlignedLabels: (BOOL) useCenterAlignedLabels {
	_useCenterAlignedLabels = useCenterAlignedLabels;
	if (useCenterAlignedLabels) {
		self.labelTextAlignment = NSTextAlignmentRight;
		self.contentTextAlignment = NSTextAlignmentLeft;
		self.labelContentSpacing = 10;
	} else {
		self.labelTextAlignment = NSTextAlignmentLeft;
		self.contentTextAlignment = NSTextAlignmentRight;
		self.labelContentSpacing = 0;
	}
	[self setNeedsLayout];
}

- (void) setDividerPosition: (CGFloat) dividerPosition {
	_dividerPosition = dividerPosition;
	self.autoCalculateDivider = (dividerPosition == 0);
}

- (BOOL)textFieldShouldBeginEditing:(MM_ColumnEditTextField *)aTextField {
	if ([self.columnViewDelegate respondsToSelector: @selector(columnView:textFieldShouldBeginEditing:withKey:)]) {
		return [self.columnViewDelegate columnView: self textFieldShouldBeginEditing: aTextField withKey: aTextField.key];
	}
	return YES;
}

- (BOOL) textFieldShouldEndEditing: (MM_ColumnEditTextField *)textField {
	if ([self.columnViewDelegate respondsToSelector: @selector(columnView:textFieldShouldEndEditing:withKey:)]) {
		return [self.columnViewDelegate columnView: self textFieldShouldEndEditing: textField withKey: textField.key];
	}
	
	
	return YES;
}

- (BOOL) textField: (MM_ColumnEditTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([self.columnViewDelegate respondsToSelector: @selector(columnView:shouldChangeTextField:charactersInRange:replacementString:withKey:)]) {
		return [self.columnViewDelegate columnView: self shouldChangeTextField: textField charactersInRange: range replacementString: string withKey: textField.key];
	}
	return YES;
}


- (void) textFieldDidEndEditing: (MM_ColumnEditTextField *) textField {
	if ([self.columnViewDelegate respondsToSelector: @selector(columnView:textFieldDidEndEditing:withKey:)]) {
		[self.columnViewDelegate columnView: self textFieldDidEndEditing: textField withKey: textField.key];
	}
	
	if (self.modifiedFields == nil) self.modifiedFields = [NSMutableDictionary dictionary];
	[self.modifiedFields setObject: textField.text forKey: textField.key];
}

- (void) saveCurrentField {
	for (MM_ColumnEditTextField *field in self.subviews) {
		if ([field isKindOfClass: [MM_ColumnEditTextField class]] && [field isFirstResponder]) {
			field.delegate = nil;
			[self textFieldShouldEndEditing: field];
			[self textFieldDidEndEditing: field];
		}
	}
}

- (void) updateField: (NSString *) field {
	[self setNeedsLayout];
}

- (void) fieldSwitchToggled: (MM_ColumnEditSwitch *) boolSwitch {
	if ([self.columnViewDelegate respondsToSelector: @selector(columnView:didChangeField:toBooleanValue:)])
		[self.columnViewDelegate columnView: self didChangeField: boolSwitch.key toBooleanValue: boolSwitch.on];
}
@end

@implementation MM_ColumnEditSwitch
@synthesize key;
@end

@implementation MM_ColumnEditTextField
@synthesize key;
@end

#pragma clang diagnostic pop
