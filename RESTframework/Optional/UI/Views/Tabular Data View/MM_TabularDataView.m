//
//  MM_TabularDataView.m
//  iVisit
//
//  Created by Ben Gottlieb on 6/23/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "MM_TabularDataView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#define SIMPLE_REFRESH_SETTER(type, attr, upAttr)	- (void) set##upAttr: (type) arg_##attr { _##attr = arg_##attr; [self setNeedsDisplay]; }
#define OBJECT_REFRESH_SETTER(attr, upAttr)			- (void) set##upAttr: (id) arg_##attr { _##attr = arg_##attr; [self setNeedsDisplay]; }

@interface MM_TabularDataView ()
- (NSTextAlignment) alignmentForColumn: (NSInteger) index;
- (UIFont *) fontForColumn: (NSInteger) index;
@end

@implementation MM_TabularDataView
@synthesize columnWidths = _columnWidths, leftIndent = _leftIndent, font = _font, fonts = _fonts, alignments = _alignments, columns = _columns;
@synthesize columnSpacing = _columnSpacing, dividerColor = _dividerColor, textColor = _textColor;

- (void) commonInit
{
    self.font = [UIFont systemFontOfSize: 14];
    self.contentMode = UIViewContentModeRedraw;
    self.userInteractionEnabled = NO;
    self.textColor = [UIColor blackColor];
}

- (void) awakeFromNib
{
    [self commonInit];
}

- (id) initWithFrame: (CGRect) frame {
	if ((self = [super initWithFrame: frame])) {
        [self commonInit];
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return self;
}

- (void) drawRect: (CGRect) rect {
	CGFloat					x = self.columnSpacing;
	CGFloat					totalWidth = 0, scalingFactor = 1.0;
	NSInteger				index = 0;
	
	[self.backgroundColor set];
	UIRectFill(self.bounds);
	
	[self.textColor set];
	for (NSNumber *width in self.columnWidths) totalWidth += width.floatValue;
	scalingFactor = (self.bounds.size.width - self.columnSpacing * (self.columnWidths.count + 1)) / totalWidth;
	
	SA_Assert(self.columns.count == self.columnWidths.count, @"The number of columns must match the number of widths");
	for (NSString *column in self.columns) {
		CGFloat				width = [[self.columnWidths objectAtIndex: index] floatValue] * scalingFactor;
		CGRect				textFrame = CGRectMake((index == 0 && self.leftIndent) ? self.leftIndent : x, 0, width - (index == 0 ? self.leftIndent : 0), self.bounds.size.height);
		NSTextAlignment		align = [self alignmentForColumn: index];
		UIFont				*font = [self fontForColumn: index];
		NSLineBreakMode		lineBreakMode = NSLineBreakByTruncatingTail;
		
		switch (align) {
			case NSTextAlignmentRight:
				lineBreakMode = NSLineBreakByTruncatingHead;
				break;
				
			default:
				break;
		} 
		
		CGSize					size = [column sizeWithFont: font];
		CGRect					actualFrame;
		
		if (align == NSTextAlignmentCenter) {
			actualFrame = CGRectMake(textFrame.origin.x + MAX(0, textFrame.size.width - size.width) / 2, 
									 textFrame.origin.y + MAX(0, textFrame.size.height - size.height) / 2,
									 MIN(textFrame.size.width, size.width), MIN(textFrame.size.height, size.height));
		} else if (align == NSTextAlignmentRight){
			actualFrame = CGRectMake(textFrame.origin.x + (textFrame.size.width - size.width),
									 textFrame.origin.y + MAX(0, textFrame.size.height - size.height) / 2,
									 MIN(textFrame.size.width, size.width), MIN(textFrame.size.height, size.height));
		} else {
        actualFrame = CGRectMake(textFrame.origin.x,
                                 textFrame.origin.y + MAX(0, textFrame.size.height - size.height) / 2,
                                 MIN(textFrame.size.width, size.width), MIN(textFrame.size.height, size.height));
        }
		
		[column drawInRect: actualFrame withFont: font lineBreakMode: lineBreakMode alignment: align];
		if (self.dividerColor && index > 0) {
			[self.dividerColor setFill];
			UIRectFill(CGRectMake(x - (self.columnSpacing - 1) / 2, 0, 1.0, self.bounds.size.height));
			[self.textColor set];
		}
		x += (width + self.columnSpacing);
		index++;
	}
}



- (NSTextAlignment) alignmentForColumn: (NSInteger) index {
	if (index < self.alignments.count) return [[self.alignments objectAtIndex: index] intValue];
	if (self.alignments.count) return [self.alignments.lastObject intValue];
	return index == 0 ? NSTextAlignmentLeft : NSTextAlignmentCenter;
}

- (UIFont *) fontForColumn: (NSInteger) index {
	if (index < self.fonts.count) return [self.fonts objectAtIndex: index];
	return self.font;
}

OBJECT_REFRESH_SETTER(columns, Columns)
OBJECT_REFRESH_SETTER(fonts, Fonts)
OBJECT_REFRESH_SETTER(font, Font)
OBJECT_REFRESH_SETTER(alignments, Alignments)
OBJECT_REFRESH_SETTER(columnWidths, ColumnWidths)
OBJECT_REFRESH_SETTER(dividerColor, DividerColor)
OBJECT_REFRESH_SETTER(textColor, TextColor)
SIMPLE_REFRESH_SETTER(CGFloat, leftIndent, LeftIndent)
SIMPLE_REFRESH_SETTER(CGFloat, columnSpacing, ColumnSpacing)
@end

#pragma clang diagnostic pop
