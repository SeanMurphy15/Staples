//
//  MM_TabularDataView.h
//  iVisit
//
//  Created by Ben Gottlieb on 6/23/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MM_TabularDataView : UIView

@property (nonatomic, strong) NSArray *columnWidths;		//an array of NSNumber-enclosed floats
@property (nonatomic, strong) NSArray *alignments;			//an array of NSNumber-enclosed NSTextAlignments
@property (nonatomic, strong) NSArray *columns;				//an array of strings
@property (nonatomic) CGFloat leftIndent;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSArray *fonts;	
@property (nonatomic, strong) UIColor *dividerColor, *textColor;
@property (nonatomic) CGFloat columnSpacing;

@end
