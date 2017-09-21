//
//  MM_SABase_ConvenienceMethods.m
//  Monsanto
//
//  Created by Ben Gottlieb on 8/2/13.
//  Copyright (c) 2013 Model Metrics, Inc. All rights reserved.
//

#import "MM_SABase_ConvenienceMethods.h"

@implementation NSSortDescriptor (MM_SABase_ConvenienceMethods)
+ (NSSortDescriptor *) descriptorWithKey: (NSString *) key ascending: (BOOL) ascending { return [self SA_descWithKey: key ascending: ascending]; }
+ (NSArray *) arrayWithDescriptorWithKey: (NSString *) key ascending: (BOOL) ascending { return [self SA_arrayWithDescWithKey: key ascending: ascending]; }
@end

@implementation UIColor (MM_SABase_ConvenienceMethods)
+ (UIColor *)  colorWithHexString: (NSString *) string { return [self colorWithSA_HexString: string]; }
@end

@implementation UIBarButtonItem (MM_SABase_ConvenienceMethods)
+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action { return [self SA_itemWithTitle: title target: target action: action]; }
+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action { return [self SA_itemWithImage:image target: target action: action]; }
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action { return [self SA_itemWithSystemItem: item target: target action: action]; }
+ (id) itemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block { return [self SA_itemWithTitle: title block: block]; }
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block { return [self SA_itemWithSystemItem: item block: block]; }
+ (id) spacerOfWidth: (float) width { return [self SA_spacerOfWidth: width]; }
+ (id) itemWithView: (UIView *) view { return [self SA_itemWithView: view]; }
@end


@implementation UIActionSheet (MM_SABase_ConvenienceMethods)
- (void) addButtonWithTitle: (NSString *) title andTag: (NSInteger) tag { [self addButtonWithTitle: title andSA_Tag: tag]; }
- (NSInteger) tagForButtonAtIndex: (NSUInteger) index { return [self SA_TagForButtonAtIndex: index]; }
- (void) showFromView: (UIView *) view withButtonSelectedBlock: (intArgumentBlock) block { return [self showFromView: view withSA_ButtonSelectedBlock: block]; }
@end

@implementation UIPopoverController (MM_SABase_ConvenienceMethods)

+ (void) dismissAllVisibleSAPopoversAnimated: (BOOL) animated { [self dismissAllVisibleSA_PopoversAnimated: animated]; }
- (void) dismissSAPopoverAnimated: (BOOL) animated { [self dismissSA_PopoverAnimated: animated]; }

@end

@implementation UIViewController (MM_SABase_ConvenienceMethods)
- (UIPopoverController *) SAPopoverController { return [self SA_PopoverController]; }
@end

@implementation NSArray (MM_SABase_ConvenienceMethods)
- (NSArray *) arrayByRemovingObject: (id) object { return [self SA_arrayByRemovingObject: object]; }
- (id) firstObject { return [self SA_firstObject]; }
@end

@implementation UIGestureRecognizer (MM_SABase_ConvenienceMethods)
- (id) initWithBlock: (gestureArgumentBlock) block { return [self initWithSA_Block: block]; }
+ (id) longPressRecognizerWithPressBlock: (gestureArgumentBlock) block { return [self SA_longPressRecognizerWithPressBlock: block]; }
@end