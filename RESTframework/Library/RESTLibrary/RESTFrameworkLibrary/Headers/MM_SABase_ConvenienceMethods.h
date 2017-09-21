//
//  MM_SABase_ConvenienceMethods.h
//  Monsanto
//
//  Created by Ben Gottlieb on 8/2/13.
//  Copyright (c) 2013 Model Metrics, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#if (__has_feature(objc_arc))
	#define			autorelease					self
	#define			release						self
#endif

@interface NSSortDescriptor (MM_SABase_ConvenienceMethods)
+ (NSSortDescriptor *) descriptorWithKey: (NSString *) key ascending: (BOOL) ascending;
+ (NSArray *) arrayWithDescriptorWithKey: (NSString *) key ascending: (BOOL) ascending;
@end

@interface UIColor (MM_SABase_ConvenienceMethods)
+ (UIColor *)  colorWithHexString: (NSString *) string;
@end

@interface UIBarButtonItem (MM_SABase_ConvenienceMethods)
+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;

+ (id) itemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block;

+ (id) spacerOfWidth: (float) width;

+ (id) itemWithView: (UIView *) view;
@end


@interface UIActionSheet (MM_SABase_ConvenienceMethods)
- (void) addButtonWithTitle: (NSString *) title andTag: (NSInteger) tag;
- (NSInteger) tagForButtonAtIndex: (NSUInteger) index;
- (void) showFromView: (UIView *) view withButtonSelectedBlock: (intArgumentBlock) block;
@end

@interface UIPopoverController (MM_SABase_ConvenienceMethods)
+ (void) dismissAllVisibleSAPopoversAnimated: (BOOL) animated;
- (void) dismissSAPopoverAnimated: (BOOL) animated;
@end

@interface UIView (MM_SABase_ConvenienceMethods)
- (UIPopoverController *) SAPopoverController;
@end

@interface UIViewController (MM_SABase_ConvenienceMethods)
- (UIPopoverController *) SAPopoverController;
@end

@interface NSArray (MM_SABase_ConvenienceMethods)
- (NSArray *) arrayByRemovingObject: (id) object;
- (id) firstObject;
@end

@interface UIGestureRecognizer (MM_SABase_ConvenienceMethods)
- (id) initWithBlock: (gestureArgumentBlock) block;
+ (id) longPressRecognizerWithPressBlock: (gestureArgumentBlock) block;
@end