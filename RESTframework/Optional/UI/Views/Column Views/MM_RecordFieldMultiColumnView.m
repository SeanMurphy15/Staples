//
//  MM_RecordFieldMultiColumnView.m
//
//  Created by Ben Gottlieb on 12/23/11.
//  Copyright (c) 2011 Model Metrics, Inc. All rights reserved.
//

#import "MM_RecordFieldMultiColumnView.h"
#import "MM_RecordFieldColumnView.h"

@interface MM_RecordFieldMultiColumnView ()
@property (nonatomic, strong) NSArray *columnViews; 
@property (nonatomic) CGFloat keyboardHeightAdjustment;
@property (nonatomic) BOOL fieldsNeedLayout;

@end

@implementation MM_RecordFieldMultiColumnView
@synthesize columnViews, fields = _fields, record = _record, horizontalSpacing, edgeInsets;
@synthesize showMultipleLines, labelFont = _labelFont, contentFont = _contentFont, labelColor = _labelColor, contentColor = _contentColor, dividerPosition, noFixedDivider, autoCalculateDivider;
@synthesize columnBackgroundColor, contentFrame, viewController = _viewController;
@synthesize labelTextAlignment = _labelTextAlignment, contentTextAlignment = _contentTextAlignment, labelContentSpacing = _labelContentSpacing, useCenterAlignedLabels = _useCenterAlignedLabels;
@synthesize columnViewDelegate = _columnViewDelegate, editing = _editing, lineHeight = _lineHeight, keyboardHeightAdjustment;
@synthesize fieldsNeedLayout;

- (void) dealloc {
	[self removeAsObserver];
}

- (id) initWithFrame: (CGRect) frame {
    if ((self = [super initWithFrame: frame])) [self postInitSetup];
    return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder {
	if ((self = [super initWithCoder: aDecoder])) [self postInitSetup];
	return self;
}

- (void) postInitSetup {
	self.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
	self.contentFrame = self.bounds;
	self.horizontalSpacing = 10;
	self.autoCalculateDivider = YES;

	[self addAsObserverForName: UIKeyboardWillShowNotification selector: @selector(keyboardWillShow:)];
	[self addAsObserverForName: UIKeyboardWillHideNotification selector: @selector(keyboardWillHide:)];
}

- (void) reloadData {
	for (MM_RecordFieldColumnView *view in self.columnViews) { [view reloadData]; }
}



- (BOOL) canBecomeFirstResponder {
	for (MM_RecordFieldColumnView *view in self.columnViews) {
		if (view.canBecomeFirstResponder) return YES;
	}
	return NO;
}

- (BOOL) becomeFirstResponder {
	[super becomeFirstResponder];
	for (MM_RecordFieldColumnView *view in self.columnViews) {
		if (!view.becomeFirstResponder) return NO;
	}
	return YES;
}

- (BOOL) resignFirstResponder {
	for (MM_RecordFieldColumnView *view in self.columnViews) {
		if (view.resignFirstResponder) return YES;
	}
	return [super resignFirstResponder];
}

- (void) setNeedsFieldLayout {
	self.fieldsNeedLayout = YES;
	[self setNeedsLayout];
}

- (void) setFrame: (CGRect) frame {
	if (frame.size.width != self.frame.size.width) [self setNeedsFieldLayout];
	[super setFrame: frame];
	self.edgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
	self.contentFrame = self.bounds;
}

- (void) layoutSubviews {
	[super layoutSubviews];
	if (self.fields.count && self.fieldsNeedLayout) {
		CGFloat				columnWidth = floorf((self.contentFrame.size.width - (self.horizontalSpacing * (self.fields.count - 1) + self.edgeInsets.left + self.edgeInsets.right + self.contentFrame.origin.x)) / self.fields.count);
		CGFloat				left = self.edgeInsets.left + self.contentFrame.origin.x;
		CGFloat				maxHeight = 0;
		
		if (self.columnViews != nil) {
			for (MM_RecordFieldColumnView *column in self.columnViews) {
				column.frame = CGRectMake(left, 0, columnWidth, self.contentFrame.size.height);
				left += columnWidth;
			}
		} else {
			NSMutableArray			*columns = [NSMutableArray array];
			
			for (NSArray *fieldSet in self.fields) {
				MM_RecordFieldColumnView				*column = [[MM_RecordFieldColumnView alloc] initWithFrame: CGRectMake(left, self.edgeInsets.top + self.contentFrame.origin.y, columnWidth, self.contentFrame.size.height - (self.contentFrame.origin.y + self.edgeInsets.top + self.edgeInsets.bottom))];
				
				//IF_SIM(column.layer.borderColor = [UIColor lightGrayColor].CGColor; column.layer.borderWidth = 1.0; );
				
				column.backgroundColor = self.columnBackgroundColor ?: self.backgroundColor;
				column.fields = fieldSet;
				column.labelTextAlignment = self.labelTextAlignment;
				column.contentTextAlignment = self.contentTextAlignment;
				column.record = self.record;
				column.labelContentSpacing = self.labelContentSpacing;
				column.lineHeight = self.lineHeight;
				column.showMultipleLines = self.showMultipleLines;
				column.autoCalculateDivider = self.autoCalculateDivider;
				column.noFixedDivider = self.noFixedDivider;
				column.viewController = self.viewController;
				column.editing = self.editing;
				column.columnViewDelegate = self.columnViewDelegate;
				if (self.useCenterAlignedLabels) column.useCenterAlignedLabels = self.useCenterAlignedLabels;
				if (self.labelColor) column.labelColor = self.labelColor;
				if (self.labelFont) column.labelFont = self.labelFont;
				if (self.contentColor) column.contentColor = self.contentColor;
				if (self.contentFont) column.contentFont = self.contentFont;
				
				[self addSubview: column];
				[columns addObject: column];

				left += columnWidth + self.horizontalSpacing;
				maxHeight = MAX(maxHeight, column.contentHeight);
			}
			
			self.columnViews = columns;
		}
		if (maxHeight > self.bounds.size.height) {
			self.contentSize = CGSizeMake(self.frame.size.width, maxHeight + 10);
		} else {
			self.contentSize = self.bounds.size;
		}
		self.fieldsNeedLayout = NO;
	}
}

- (void) setContentOffset: (CGPoint) offset {
	if (!self.dragging && !self.tracking && !self.decelerating && offset.y < 0) offset.y = 0;
	[super setContentOffset: offset];
}

//=============================================================================================================================
#pragma mark properties

- (void) setColumnViewDelegate: (id <MM_RecordFieldColumnViewDelegate>) delegate {
	_columnViewDelegate = delegate;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.columnViewDelegate = delegate;
}

- (void) setEditing: (BOOL) editing animated: (BOOL) animated {
	_editing = editing;
	if (!editing) [self resignFirstResponder];
	for (MM_RecordFieldColumnView *view in self.columnViews) [view setEditing: editing animated: animated];
}

- (void) setEditing: (BOOL) editing {
	_editing = editing;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.editing = editing;
}

- (void) setFields: (NSArray *) fields {
	_fields = fields;
	for (UIView *view in self.columnViews) [view removeFromSuperview];
	[self removeAllSubviews];
	self.columnViews = nil;
	[self setNeedsFieldLayout];
}

- (void) setRecord: (MMSF_Object *) record {
	_record = record;
	for (UIView *view in self.columnViews) [view removeFromSuperview];
	self.columnViews = nil;
	[self setNeedsFieldLayout];
}

- (void) saveCurrentField {
	for (MM_RecordFieldColumnView *v in self.columnViews) {
		[v saveCurrentField];
	}
}

- (void) updateField: (NSString *) field {
	for (MM_RecordFieldColumnView *v in self.columnViews) {
		[v updateField: field];
	}
}

- (void) setLabelFont: (UIFont *) labelFont {
	_labelFont = labelFont;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.labelFont = labelFont;
}

- (void) setLabelColor: (UIColor *) labelColor {
	_labelColor = labelColor;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.labelColor = labelColor;
}

- (void) setContentFont: (UIFont *) contentFont {
	_contentFont = contentFont;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.contentFont = contentFont;
}

- (void) setContentColor: (UIColor *) contentColor {
	_contentColor = contentColor;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.contentColor = contentColor;
}

- (void) setContentTextAlignment: (NSTextAlignment) contentTextAlignment {
	_contentTextAlignment = contentTextAlignment;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.contentTextAlignment = contentTextAlignment;
}

- (void) setLabelTextAlignment: (NSTextAlignment) labelTextAlignment {
	_labelTextAlignment = labelTextAlignment;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.labelTextAlignment = labelTextAlignment;
}

- (void) setLineHeight: (CGFloat) lineHeight {
	_lineHeight = lineHeight;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.lineHeight = lineHeight;
}

- (void) setLabelContentSpacing:(CGFloat)labelContentSpacing {
	_labelContentSpacing = labelContentSpacing;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.labelContentSpacing = labelContentSpacing;
}

- (void) setUseCenterAlignedLabels: (BOOL) useCenterAlignedLabels {
	_useCenterAlignedLabels = useCenterAlignedLabels;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.useCenterAlignedLabels = useCenterAlignedLabels;
}
- (void) setViewController: (UIViewController *) viewController {
	_viewController = viewController;
	for (MM_RecordFieldColumnView *view in self.columnViews) view.viewController = viewController;
}


//=============================================================================================================================
#pragma mark Notifications
- (void) keyboardWillShow: (NSNotification *) note {
    CGRect	keyboardEndingUncorrectedFrame = [[note.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat	duration = 0;// [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect	keyboardEndingFrame = [self convertRect:keyboardEndingUncorrectedFrame  fromView:nil];
	CGRect	overlap = CGRectIntersection(self.bounds, keyboardEndingFrame);
	CGRect	frame = self.frame;
	
	self.keyboardHeightAdjustment = overlap.size.height;
	frame.size.height -= self.keyboardHeightAdjustment;
	
	UIView				*fr = self.firstResponderView;
	CGFloat				newOffset = MIN(fr.frame.origin.y - frame.size.height / 2, self.contentSize.height - frame.size.height);
	
	CGPoint	offset = self.contentOffset;
	offset.y = newOffset;
	
	[UIView animateWithDuration: duration animations: ^{
		self.frame = frame;
		[self setContentOffset: offset animated: YES];
	}];
}

- (void) keyboardWillHide: (NSNotification *) note {
	CGFloat	duration = [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
	CGRect frame = self.frame;
	
	frame.size.height += self.keyboardHeightAdjustment;
	[UIView animateWithDuration: duration animations: ^{
		self.frame = frame;
	}];
}


@end
