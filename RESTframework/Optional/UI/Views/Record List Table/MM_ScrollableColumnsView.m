//
//  MM_ScrollableColumnsView.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 11/29/11.
//  Copyright (c) 2011 Stand Alone, Inc. All rights reserved.
//

#import "MM_ScrollableColumnsView.h"
#import "MM_RecordFieldColumnView.h"
#import "NSString+MM_String.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define kNotification_SBRowViewDidScroll		@"kNotification_SBRowViewDidScroll"

@interface MM_ScrollableColumnsView ()
- (CGFloat) standardWithForFieldOfType: (NSAttributeType) type;
@end

@implementation MM_ScrollableColumnsView
@synthesize objectDefinition = _objectDefinition, isHeader, evenColumnBackgroundColor, oddColumnBackgroundColor, evenColumnTextColor, oddColumnTextColor, contentFont, headerFont;
@synthesize object = _object;

- (void) dealloc {
	[self removeAsObserver];
}

+ (id) headerViewWithFrame: (CGRect) frame displayingObjectType: (MM_SFObjectDefinition *) objectDefinition {
	MM_ScrollableColumnsView				*view = [[MM_ScrollableColumnsView alloc] initWithFrame: frame];
	
	view.isHeader = YES;
	view.backgroundColor = [UIColor whiteColor];
	view.showsVerticalScrollIndicator = NO;
	view.showsHorizontalScrollIndicator = NO;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.evenColumnBackgroundColor = [UIColor whiteColor];
	view.oddColumnBackgroundColor = [UIColor colorWithWhite: 0.75 alpha: 0.5];
	view.evenColumnTextColor = [UIColor blackColor];
	view.oddColumnTextColor = [UIColor blackColor];
	view.headerFont = [UIFont boldSystemFontOfSize: 14];
	view.contentFont = [UIFont systemFontOfSize: 14];
	view.delegate = view;
	
	[[NSNotificationCenter defaultCenter] addObserver: view selector: @selector(otherRowDidScroll:) name: kNotification_SBRowViewDidScroll object: nil];
	
	[view performSelector: @selector(setObjectDefinition:) withObject: objectDefinition afterDelay: 0.0];

	
	
	return view;
}

+ (id) viewWithFrame: (CGRect) frame displayingObject: (MMSF_Object *) object ofType: (MM_SFObjectDefinition *) objectType {
	MM_ScrollableColumnsView			*view = [self headerViewWithFrame: frame displayingObjectType: objectType];

	view.isHeader = NO;
	[view performSelector: @selector(setObject:) withObject: object afterDelay: 0.0];
	return view;
}

- (void) scrollViewDidScroll: (UIScrollView *) scrollView {
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SBRowViewDidScroll object: self];
}

- (void) otherRowDidScroll: (NSNotification *) note {
	MM_ScrollableColumnsView		*view = note.object;
	
	if (view == self) return;
	
	self.contentOffset = view.contentOffset;
}

//=============================================================================================================================
#pragma mark Properties
- (void) setObjectDefinition: (MM_SFObjectDefinition *) objectDefinition {
	[self removeAllSubviews];
	
	_objectDefinition = objectDefinition;
	
	CGRect						bounds = self.bounds;
	CGFloat						left = 0;
	NSInteger					fieldCount = 0;
	UIFont						*measureFont = self.headerFont;
	UIFont						*font = self.isHeader ? self.headerFont : self.contentFont;
	
	for (NSDictionary *field in objectDefinition.queriedFields) {
		NSString				*fieldName = [field objectForKey: @"name"];
		NSString				*fieldType = [field objectForKey: @"type"];
		if ([fieldType isEqual: @"reference"]) continue;
		CGSize					labelSize = [fieldName sizeWithFont: measureFont];
		CGFloat					fieldWidth = MAX(labelSize.width + 10, [self standardWithForFieldOfType: [fieldType convertToAttributeType]]);
		UILabel					*label = [[UILabel alloc] initWithFrame: CGRectMake(left, 0, fieldWidth, bounds.size.height)];
		
		label.backgroundColor = (++fieldCount % 2) ? self.oddColumnBackgroundColor : self.evenColumnBackgroundColor;
		label.textColor = (fieldCount % 2) ? self.oddColumnTextColor : self.evenColumnTextColor;
		label.font = font;
		label.textAlignment = NSTextAlignmentCenter;
		label.text = fieldName;
		[self addSubview: label];
		left += label.bounds.size.width;
	}
	
	self.contentSize = CGSizeMake(left, bounds.size.height);
}

- (void) setObject: (MMSF_Object *) object {
	[self removeAllSubviews];
	
	_object = object;
	
	CGRect						bounds = self.bounds;
	CGFloat						left = 0;
	NSInteger					fieldCount = 0;
	UIFont						*measureFont = self.headerFont;
	UIFont						*font = self.isHeader ? self.headerFont : self.contentFont;
	
	for (NSDictionary *field in self.objectDefinition.queriedFields) {
		NSString				*fieldName = [field objectForKey: @"name"];
		NSString				*fieldType = [field objectForKey: @"type"];
		if ([fieldType isEqual: @"reference"]) continue;
		NSAttributeType			type = [fieldType convertToAttributeType];
		id						value = [self.object valueForKey: fieldName];
		CGSize					labelSize = [fieldName sizeWithFont: measureFont];
		CGFloat					fieldWidth = MAX(labelSize.width + 10, [self standardWithForFieldOfType: type]);
		UILabel					*label = [[UILabel alloc] initWithFrame: CGRectMake(left, 0, fieldWidth, bounds.size.height)];
		
		label.backgroundColor = (++fieldCount % 2) ? self.oddColumnBackgroundColor : self.evenColumnBackgroundColor;
		label.textColor = (fieldCount % 2) ? self.oddColumnTextColor : self.evenColumnTextColor;
        
		label.highlightedTextColor = [UIColor whiteColor];
		
		label.font = font;
		
		if (value) {
			switch (type) {
				case NSUndefinedAttributeType:		
				case NSInteger16AttributeType:			
				case NSInteger32AttributeType:			
				case NSInteger64AttributeType:	
				case NSDecimalAttributeType:			
				case NSDoubleAttributeType:				
				case NSFloatAttributeType:				
				case NSStringAttributeType:				
					label.text = $S(@"%@", value); 
					break;
					
				case NSBooleanAttributeType:			
					label.text = $S(@"%@", [value boolValue] ? @"Yes" : @"No");

					break;

				case NSDateAttributeType:				
					label.text = $S(@"%@ %@", [value shortDateString], [value shortTimeString]);
					break;
					
				case NSBinaryDataAttributeType:			
					label.text = $S(@"<%d bytes>", (UInt16) [value length]);
					break;
					
				case NSTransformableAttributeType:
					label.text = @"Transform";
					break;
					
				default:
                    NSLog(@"defaulting on type:");
					break;
			}
		} 

		label.textAlignment = NSTextAlignmentCenter;
		if (type == NSStringAttributeType) {
			if ([label.text sizeWithFont: label.font].width > label.bounds.size.width)
				label.textAlignment = NSTextAlignmentLeft;
		} 
		[self addSubview: label];
		left += label.bounds.size.width;
	}
	
	self.contentSize = CGSizeMake(left, bounds.size.height);
}


//=============================================================================================================================
#pragma mark Utility
- (CGFloat) standardWithForFieldOfType: (NSAttributeType) type {
	switch (type) {
		case NSUndefinedAttributeType:			return 0;
		case NSInteger16AttributeType:			
		case NSInteger32AttributeType:			
		case NSInteger64AttributeType:			return 30;
		case NSDecimalAttributeType:			
		case NSDoubleAttributeType:				
		case NSFloatAttributeType:				return 35;
		case NSStringAttributeType:				return RUNNING_ON_IPAD ? 220 : 120;
		case NSBooleanAttributeType:			return 15;
		case NSDateAttributeType:				return 60;
		case NSBinaryDataAttributeType:			return 100;
		case NSTransformableAttributeType:		return 25;
		case NSObjectIDAttributeType:			
		default:
			return 0;
			break;
	}
}

@end
#pragma clang diagnostic pop
