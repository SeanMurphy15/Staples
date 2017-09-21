//
//  UIView+SA_Additions.h
//
//  Created by Ben Gottlieb on 11/10/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIViewSlideDelegate
- (void) slideDidFinishForView: (UIView *) view;
@end


typedef enum {
	viewSlideDirectionTop,
	viewSlideDirectionLeft,
	viewSlideDirectionRight,
	viewSlideDirectionBottom
} viewSlideDirection;

@interface UIView (UIView_SA_Additions)

@property (nonatomic, readwrite) CGRect normalizedFrame;
@property (nonatomic, readonly) UIView *firstScrollviewChild;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) CGPoint contentCenter;
@property (nonatomic, readonly) UIViewController *viewController;
@property (nonatomic, readonly) UITableViewCell *tableViewCell;
@property (nonatomic) BOOL observingKeyboard;
//@property (nonatomic, readwrite) CGSize size;

+ (UIView *) firstResponderView;
- (UIView *) firstResponderView;
+ (void) resignFirstResponder;
- (BOOL) resignFirstResponderForAllChildren;
- (void) localizeText;

+ (void) chainAnimations: (NSArray *) animations withDurations: (NSArray *) durations;

- (id) firstSubviewOfClass: (Class) classToSearchFor;
- (void) offsetPositionByX: (float) x y: (float) y;
- (void) adjustSizeWidth: (float) width height: (float) height;
- (void) setCenter: (CGPoint) center andSize: (CGSize) size;
- (void) expandWidth: (float) additionalWidth andHeight: (float) additionalHeight;
- (void) compressWidth: (float) removedWidth andHeight: (float) removedHeight;
- (UIImageView *) imageViewCloneUsingLayer: (BOOL) useLayer;

- (BOOL) hasAncestor: (UIView *) ancestor;
- (NSString *) hierarchyToStringWithLevel: (int) level;
- (id) firstSubviewOfClass: (Class) classToSearchFor searchHierarchy: (BOOL) searchHierarchy;
- (void) logHierarchy;
- (UIImage *) toImage;
- (UIImage *) toImageUsingLayer: (BOOL) useLayer;			//pass YES to force the old style -renderInContext-based method
- (UIImage *) toImageUsingLayer: (BOOL) useLayer fromRect: (CGRect) rect;
- (NSArray *) allSubviews;
- (void) removeAllSubviews;
- (void) recursiveSetFont: (UIFont *) font;

- (void) positionInView: (UIView *) view withContentMode: (UIViewContentMode) mode;

//implement - (void) slideDidFinishForView: (UIView *) view if you want callbacks 
//- (void) slideInFrom: (viewSlideDirection) direction inParent: (UIView *) parent delegate: (id) delegate;
//- (void) slideOutTo: (viewSlideDirection) direction removeWhenDone: (BOOL) remove delegate: (id) delegate;

- (void) pulseWithFrequency: (NSTimeInterval) frequency;
- (void) animatePulse;
- (void) addEdgeDividers: (UIEdgeInsets) dividerWidths ofColor: (UIColor *) color;
- (void) animateAndBounceToPoint: (CGPoint) point;
- (void) stopPulsing;
- (UIView *) blockingViewWithTappedBlock: (viewArgumentBlock) block;

- (UIView *) commonAncestorWith: (UIView *) view;
- (BOOL) isSubviewOf: (UIView *) view;

+ (void) maskedTransitionFromView: (UIView *) initialView toView: (UIView *) finalView duration: (NSTimeInterval) duration options: (UIViewAnimationOptions) options completion: (booleanArgumentBlock) completion;


#if BLUR_SUPPORTED
- (BOOL) isBlurred;
- (UIImageView *) blur: (int) blurriness withDuration: (NSTimeInterval) duration;	//returns the UIImageView that was created with the blurred image
- (void) unblurWithDuration: (NSTimeInterval) duration;
- (UIImageView *) preBlur;
- (void) unblur;
#endif
@end


@interface NSString (NSString_LocalizedAdditions)

- (NSString *)localizedString;

@end


