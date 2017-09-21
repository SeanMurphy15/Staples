//
//  UISegmentedControl+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 2/4/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISegmentedControl (SA_SA_Additions)
- (void) insertSegmentWithImage: (UIImage *) image atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (SInt16) tag;
- (void) insertSegmentWithTitle: (NSString *) title atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (SInt16) tag;

- (SInt16) tagForSegment: (NSUInteger) index;
@property (nonatomic) SInt16 selectedSegmentTag;
@end
