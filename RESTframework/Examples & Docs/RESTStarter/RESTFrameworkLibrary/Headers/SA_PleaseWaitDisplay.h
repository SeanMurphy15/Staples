//
//  SA_PleaseWaitDisplay.h
//
//  Created by Ben Gottlieb on 4/3/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SA_PleaseWaitDisplayDelegate <NSObject>
@optional;
- (void) pleaseWaitCancelPressed;
- (void) pleaseWaitAuxPressed;
@end

@interface SA_PleaseWaitDisplay : NSObject {
	NSString							*_cancelTitle, *_auxTitle, *_minorText, *_majorText;
	BOOL								_spinnerHidden;
	id <SA_PleaseWaitDisplayDelegate>	_delegate;
	
	
	UILabel								*_majorLabel, *_minorLabel;
	UIActivityIndicatorView				*_spinner;
	UIProgressView						*_progressIndicator;
	UIButton							*_cancelButton, *_auxButton;
	UIView								*_view, *_container;
	
	UIFont								*_majorFont, *_minorFont;
	
	BOOL								_majorLabelPositionedWithSpinner, _hidden;
	CALayer								*_grayLayer;
	UIInterfaceOrientation				_currentOrientation;
}

@property (nonatomic, readwrite, strong) NSString *cancelTitle, *auxTitle, *minorText, *majorText;
@property (nonatomic, readwrite) float progressValue;
@property (nonatomic, readwrite, strong) id <SA_PleaseWaitDisplayDelegate> delegate;
@property (nonatomic, readwrite) BOOL spinnerHidden, progressBarHidden;
@property (nonatomic, readonly) BOOL hidden;
@property (nonatomic, readwrite, strong) UIFont *majorFont, *minorFont;
@property (nonatomic, readonly) UIView *sibling;
@property (nonatomic, readwrite) UIInterfaceOrientation currentOrientation;
@property (nonatomic, readonly) CGRect majorLabelFrame, minorLabelBounds, contentBounds, contentFrame, auxButtonFrame, spinnerFrame, progressIndicatorFrame;
@property (nonatomic, copy) simpleBlock cancelBlock;

@property(nonatomic, readonly) UIView *view;

+ (SA_PleaseWaitDisplay *) showPleaseWaitDisplayWithMajorText: (NSString *) major minorText: (NSString *) minor cancelLabel: (NSString *) cancel showProgressBar: (BOOL) showProgressBar delegate: (id <SA_PleaseWaitDisplayDelegate>) delegate;
+ (void) hidePleaseWaitDisplay;
+ (SA_PleaseWaitDisplay *) pleaseWaitDisplay;
+ (SA_PleaseWaitDisplay *) showPleaseWaitDisplay: (NSString *) major;

+ (void) setCancelButtonImageName: (NSString *) name withPressedImageName: (NSString *) pressed;
+ (void) setAuxButtonImageName: (NSString *) name withPressedImageName: (NSString *) pressed;
	

- (void) display;

- (void) setupMajorLabel;
- (void) setupMinorLabel;
- (void) setupButtons;
- (void) setupSpinner;
- (void) setupProgressIndicator;
- (void) setProgressValueAsNumber: (NSNumber *) number;

- (UIFont *) minorFont;
- (UIFont *) majorFont;

- (void) deviceOrientationDidChange: (NSNotification *) note;

- (UIWindow *) mainWindow;

- (void) setupBoundsAndTransform;
@end
