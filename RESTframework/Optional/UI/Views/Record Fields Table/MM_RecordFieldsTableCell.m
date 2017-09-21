//
//  MM_RecordFieldsTableCell.m
//
//  Created by Ben Gottlieb on 6/1/13.
//

#import "MM_RecordFieldsTableCell.h"
#import "MM_RecordFieldsTable.h"
#import "MM_Headers.h"

@interface MM_RecordFieldsTableCell () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UILabel *labelLabel, *valueLabel;
@property (nonatomic, strong) UISwitch *valueSwitch;
@property (nonatomic, strong) UITextField *valueField;
@property (nonatomic, strong) UIButton *valueButton;
@property (nonatomic, strong) NSDictionary *attributeInfo;
@property (nonatomic) NSAttributeType attributeType;
@property (nonatomic, strong) NSArray *picklistOptions;
@property (nonatomic) BOOL isSwitch, booleanValue, usesTextView;
@property (nonatomic, strong) UITextView *valueTextView;

@end

@implementation MM_RecordFieldsTableCellTextField
- (CGRect) textRectForBounds: (CGRect) bounds {
	if (bounds.size.height < self.font.lineHeight || bounds.size.width < 10) return bounds;
	return CGRectInset(bounds, 5, 0);
}
- (CGRect) editingRectForBounds: (CGRect) bounds { return [self textRectForBounds: bounds]; }
@end

static UIImage		*s_switchOnImage = nil, *s_switchOffImage = nil;

@implementation MM_RecordFieldsTableCell

+ (void) load {
	@autoreleasepool {
		if (RUNNING_ON_60 && [[NSLocale preferredLanguages][0] isEqual: @"en"]) {
			s_switchOnImage	= [UIImage imageNamed: @"switch_on_image.png"];
			s_switchOffImage = [UIImage imageNamed: @"switch_off_image.png"];
		}
	}
}
//=============================================================================================================================
#pragma mark Factory
+ (MM_RecordFieldsTableCell *) cell {
	MM_RecordFieldsTableCell				*cell = [[self alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: [self identifier]];
	
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.clipsToBounds = YES;
	
	return cell;
}

+ (MM_RecordFieldsTableCell *) cellWithObject:(MMSF_Object *) object inFieldsTable: (MM_RecordFieldsTable *) table {
	MM_RecordFieldsTableCell			*cell = [self cell];
	
	cell.object = object;
	cell.table = table;
	return cell;
}

+ (NSString *) identifier { return @"MM_RecordFieldsTableCell"; }

+ (CGFloat) height { return 44.0; }

//- (NSString *) reuseIdentifier { return [[self class] identifier]; }

//=============================================================================================================================
#pragma mark date picker
- (void) showDatePickerFromButton: (UIButton *) button {
	if ([self.table.recordFieldsTableDelegate respondsToSelector: @selector(recordFieldsTable:showDatePickerFromButton:forField:)] && [self.table.recordFieldsTableDelegate recordFieldsTable: self.table showDatePickerFromButton: button forField:self.keyPath]) return;
	
	UIView						*holder = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 216 + 44)];
	UIDatePicker				*picker = [[UIDatePicker alloc] initWithFrame: CGRectMake(0, 44, 320, 216)];
	UINavigationBar				*bar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, 44)];
	
	if (self.isDateTime)
		picker.datePickerMode = UIDatePickerModeDateAndTime;
	else
		picker.datePickerMode = UIDatePickerModeDate;
		
	[holder addSubview: picker];
	[holder addSubview: bar];
	
	bar.barStyle = UIBarStyleBlack;
	[bar pushNavigationItem: [[UINavigationItem alloc] initWithTitle: self.fieldInfo[MMFIELDS_TABLE_LABEL]] animated: NO];
	bar.topItem.rightBarButtonItem = [UIBarButtonItem itemWithSystemItem: UIBarButtonSystemItemSave block:^(id arg) {
		[self.table changeValue: picker.date forKeyPath: self.keyPath onObject: self.object];
		[self updateDisplayedContents];
		[UIPopoverController dismissAllVisibleSAPopoversAnimated: YES];
	}];
	
	picker.date = [self.table valueForKeyPath: self.keyPath onObject: self.object] ?: [NSDate date];
	
	[UIPopoverController presentSA_PopoverForView: holder fromRect: button.bounds inView: button permittedArrowDirections: UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight animated: YES];
}

//=============================================================================================================================
#pragma mark Picklist
- (NSArray *) picklistOptions {
	if (_picklistOptions == nil) {
		_picklistOptions = [self.table picklistOptionsForField: self.keyPath];
	}
	return _picklistOptions;
}
- (void) buttonPressed: (UIButton *) sender {
	if (self.isDate) {
		[self showDatePickerFromButton: sender];
		return;
	}
	
	if ([self.table.recordFieldsTableDelegate respondsToSelector: @selector(recordFieldsTable:showPicklistFromButton:forField:)] && ![self.table.recordFieldsTableDelegate recordFieldsTable: self.table showPicklistFromButton: sender forField:self.keyPath]) return;
	
	UITableView							*table = [[UITableView alloc] initWithFrame: CGRectMake(0, 0, 320, MIN(self.picklistOptions.count * 44, 700))];
	
	table.delegate = self;
	table.dataSource = self;
	table.scrollEnabled = YES;//table.bounds.size.height == 700;
	table.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	[UIPopoverController presentSA_PopoverForView: table fromRect: sender.bounds inView: sender permittedArrowDirections: UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight animated: YES].SA_didDismissBlock = ^(id controller) {
		[self.valueButton setTitle: self.buttonTitle forState: UIControlStateNormal];
	};
}

- (void) switchFlipped: (UISwitch *) sender {
	self.booleanValue = sender.isOn;
	if (self.isPicklist)
		[self.table changeValue: self.picklistOptions[self.booleanValue ? 1 : 0][@"value"] forKeyPath: self.keyPath onObject: self.object];
	else
		[self.table changeValue: @(sender.isOn) forKeyPath: self.keyPath onObject: self.object];
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: @"cell"];
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"cell"];
	cell.textLabel.text = self.picklistOptions[indexPath.row][MMFIELDS_TABLE_LABEL];
	cell.accessoryType = [([self.table valueForKeyPath: self.keyPath onObject: self.object] ?: @"") rangeOfString: self.picklistOptions[indexPath.row][@"value"]].location != NSNotFound ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView { return 1; }
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section { return [self.picklistOptions count]; }
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	if (self.isMultipicklist) {
		NSArray					*values = [[self.table valueForKeyPath: self.keyPath onObject: self.object] componentsSeparatedByString: @";"] ?: @[];
		NSString				*newValue = self.picklistOptions[indexPath.row][@"value"];
		BOOL					currentlySelected = [values containsObject: newValue];
		
		values = (currentlySelected) ? [values arrayByRemovingObject: newValue] : [values arrayByAddingObject: newValue];
		[self.table changeValue: [values componentsJoinedByString: @";"] forKeyPath: self.keyPath onObject: self.object];
		[tableView cellForRowAtIndexPath: indexPath].accessoryType = currentlySelected ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
		[self updateDisplayedContents];
	} else {
		[self.table changeValue: self.picklistOptions[indexPath.row][@"value"] forKeyPath: self.keyPath onObject: self.object];
		[self.table reloadRowForKey: self.keyPath];
		[UIPopoverController dismissAllVisibleSAPopoversAnimated: YES];
	}
	[self.table invalidateCachedPicklistsBasedOnField: self.keyPath];
}

- (void) updateValidityIndicator {
	self.displayInvalidFieldIndicator = (self.table.showRequiredFieldIndicators && ![self.table isFieldValid: self.fieldInfo]);
}
//=============================================================================================================================
#pragma mark Text Field Delegate
- (BOOL) textField: (UITextField *) textField shouldChangeCharactersInRange: (NSRange) range replacementString: (NSString *) string {
	if (self.isZIPCode) {
		NSCharacterSet				*numbers = [NSCharacterSet characterSetWithCharactersInString: @"0123456789"];
		
		if ([[string stringByTrimmingCharactersInSet: numbers] length]) return NO;
		return YES;
	}
	
	if (self.numberOfDecimalPlaces && string.length) {
		NSCharacterSet				*numbers = [NSCharacterSet characterSetWithCharactersInString: @"0123456789.-"];
		
		if ([[string stringByTrimmingCharactersInSet: numbers] length]) return NO;
		NSString			*newText = [textField.text stringByReplacingCharactersInRange: range withString: string];
		NSArray				*parts = [newText componentsSeparatedByString: @"."];
		
		if (parts.count == 2 && [parts[1] length] > self.numberOfDecimalPlaces) return NO;
	}

	NSString					*newText = [textField.text stringByReplacingCharactersInRange: range withString: string];
	
	if ([self.table.recordFieldsTableDelegate respondsToSelector: @selector(recordFieldsTable:shouldAllowText:forField:)] && ![self.table.recordFieldsTableDelegate recordFieldsTable: self.table shouldAllowText: newText forField: self.keyPath]) return NO;
	
	if (self.isPhone) {
		STATIC_CONSTANT(NSCharacterSet, numbers, [NSCharacterSet characterSetWithCharactersInString: @"0123456789-()."]);
		
		if ([string stringByTrimmingCharactersInSet: numbers].length != 0) return NO;
	}
	return YES;
}

- (BOOL) textFieldShouldEndEditing: (UITextField *) textField {
	if ([self.table.recordFieldsTableDelegate respondsToSelector: @selector(recordFieldsTable:showFinishEditingTextField:forField:)] && ![self.table.recordFieldsTableDelegate recordFieldsTable: self.table showFinishEditingTextField: textField forField:self.keyPath]) return NO;
	
	return YES;
}

- (void) textFieldDidEndEditing: (UITextField *) textField {
	NSString		*keypath = self.keyPath;
	
	switch (self.attributeType) {
		case NSStringAttributeType: [self.table changeValue: textField.text forKeyPath: keypath onObject: self.object]; break;
		case NSFloatAttributeType: [self.table changeValue: @(textField.text.floatValue) forKeyPath: keypath onObject: self.object]; break;
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType: [self.table changeValue: @(textField.text.intValue) forKeyPath: keypath onObject: self.object]; break;
		case NSDoubleAttributeType:  [self.table changeValue: @(textField.text.floatValue) forKeyPath: keypath onObject: self.object]; break;
		default: break;
	}
	[NSObject performBlock: ^{ [self updateValidityIndicator]; } afterDelay: 0.0];
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
	self.table.lastEditedCell = self;
	return YES;
}

- (BOOL) textView: (UITextView *) textView shouldChangeTextInRange: (NSRange) range replacementText: (NSString *) text {
	NSUInteger				limit = [self.attributeInfo[@"length"] intValue];
	
	if (text.length == 0 || limit == 0) return YES;
	
	NSString				*newText = [textView.text stringByReplacingCharactersInRange: range withString: text];
	
	return (newText.length < limit);
	
}

- (void) textViewDidEndEditing: (UITextView *) textView {
	[self.table changeValue: textView.text forKeyPath: self.keyPath onObject: self.object];
}

//=============================================================================================================================
#pragma mark Properties
- (void) setFieldInfo: (NSDictionary *) fieldInfo {
	_fieldInfo = fieldInfo;
	_picklistOptions = nil;
	if (fieldInfo == nil) return;
	
	NSString			*keypath = self.keyPath;
	NSString			*relationshipPath = fieldInfo[MMFIELDS_TABLE_FIELD_ON_RELATIONSHIP_KEY];
	
	if (relationshipPath) {
		NSRelationshipDescription			*info = self.object.entity.relationshipsByName[keypath];
		MM_SFObjectDefinition				*def = [MM_SFObjectDefinition objectNamed: info.destinationEntity.name inContext: nil];
		
		self.attributeInfo = [def infoForField: relationshipPath];
	} else
		self.attributeInfo = [keypath containsCString: "."] ? nil : [self.table.objectDefinition infoForField: keypath];
	
	
	self.attributeType =  self.attributeInfo ? [self.attributeInfo[@"type"] convertToAttributeType] : NSStringAttributeType;
	self.isSwitch = (self.attributeType == NSBooleanAttributeType);
	
	if (self.isSwitch) {
		self.booleanValue = [[self.table valueForKeyPath: self.keyPath onObject: self.object] boolValue];
	}
	if (self.table.convertYesNoPicklistsToSwitches && self.isPicklist && self.picklistOptions.count == 2) {
		NSString			*opt1 = [self.picklistOptions[0][@"value"] lowercaseString], *opt2 = [self.picklistOptions[1][@"value"] lowercaseString];
		
		if (([opt1 isEqual: @"no"] || [opt1 isEqual: @"off"]) && ([opt2 isEqual: @"yes"] || [opt2 isEqual: @"on"])) self.isSwitch = YES;
		self.booleanValue = [[[self.table valueForKeyPath: self.keyPath onObject: self.object] lowercaseString] isEqual: opt2];
	}
	
	self.usesTextView = [self.fieldInfo hasValueForKey: MMFIELDS_TABLE_CUSTOM_HEIGHT_FIELD_KEY];
	
	[self updateDisplayedContents];
}

- (void) setupComponentFramesWithValue: (NSString *) value {
	CGSize					size = self.table.bounds.size;
	size.height = self.table.rowHeight;
	BOOL					editing = self.isEditing && [self.fieldInfo[MMFIELDS_TABLE_EDITABLE_KEY] boolValue];
	BOOL					editingViaTextField = (!self.isSwitch && !self.isPicklist);
	CGFloat					valueLeft = 0, editingHeight;
	size.width -= (self.table.edgeInsets.left + self.table.edgeInsets.right);
	
	if (![value isKindOfClass: [NSString class]]) value = @"";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	CGSize					labelSize = [self.labelLabel.text sizeWithFont: self.table.labelFont constrainedToSize: CGSizeMake(self.labelRight ? self.labelRight : size.width, size.height) lineBreakMode: NSLineBreakByWordWrapping];
	CGSize					valueSize = [value sizeWithFont: self.table.valueFont constrainedToSize: CGSizeMake(self.labelRight ? (size.width - self.labelRight) : size.width, size.height) lineBreakMode: NSLineBreakByWordWrapping];
	

#pragma clang diagnostic pop

	if (valueSize.height == 0) valueSize.height = self.table.valueFont.lineHeight;
	
	valueSize.height *= 2;
	editingHeight = valueSize.height;
	
	switch (self.table.labelValueAlignment) {
		case MM_RecordLabelValueAlignment_centered:
		case MM_RecordLabelValueAlignment_centeredBySection:
			valueLeft = self.labelRight + self.table.labelValueMargin;
			self.labelLabel.frame = CGRectMake(self.labelRight - labelSize.width, (size.height - labelSize.height) / 2 - 1, labelSize.width, labelSize.height);
			break;
			
		case MM_RecordLabelValueAlignment_justified:
			valueLeft = size.width - (valueSize.width + self.table.edgeInsets.right);
			self.labelLabel.frame = CGRectMake(self.table.edgeInsets.left, (size.height - labelSize.height) / 2 - 1, labelSize.width, labelSize.height);
			if (editing && editingViaTextField) {
				valueLeft = self.labelRight ?: (labelSize.width + self.table.labelValueMargin + self.table.edgeInsets.left);
			}
			break;
			
		case MM_RecordLabelValueAlignment_left:
			valueLeft = self.labelRight;
			self.labelLabel.frame = CGRectMake(self.table.edgeInsets.left, (size.height - labelSize.height) / 2 - 1, labelSize.width, labelSize.height);
			break;
			
		default:
			break;
	}

	CGFloat						textFieldWidth = size.width - (valueLeft + self.table.edgeInsets.right), leftOffset = 5;
	
	if (editing && editingViaTextField && !self.shouldShowButton) {
		if (self.isNumeric) textFieldWidth = MIN(textFieldWidth, 80);
		self.valueField.frame = CGRectMake(valueLeft - leftOffset, (size.height - editingHeight) / 2 + 0, textFieldWidth, editingHeight);
	} else
		self.valueLabel.frame = CGRectMake(valueLeft, (size.height - valueSize.height) / 2 - 1, valueSize.width, valueSize.height);
	
	if (self.shouldShowButton && editing) {
		CGFloat					left = _valueLabel.frame.origin.x ? _valueLabel.frame.origin.x : _valueField.frame.origin.x;
		self.valueButton.frame = CGRectMake(left - leftOffset, (size.height - 34) / 2, MIN(self.table.defaultRowButtonWidth, size.width - (self.valueLabel.frame.origin.x + self.table.edgeInsets.right)), 34);
	}
	if (self.fieldInfo[MMFIELDS_TABLE_CUSTOM_HEIGHT_FIELD_KEY]) {
		self.valueTextView.frame = CGRectMake(valueLeft - leftOffset, 2, textFieldWidth, self.bounds.size.height - 4);
	}

}

- (void) prepareForReuse {
	self.object = nil;
	self.fieldInfo = nil;
	
	[_valueField removeFromSuperview];
	[_valueSwitch removeFromSuperview];
	[_valueButton removeFromSuperview];
	[_valueTextView removeFromSuperview];
	[_valueField removeFromSuperview];

	_valueSwitch = nil;
	_valueButton = nil;
	_valueTextView = nil;
	_valueField = nil;
	_labelLabel.hidden = NO;
}

- (NSUInteger) numberOfDecimalPlaces { return (self.attributeType == NSFloatAttributeType || self.attributeType == NSDoubleAttributeType) ? [self.attributeInfo[@"scale"] intValue] : 0; }

- (void) updateDisplayedContents {
	NSString		*value = self.displayTextValue;

	_valueSwitch.hidden = !self.isEditing || self.shouldShowButton;
	_valueButton.hidden = !self.isEditing || self.isSwitch;
	_valueTextView.hidden = !self.usesTextView || self.isSwitch || self.shouldShowButton;
	_valueField.hidden = !self.isEditing || self.isSwitch || self.shouldShowButton;
	_valueLabel.hidden = self.isEditing || self.isSwitch || self.usesTextView;
	
	self.labelLabel.text = self.fieldInfo[MMFIELDS_TABLE_LABEL];
	
	[self setupComponentFramesWithValue: value];
	
	CGSize					size = self.table.bounds.size;
	size.height = self.table.rowHeight;
	BOOL					editing = self.isEditing && [self.fieldInfo[MMFIELDS_TABLE_EDITABLE_KEY] boolValue];
	size.width -= (self.table.edgeInsets.left + self.table.edgeInsets.right);
	
	_valueLabel.text = value;
	_valueField.text = self.textValue;
	
	if (self.isSwitch) {
		self.valueSwitch.frame = CGRectMake(self.valueLabel.frame.origin.x, (size.height - self.valueSwitch.bounds.size.height) / 2, self.valueSwitch.bounds.size.width, self.valueSwitch.bounds.size.height);
		self.valueLabel.hidden = YES;
		self.valueSwitch.enabled = editing;
		self.valueSwitch.on = self.booleanValue;
	} else if (self.shouldShowButton && editing) {
		[self.valueButton setTitle: self.buttonTitle forState: UIControlStateNormal];
	}
	if (self.usesTextView) {
		self.valueTextView.text = self.textValue;
		self.valueField.hidden = YES;
		self.valueTextView.layer.borderWidth = self.isEditing ? 1 : 0;
		self.valueTextView.editable = self.isEditing;
	}
	
	[NSObject performBlock: ^{ [self updateValidityIndicator]; } afterDelay: 0.0];
}

- (void) setDisplayInvalidFieldIndicator: (BOOL) displayInvalidFieldIndicator {
	_displayInvalidFieldIndicator = displayInvalidFieldIndicator;
	
	_labelLabel.textColor = displayInvalidFieldIndicator ? [UIColor redColor] : [UIColor blackColor];
}


- (BOOL) isPicklist { return [self.attributeInfo[@"picklistValues"] count] > 0; }
- (BOOL) isDate { return self.attributeType == NSDateAttributeType; }
- (BOOL) isDateTime { return [self.attributeInfo[@"type"] isEqual: @"datetime"]; }
- (BOOL) isPhone { return [self.fieldInfo[MMFIELDS_TABLE_IS_PHONE_FIELD_KEY] boolValue] || [self.fieldInfo[MMFIELDS_TABLE_IS_US_PHONE_FIELD_KEY] boolValue]; }
- (BOOL) isZIPCode { return [self.fieldInfo[MMFIELDS_TABLE_IS_ZIPCODE_FIELD_KEY] boolValue]; }
- (BOOL) isEmail { return [self.fieldInfo[MMFIELDS_TABLE_IS_EMAIL_FIELD_KEY] boolValue]; }
- (BOOL) isNumeric { return self.attributeType == NSFloatAttributeType || self.attributeType == NSInteger16AttributeType || self.attributeType == NSInteger32AttributeType || self.attributeType == NSInteger64AttributeType || self.attributeType == NSDoubleAttributeType; }
- (BOOL) isMultipicklist { return [self.attributeInfo[@"type"] isEqual: @"multipicklist"]; }
- (BOOL) isRelationship { return self.fieldInfo[MMFIELDS_TABLE_FIELD_ON_RELATIONSHIP_KEY] != nil; }
- (BOOL) shouldShowButton { return self.isPicklist || self.isDate || self.isDateTime || self.isMultipicklist || self.isRelationship || self.fieldInfo[MMFIELDS_TABLE_BUTTON_TITLE_KEY]; }
- (NSString *) keyPath { return self.fieldInfo[MMFIELDS_TABLE_KEYPATH_KEY]; }
									  
- (BOOL) isEditing { return self.table.editing && [self.fieldInfo[MMFIELDS_TABLE_EDITABLE_KEY] boolValue]; }

- (UILabel *) labelLabel {
	if (_labelLabel == nil) {
		_labelLabel = [[UILabel alloc] initWithFrame: CGRectZero];
		_labelLabel.backgroundColor = [UIColor clearColor];
		_labelLabel.font = self.table.labelFont;
		[self.contentView addSubview: _labelLabel];
	}
	return _labelLabel;
}

- (UILabel *) valueLabel {
	if (_valueLabel == nil) {
		_valueLabel = [[MM_RecordFieldsTableCellLabel alloc] initWithFrame: CGRectZero];
		_valueLabel.backgroundColor = [UIColor clearColor];
		_valueLabel.font = self.table.valueFont;
		//IF_DEBUG(_valueLabel.backgroundColor = [UIColor lightGrayColor]);
		
		[self.contentView addSubview: _valueLabel];
	}
	_valueLabel.hidden = self.isEditing || self.isSwitch || self.usesTextView;
	return _valueLabel;
}

- (UITextField *) valueField {
	if (_valueField == nil) {
		_valueField = [[MM_RecordFieldsTableCellTextField alloc] initWithFrame: self.bounds];
		_valueField.borderStyle = UITextBorderStyleNone;
		_valueField.layer.borderColor = [UIColor lightGrayColor].CGColor;
		_valueField.font = self.table.valueFont;
		_valueField.layer.borderWidth = 1;
		_valueField.delegate = self;
		//_valueField.text = self.textValue;
		[self.contentView addSubview: _valueField];
		[self setupComponentFramesWithValue: self.displayTextValue];
	}
	
	_valueField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_valueField.autocorrectionType = UITextAutocorrectionTypeNo;

	if (self.isZIPCode)
		_valueField.keyboardType = UIKeyboardTypeNumberPad;
	if (self.isEmail)
		_valueField.keyboardType = UIKeyboardTypeEmailAddress;
	else if (self.isPhone)
		_valueField.keyboardType = UIKeyboardTypePhonePad;
	else if (self.isNumeric)
		_valueField.keyboardType = UIKeyboardTypeNumberPad;
	else {
		_valueField.keyboardType = UIKeyboardTypeDefault;
		_valueField.autocapitalizationType = UITextAutocapitalizationTypeWords;
		_valueField.autocorrectionType = UITextAutocorrectionTypeDefault;
	}

	_valueField.hidden = !self.isEditing || self.isSwitch || self.shouldShowButton || self.usesTextView;
	return _valueField;
}

- (UITextView *) valueTextView {
	if (_valueTextView == nil) {
		_valueTextView = [[UITextView alloc] initWithFrame: CGRectZero];
		_valueTextView.delegate = self;
		_valueTextView.backgroundColor = [UIColor clearColor];
		_valueTextView.font = self.table.valueFont;
		_valueTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_valueTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
		[self.contentView addSubview: _valueTextView];
	}

	_valueTextView.hidden = !self.usesTextView || self.isSwitch || self.shouldShowButton;
	return _valueTextView;
}

- (UISwitch *) valueSwitch {
	if (_valueSwitch == nil) {
		_valueSwitch = [[UISwitch alloc] initWithFrame: CGRectZero];
		_valueSwitch.enabled = NO;
		if (s_switchOnImage) _valueSwitch.onImage = s_switchOnImage;
		if (s_switchOffImage) _valueSwitch.offImage = s_switchOffImage;
		[self.contentView addSubview: _valueSwitch];
		[_valueSwitch addTarget: self action: @selector(switchFlipped:) forControlEvents: UIControlEventValueChanged];
	}

	return _valueSwitch;
}

- (UIButton *) valueButton {
	if (_valueButton == nil) {
		if ([self.table.recordFieldsTableDelegate respondsToSelector: @selector(createRecordFieldsTableButton)])
			_valueButton = [self.table.recordFieldsTableDelegate createRecordFieldsTableButton];
		else
			_valueButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];			//▼
		[_valueButton addTarget: self action: @selector(buttonPressed:) forControlEvents: UIControlEventTouchUpInside];
		_valueButton.titleLabel.font = self.table.valueFont;
		_valueButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		[self.contentView addSubview: _valueButton];
	}
	_valueButton.hidden = NO;
	return _valueButton;
}

- (NSString *) buttonTitle {
	if (self.displayTextValue.length == 0 && self.fieldInfo[MMFIELDS_TABLE_BUTTON_TITLE_KEY]) return $S(@"▼ %@", self.fieldInfo[MMFIELDS_TABLE_BUTTON_TITLE_KEY]);
	return $S(@"▼ %@", self.displayTextValue ?: @"                       ");
}

- (NSString *) displayTextValue { return self.textValue; }

- (NSString *) textValue {
	NSString		*keypath = self.keyPath;
	if (keypath == nil) return @"";
	
	id				value = [self.table valueForKeyPath: keypath onObject: self.object];
	
	if (self.isRelationship) value = value[self.fieldInfo[MMFIELDS_TABLE_FIELD_ON_RELATIONSHIP_KEY]];
	
	switch (self.attributeType) {
		case NSStringAttributeType:
			if (self.picklistOptions.count) {
				if (self.isMultipicklist) {
					NSMutableString				*text = [NSMutableString string];
					
					for (NSDictionary *option in self.picklistOptions) {
						if ([value length] && [value rangeOfString: option[@"value"]].location != NSNotFound) {
							[text appendFormat: text.length ? @", %@" : @"%@", option[@"label"]];
						}
					}
					return text;
					
				}
				for (NSDictionary *option in self.picklistOptions) {
					if ([option[@"value"] isEqual: value]) return option[@"label"];
				}
			}
			return value;
			
		case NSFloatAttributeType:
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
		case NSDoubleAttributeType: {
				NSNumberFormatter		*numberFormatter = [[NSNumberFormatter alloc] init];
				[numberFormatter setMaximumSignificantDigits: 10];
				[numberFormatter setGeneratesDecimalNumbers: YES];
				[numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
				if ([self.attributeInfo[@"type"] isEqual: @"percent"]) [numberFormatter setNumberStyle: NSNumberFormatterPercentStyle];
				else if ([self.attributeInfo[@"type"] isEqual: @"currency"]) [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
				else {
					NSString			*format = $S(@"%%.0%df", (short) self.numberOfDecimalPlaces);
					NSString			*string = [NSString stringWithFormat: format, [value floatValue]];
					if ([string containsCString: "."]) {
						string = [string stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"0"]];
						return ([string isEqual: @"."]) ? @"" : string;
					}
					return string;
				}
				return [numberFormatter stringFromNumber: value ?: @0.0];
			} break;
	
		case NSBooleanAttributeType: return [value boolValue] ? NSLocalizedString(@"yes", @"yes") : NSLocalizedString(@"no", @"no");
		case NSDateAttributeType: {
				if (value == nil) return nil;
				NSDateFormatter			*formatter = [[NSDateFormatter alloc] init];
				[formatter setDateFormat: self.isDateTime ? @"dd' 'MMM' 'yyyy', 'HH':'mm" : @"dd' 'MMM' 'yyyy"];
				
				return [formatter stringFromDate: value];
			} break;
			
		default: break;
	}

	return $S(@"%@", value);
}

@end

@implementation MM_RecordFieldsTableCellLabel
@end
