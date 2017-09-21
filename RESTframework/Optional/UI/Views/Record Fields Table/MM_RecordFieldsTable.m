//
//  MM_RecordFieldsTable.m
//
//  Created by Ben Gottlieb on 6/1/13.
//
//

#import "MM_RecordFieldsTable.h"
#import "MM_RecordFieldsTableCell.h"
#import "MM_Headers.h"

@interface NSString (MM_RecordFieldsTable)
- (BOOL) isValidUSPhone;
- (BOOL) isValidZIPCode;
@end


@interface MM_RecordFieldsTable ()
@property (nonatomic, strong) NSMutableArray *sections;		//array of dictionaries, each with "rows", "labelRight" and "headerView"
@property (nonatomic) CGFloat labelRight;
@property (nonatomic) CGFloat keyboardHeightAdjustment;
@property (nonatomic, strong) MM_SFObjectDefinition *objectDefinition;
@property (nonatomic, strong) NSMutableDictionary *cachedPicklists;
@property (nonatomic, strong) NSMutableDictionary *changedValues;
@property (nonatomic, strong) UIView *keyboardAccessoryView;
@property (nonatomic, strong) UISegmentedControl *keyboardAccessorySegments;
@end

@interface UITableView (SA_IndexPathTools)
- (NSIndexPath *) decrementIndexPath: (NSIndexPath *) path;
- (NSIndexPath *) incrementIndexPath: (NSIndexPath *) path;
@end

@implementation MM_RecordFieldsTable

- (void) dealloc {
	[self removeAsObserver];
}

//=============================================================================================================================
#pragma mark Setup
- (id) initWithFrame: (CGRect) frame {
    if (self = [super initWithFrame: frame]) {
		[self setup];
    }
    return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder {
    if (self = [super initWithCoder: aDecoder]) {
		[self setup];
    }
    return self;
}

- (void) setup {
	self.dataSource = self;
	self.delegate = self;
	self.defaultRowButtonWidth = 400;
	self.labelValueMargin = 10;
	self.labelValueAlignment = MM_RecordLabelValueAlignment_centered;
	self.labelFont = [UIFont systemFontOfSize: 18];
	self.valueFont = [UIFont boldSystemFontOfSize: 17];
	self.tableCellClass = [MM_RecordFieldsTableCell class];
    [self addAsObserverForName: UIKeyboardWillShowNotification selector: @selector(keyboardWillShow:)];
    [self addAsObserverForName: UIKeyboardWillHideNotification selector: @selector(keyboardWillHide:)];
    [self addAsObserverForName: UITextFieldTextDidBeginEditingNotification selector: @selector(textFieldDidBeginEditing:)];
    [self addAsObserverForName: UITextViewTextDidBeginEditingNotification selector: @selector(textViewDidBeginEditing:)];
	
	self.inputViewEnabled = RUNNING_ON_60;
}

- (void) clearAllSectionsAndRows {
	self.sections = [NSMutableArray array];
	[self cancelAndPerformSelector: @selector(reloadData) withObject: nil afterDelay: 0];
}

//=============================================================================================================================
#pragma mark Adding Fields
- (NSMutableDictionary *) startNewSectionWithView: (UIView *) headerView {
	if (self.sections == nil) self.sections = [NSMutableArray array];
	
	NSMutableDictionary			*section = [NSMutableDictionary dictionaryWithObject: [NSMutableArray array] forKey: @"rows"];
	
	if (headerView) section[@"headerView"] = headerView;
	[self.sections addObject: section];
	[self cancelAndPerformSelector: @selector(reloadData) withObject: nil afterDelay: 0];
	return section;
}

- (NSMutableDictionary *) startNewSectionWithString: (NSString *) headerTitle {
	UIView					*header = nil;
	
	if (self.headerViewClass) header = [self.headerViewClass headerWithTitle: headerTitle inTable: self];
	
	if (header == nil) {
		UILabel				*label = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, self.bounds.size.width, headerTitle.length ? 20 : 0)];
		label.text = headerTitle;
		label.backgroundColor = [UIColor colorWithWhite: 0.75 alpha: 1.0];
		label.font = [UIFont boldSystemFontOfSize: 18];
		label.textAlignment = NSTextAlignmentCenter;
		header = label;
	}
	
	return [self startNewSectionWithView: header];
}

- (NSMutableDictionary *) addRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable {
	NSMutableDictionary				*info = [NSMutableDictionary dictionary];
	
	if (keyPath == nil) {
		[SA_AlertView showAlertWithTitle: $S(@"Trying to add an empty keypath to a table (%@)", label ?: @"untitled") message: nil];
		return nil;
	}
	if (self.object && ![self.object hasValueForKeyPath: keyPath]) LOG(@"Trying to add a row with no valid keypath: %@ on %@", keyPath, self.object.entity.name);
	
	SA_Assert(label != nil || self.object != nil, @"When using definition-provided labels, you MUST set the obect before adding fields");
	info[MMFIELDS_TABLE_LABEL] = (label ?: [self.objectDefinition infoForField: keyPath][MMFIELDS_TABLE_LABEL]) ?: @"";
	info[MMFIELDS_TABLE_KEYPATH_KEY] = keyPath;
	info[MMFIELDS_TABLE_EDITABLE_KEY] = @(editable);
	
	[self.sections.lastObject[@"rows"] addObject: info];
	[self cancelAndPerformSelector: @selector(reloadData) withObject: nil afterDelay: 0];
	return info;
}

- (NSMutableDictionary *) addRelationshipWithLabel: (NSString *) label forField: (NSString *) field onKeyPath: (NSString *) keyPath editButtonTitle: (NSString *) editButtonTitle {
	NSMutableDictionary			*info = [self addRowWithLabel: label forKeyPath: keyPath editButtonTitle: editButtonTitle];
	
	info[MMFIELDS_TABLE_FIELD_ON_RELATIONSHIP_KEY] = field;
	return info;
}

- (NSMutableDictionary *) addEmailRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable {
	NSMutableDictionary			*info = [self addRowWithLabel: label forKeyPath: keyPath editable: editable];
	
	info[MMFIELDS_TABLE_IS_EMAIL_FIELD_KEY] = @true;
	return info;
}

- (NSMutableDictionary *) addPhoneRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath USOnly: (BOOL) USOnly editable: (BOOL) editable {
	NSMutableDictionary			*info = [self addRowWithLabel: label forKeyPath: keyPath editable: editable];
	
	info[USOnly ? MMFIELDS_TABLE_IS_US_PHONE_FIELD_KEY : MMFIELDS_TABLE_IS_PHONE_FIELD_KEY] = @true;
	return info;
}

- (NSMutableDictionary *) addZIPCodeRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable {
	NSMutableDictionary			*info = [self addRowWithLabel: label forKeyPath: keyPath editable: editable];
	
	info[MMFIELDS_TABLE_IS_ZIPCODE_FIELD_KEY] = @true;
	return info;
}

- (NSMutableDictionary *) addRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable textHeight: (CGFloat) height {
	NSMutableDictionary				*info = [self addRowWithLabel: label forKeyPath: keyPath editable: editable];
	info[MMFIELDS_TABLE_CUSTOM_HEIGHT_FIELD_KEY] = @(height);
	return info;
}

- (NSMutableDictionary *) addRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editButtonTitle: (NSString *) editButtonTitle {
	NSMutableDictionary				*info = [self addRowWithLabel: label forKeyPath: keyPath editable: editButtonTitle != nil];
	
	if (editButtonTitle) info[MMFIELDS_TABLE_BUTTON_TITLE_KEY] = editButtonTitle;
	return info;
}

- (void) addTableCell: (UITableViewCell *) cell {
	[self.sections.lastObject[@"rows"] addObject: cell];
	[self cancelAndPerformSelector: @selector(reloadData) withObject: nil afterDelay: 0];
}

//=============================================================================================================================
#pragma mark Utility
- (BOOL) validateRequiredFieldsWithIndicators: (BOOL) showRequiredIndicators {
	BOOL					valid = YES;
	UIView					*responder = [self firstResponderView];
	
	[responder resignFirstResponder];
	[responder becomeFirstResponder];
	
	for (NSDictionary *section in self.sections) {
		for (NSDictionary *row in section[@"rows"]) {
			
			if ([row isKindOfClass: [NSDictionary class]] && ![self isFieldValid: row]) {
				valid = NO;
				break;
			}
		}
	}
	
	self.showRequiredFieldIndicators = showRequiredIndicators;
	
	return valid;
}

- (BOOL) isFieldValid: (NSDictionary *) fieldInfo {
	if (fieldInfo == nil) return YES;
	
	id						value = [self valueForKeyPath: fieldInfo[MMFIELDS_TABLE_KEYPATH_KEY] onObject: nil];
	BOOL					isRequired = [fieldInfo[MMFIELDS_TABLE_REQUIRED_FIELD_KEY] boolValue];

	if (![fieldInfo[MMFIELDS_TABLE_EDITABLE_KEY] boolValue]) return YES;
	if (value == nil && isRequired) return NO;
	if (!isRequired && ([value isKindOfClass: [NSString class]] || value == nil)) {
		if ([[value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) return YES;
	}
	
	if ([fieldInfo[MMFIELDS_TABLE_IS_EMAIL_FIELD_KEY] boolValue]) {
		return [value isValidEmail];
	}
	
	if ([fieldInfo[MMFIELDS_TABLE_IS_US_PHONE_FIELD_KEY] boolValue]) {
		return [value isValidUSPhone];
	}
	
	if ([fieldInfo[MMFIELDS_TABLE_IS_ZIPCODE_FIELD_KEY] boolValue]) {
		return [value isValidZIPCode];
	}
	
	if (isRequired && [value isKindOfClass: [NSString class]]) {
		return [value length] > 0;
	}
	return (YES);
}

- (void) reloadRowForKey: (NSString *) key {
	NSIndexPath				*path = [self indexPathOfKey: key];
	if (path)
		[self reloadRowsAtIndexPaths: @[ path ] withRowAnimation: UITableViewRowAnimationNone];
	else
		[self reloadData];
}

- (NSIndexPath *) indexPathOfKey: (NSString *) key {
	for (NSDictionary *section in self.sections) {
		for (NSDictionary *row in section[@"rows"]) {
			if ([row isKindOfClass: [NSDictionary class]] && [row[MMFIELDS_TABLE_KEYPATH_KEY] isEqual: key]) {
				return [NSIndexPath indexPathForRow: [section[@"rows"] indexOfObject: row] inSection: [self.sections indexOfObject: section]];
			}
		}
	}
	return nil;
}



- (void) beginEditing {
	if (self.editing) return;
	self.editing = YES;
	[NSNotificationCenter postNotificationNamed: kNotification_RecordFieldTableBeganEditing];
	[self reloadData];
}

- (void) endEditingSavingChanged: (BOOL) saving {
	[self resignFirstResponderForAllChildren];
	if (!self.editing) return;
	if (saving) {
		for (NSString *path in self.changedValues) {
			self.object[path] = self.changedValues[path];
		}
	}
	
	self.changedValues = nil;
	self.editing = NO;
	[NSNotificationCenter postNotificationNamed: kNotification_RecordFieldTableFinishedEditing];
	[self reloadData];
}

- (void) reloadData {
	[self setupLabelValueCenterline];
	[super reloadData];
}

- (void) setupLabelValueCenterline {
	if (self.labelValueCenterline)
		self.labelRight = self.labelValueCenterline;
	else {
		CGFloat				maxTableLabelWidth = 0;
		
		for (NSMutableDictionary *section in self.sections) {
			CGFloat				maxLabelWidth = 0;
			
			for (NSDictionary *field in section[@"rows"]) {
				if (![field isKindOfClass: [NSDictionary class]]) continue;
				CGSize				size = [field[@"label"] sizeWithFont: self.labelFont];
				
				if (size.width > maxLabelWidth) maxLabelWidth = size.width;
			}
			
			section[@"labelRight"] = @(maxLabelWidth + self.edgeInsets.left);
			if (maxLabelWidth > maxTableLabelWidth) maxTableLabelWidth = maxLabelWidth;
		}
		
		self.labelRight = maxTableLabelWidth * 1.1 + self.edgeInsets.left;
	}
}

//=============================================================================================================================
#pragma mark Properties
- (void) setShowRequiredFieldIndicators: (BOOL) showRequiredFieldIndicators {
	if (self.showRequiredFieldIndicators == showRequiredFieldIndicators) return;
	
	_showRequiredFieldIndicators = showRequiredFieldIndicators;
	[self reloadData];
}

- (void) setObject: (MMSF_Object *) object {
	if (object != _object) {
		self.cachedPicklists = nil;
		self.changedValues = nil;
	}
	_object = object;
	self.objectDefinition = object.definition;
}

- (void) clearCachedPicklistOptionsForField: (NSString *) field {
	if (field) [self.cachedPicklists removeObjectForKey: field];
}

- (void) invalidateCachedPicklistsBasedOnField: (NSString *) field {		//this could probably be a bit smarter, but will do for now
	self.cachedPicklists = nil;
}

- (NSArray *) picklistOptionsForField: (NSString *) field {
	NSArray				*picklist = self.cachedPicklists[field];
	
	if (picklist == nil) {
		if (self.cachedPicklists == nil) self.cachedPicklists = [NSMutableDictionary dictionary];
		picklist = [self.object picklistOptionsForField: field] ?: (id) [NSNull null];
		self.cachedPicklists[field] = picklist;
	}
	
	if ([picklist isEqual: [NSNull null]]) return nil;
	
	
	return picklist;
}
//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSDictionary						*info = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	if ([info isKindOfClass: [UITableViewCell class]]) {
		MM_RecordFieldsTableCell			*cell = (id) info;
		
		if ([cell respondsToSelector: @selector(setTable:)]) cell.table = self;
		if ([cell respondsToSelector: @selector(setLabelRight:)]) cell.labelRight = (self.labelValueAlignment == MM_RecordLabelValueAlignment_centeredBySection) ? [self.sections[indexPath.row][@"labelRight"] floatValue] : self.labelRight;

		if ([cell respondsToSelector: @selector(updateDisplayedContents)]) [cell performSelector: @selector(updateDisplayedContents) withObject: nil afterDelay: 0.0];
		return cell;
	}
	
	MM_RecordFieldsTableCell			*cell = (id) [tableView dequeueReusableCellWithIdentifier: [self.tableCellClass	identifier]];
	
	if (cell == nil) cell = [self.tableCellClass cellWithObject: self.object inFieldsTable: self];
	
	cell.labelRight = (self.labelValueAlignment == MM_RecordLabelValueAlignment_centeredBySection) ? [self.sections[indexPath.row][@"labelRight"] floatValue] : self.labelRight;
	cell.fieldInfo = info;
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	return self.sections.count;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	return [self.sections[section][@"rows"] count];
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}


- (UIView *) tableView: (UITableView *) tableView viewForHeaderInSection: (NSInteger) sectionIndex {
	return self.sections[sectionIndex][@"headerView"];
}

- (UIView *) tableView: (UITableView *) tableView viewForFooterInSection: (NSInteger) sectionIndex {
	return nil;
}

- (CGFloat) tableView: (UITableView *) tableView heightForHeaderInSection: (NSInteger) section {
	return [self.sections[section][@"headerView"] bounds].size.height;
}

- (CGFloat) tableView: (UITableView *) tableView heightForFooterInSection: (NSInteger) section {
	return 0;
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSDictionary				*info = self.sections[indexPath.section][@"rows"][indexPath.row];
	
	if ([info isKindOfClass: [UITableViewCell class]]) return [(id) info bounds].size.height;
	if (info[MMFIELDS_TABLE_CUSTOM_HEIGHT_FIELD_KEY]) return [info[MMFIELDS_TABLE_CUSTOM_HEIGHT_FIELD_KEY] floatValue];
	return self.rowHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }


//=============================================================================================================================
#pragma mark Keyboard
- (void) keyboardWillShow: (NSNotification *) note {
	UIView	*rootView = self.viewController.focusedViewControllerAncestor.view;
    CGRect	keyboardEndingUncorrectedFrame = [[note.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect	keyboardEndingFrame = [rootView convertRect:keyboardEndingUncorrectedFrame  fromView:nil];
	CGRect	myFrame = [rootView convertRect: self.bounds fromView: self];
    CGRect	overlap = CGRectIntersection(myFrame, keyboardEndingFrame);
    CGRect	frame = self.frame;
    
    self.keyboardHeightAdjustment = overlap.size.height;
    frame.size.height -= self.keyboardHeightAdjustment;
    
    CGFloat	duration = [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGFloat delay = duration;
    duration = duration * self.keyboardHeightAdjustment / keyboardEndingFrame.size.height;
    delay = delay - duration;
    
    UIViewAnimationCurve curve = (UIViewAnimationCurve) [[note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = 0;
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
    }
	
    [UIView animateWithDuration: duration delay:delay options:options animations: ^{
        self.contentInset = UIEdgeInsetsMake(0, 0, self.keyboardHeightAdjustment, 0);
//        self.frame = frame;
    } completion:^(BOOL finished) {
        if (self.lastEditedCell) [self scrollToRowAtIndexPath: [self indexPathForCell: self.lastEditedCell] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }];
}

- (void) keyboardWillHide: (NSNotification *) note {
	UIView	*rootView = self.viewController.focusedViewControllerAncestor.view;
    CGRect	keyboardEndingUncorrectedFrame = [[note.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect	keyboardEndingFrame = [rootView convertRect:keyboardEndingUncorrectedFrame  fromView:nil];
    
    CGRect frame = self.frame;
    frame.size.height += self.keyboardHeightAdjustment;
    
    CGFloat	duration = [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGFloat delay = 0;
    duration = duration * self.keyboardHeightAdjustment / keyboardEndingFrame.size.height;
    
    UIViewAnimationCurve curve = (UIViewAnimationCurve) [[note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = 0;
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
    }
    [UIView animateWithDuration: duration delay:delay options:options animations: ^{
        //self.frame = frame;
		self.contentInset = UIEdgeInsetsZero;
    } completion:^(BOOL finished) {
    }];
}

- (void) textFieldDidBeginEditing: (NSNotification *) note {
	[self.keyboardAccessorySegments setEnabled: [self canMoveToPrevious: YES viewFromView: note.object] forSegmentAtIndex: 0];
	[self.keyboardAccessorySegments setEnabled: [self canMoveToPrevious: NO viewFromView: note.object] forSegmentAtIndex: 1];
}

- (void) textViewDidBeginEditing: (NSNotification *) note {
	[self.keyboardAccessorySegments setEnabled: [self canMoveToPrevious: YES viewFromView: note.object] forSegmentAtIndex: 0];
	[self.keyboardAccessorySegments setEnabled: [self canMoveToPrevious: NO viewFromView: note.object] forSegmentAtIndex: 1];
}

//=============================================================================================================================
#pragma mark Editing, saving, etc
- (void) changeValue: (id) value forKeyPath: (NSString *) path onObject: (MMSF_Object *) object {
	if (object == nil) object = self.object;
	
	if (object == self.object) {
		if ([[self.object valueForKeyPath: path] isEqual: value]) {
			[self.changedValues removeObjectForKey: path];
		} else if (value) {
			if (self.changedValues == nil) self.changedValues = [NSMutableDictionary dictionary];
			self.changedValues[path] = value;
		} else {
			[self.changedValues setValue: [NSNull null] forKey: path];
		}
	} else {
		object[path] = value;
	}
	
	if ([self.recordFieldsTableDelegate respondsToSelector: @selector(recordFieldsTable:didChangeValueForField:)]) [self.recordFieldsTableDelegate recordFieldsTable: self didChangeValueForField: path];
}

- (id) valueForKeyPath: (NSString *) path onObject: (MMSF_Object *) object {
	id				value;
	
	if (object == nil) object = self.object;
	if (object == self.object) {
		value = self.changedValues[path];
		if (value) return ([value isEqual: [NSNull null]]) ? nil : value;
		return [self.object valueForKeyPath: path];
	}
	return object[path];
}



- (NSIndexPath *) previous: (BOOL) usePrev editableIndexPathFromPath: (NSIndexPath *) path {
	while (true) {
		path = usePrev ? [self decrementIndexPath: path] : [self incrementIndexPath: path];
		if (path == nil) return nil;
		
		NSDictionary						*info = self.sections[path.section][@"rows"][path.row];
		
		if (![info isKindOfClass: [NSDictionary class]]) continue;
		if (![info[MMFIELDS_TABLE_EDITABLE_KEY] boolValue]) continue;
		
		NSDictionary						*attr = [self.objectDefinition infoForField: info[MMFIELDS_TABLE_KEYPATH_KEY]];
		NSAttributeType						type = attr ? [attr[@"type"] convertToAttributeType] : NSStringAttributeType;
		
		if (type < NSInteger16AttributeType || type > NSStringAttributeType) continue;
		if ([[self picklistOptionsForField: info[MMFIELDS_TABLE_KEYPATH_KEY]] count]) continue;
		if ([info[MMFIELDS_TABLE_BUTTON_TITLE_KEY] length]) continue;
		return path;
	}
	
	return nil;
}

- (BOOL) canMoveToPrevious: (BOOL) prev viewFromView: (UIView *) currentView {
	UITableViewCell				*cell = [currentView respondsToSelector: @selector(tableViewCell)] ? [(id) currentView tableViewCell] : nil;
	NSIndexPath					*path = cell ? [self indexPathForCell: cell] : nil;
	
	if (path == nil) return NO;
	
	return ([self previous: prev editableIndexPathFromPath: path] != nil);
}


//=============================================================================================================================
#pragma mark Input views
- (UIView *) inputAccessoryView {
	if (!self.inputViewEnabled) return [super inputAccessoryView];
	
	if  (self.keyboardAccessoryView == nil) {
		self.keyboardAccessoryView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 300, 44)];
		
		self.keyboardAccessorySegments = [[UISegmentedControl alloc] initWithFrame: CGRectMake(10, 5, 190, 34)];
		
		[self.keyboardAccessorySegments insertSegmentWithTitle: @"Previous" atIndex: 0 animated: NO];
		[self.keyboardAccessorySegments insertSegmentWithTitle: @"Next" atIndex: 1 animated: NO];
		self.keyboardAccessorySegments.momentary = YES;
		if ([[UISegmentedControl appearance] titleTextAttributesForState: UIControlStateNormal] == nil) [self.keyboardAccessorySegments setTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor blackColor]} forState: UIControlStateNormal];
		if ([[UISegmentedControl appearance] titleTextAttributesForState: UIControlStateDisabled] == nil) [self.keyboardAccessorySegments setTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor grayColor]} forState: UIControlStateDisabled];
		[self.keyboardAccessorySegments addTarget: self action: @selector(moveToNextPrev:) forControlEvents: UIControlEventValueChanged];
		
		[self.keyboardAccessoryView addSubview: self.keyboardAccessorySegments];
		self.keyboardAccessoryView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.75];
	}
	
	UIView					*responder = [self firstResponderView];
	[self.keyboardAccessorySegments setEnabled: [self canMoveToPrevious: YES viewFromView: responder] forSegmentAtIndex: 0];
	[self.keyboardAccessorySegments setEnabled: [self canMoveToPrevious: NO viewFromView: responder] forSegmentAtIndex: 1];
	return self.keyboardAccessoryView;
}

- (void) moveToNextPrev: (UISegmentedControl *) sender {
	BOOL						moveForward = sender.selectedSegmentIndex == 1;
	UIResponder					*responder = self.firstResponderView;
	MM_RecordFieldsTableCell	*cell = [responder respondsToSelector: @selector(tableViewCell)] ? (id) [(id) responder tableViewCell] : nil;
	NSIndexPath					*path = cell ? [self indexPathForCell: cell] : nil;
	
	if (path == nil) return;
	path = [self previous: !moveForward editableIndexPathFromPath: path];
	if (path == nil) return;
	
	[self scrollToRowAtIndexPath:path atScrollPosition: UITableViewScrollPositionMiddle animated: YES];
	[NSObject performBlock: ^{
		MM_RecordFieldsTableCell			*focus = (id) [self cellForRowAtIndexPath: path];
		if ([focus isKindOfClass: [MM_RecordFieldsTableCell class]]) {
			if (!focus.valueTextView.isHidden) [focus.valueTextView becomeFirstResponder];
			if (!focus.valueField.isHidden) [focus.valueField becomeFirstResponder];
		} else {
			[focus becomeFirstResponder];
		}
	} afterDelay: [self cellForRowAtIndexPath: path] ? 0 : 0.25];
}

- (BOOL) isIndexPathFirstInTable: (NSIndexPath *) path {
	return path.row == 0 && path.section == 0;
}

- (BOOL) isIndexPathLastInTable: (NSIndexPath *) path {
	return path.section == (self.numberOfSections - 1) && path.row == ([self numberOfRowsInSection: path.section] - 1);
}

@end


@implementation UITableView (SA_IndexPathTools)
//=============================================================================================================================
#pragma mark Index Path tools
- (NSIndexPath *) decrementIndexPath: (NSIndexPath *) path {
	if (path.row) return [NSIndexPath indexPathForRow: path.row - 1 inSection: path.section];
	
	NSInteger					section = path.section;
	
	while (section) {
		NSInteger					rowCount = [self numberOfRowsInSection: --section];

		if (rowCount) return [NSIndexPath indexPathForRow: rowCount - 1 inSection: section];
	}
	return nil;
}

- (NSIndexPath *) incrementIndexPath: (NSIndexPath *) path {
	NSInteger				rowCount = [self numberOfRowsInSection: path.section];
	
	if (path.row < (rowCount - 1)) return [NSIndexPath indexPathForRow: path.row + 1 inSection: path.section];
	
	NSInteger				sectionCount = [self numberOfSections], section = path.section;
	while (section < (sectionCount - 1)) {
		rowCount = [self numberOfRowsInSection: ++section];
		if (rowCount) return [NSIndexPath indexPathForRow: 0 inSection: section];
	}
	return nil;
}
@end

@implementation NSString (MM_RecordFieldsTable)
- (BOOL) isValidUSPhone {
	NSString			*phone = [self stringByStrippingCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet] options: 0];
	if ([phone hasPrefix: @"1"]) phone = [phone substringFromIndex: 1];
	
	return self.length == 0 || phone.length == 10;
}

- (BOOL) isValidZIPCode {
	NSString			*zipCode = [self stringByStrippingCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet] options: 0];
	
	return zipCode.length == 9 || zipCode.length == 5;
}

@end
