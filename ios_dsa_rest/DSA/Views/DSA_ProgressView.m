//
//  DSA_ProgressView.m
//  ios_dsa
//
//  Created by Steve Deren on 8/19/13.
//
//

#import "DSA_ProgressView.h"
#import <QuartzCore/QuartzCore.h>

#define CONTENT_INSET               100

static DSA_ProgressView * s_currentProgressView = nil;

static NSString * s_cancelButtonImageName = nil;
static NSString * s_cancelButtonPressedImageName = nil;

@interface DSA_ProgressView () {
    UIView * _contentView;
}
@end

@implementation DSA_ProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(deviceOrientationDidChange:)
                                                     name: UIDeviceOrientationDidChangeNotification
                                                   object: nil];
        
        // Setup content views
        _contentView = [[UIView alloc] initWithFrame:CGRectInset(frame, CONTENT_INSET, CONTENT_INSET)];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentView.backgroundColor = [UIColor colorWithWhite:0.1f alpha:0.7f];
        _contentView.clipsToBounds = YES;
        _contentView.layer.cornerRadius = 5.0f;
        
        // TItle Label
        self.labTitle = [self label];
        [_contentView addSubview:self.labTitle];
        
        // Overall Progress - ie step 1 of 10... & shows 10% done
        self.mainProgressViewContainer = [[DSA_ProgressIndicatorView alloc] initWithFrame:CGRectZero];
        self.mainProgressViewContainer.labStatus.text = @"";
        [_contentView addSubview:self.mainProgressViewContainer];
        
        // Detail Progress - ie syncing attachments...  & shows 90% done
        self.detailProgressViewContainer = [[DSA_ProgressIndicatorView alloc] initWithFrame:CGRectZero];
        [_contentView addSubview:self.detailProgressViewContainer];
        self.detailProgressViewContainer.labStatus.text = @"";
        self.detailProgressViewContainer.progressBar.progressTintColor = [UIColor lightGrayColor];
        
        // Cancel Button
        self.cancelButton = [self button];
        [self.cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:self.cancelButton];
        
        [self addSubview:_contentView];
    }
    return self;
}

- (UILabel *)label {
    UILabel * lab = [[UILabel alloc] initWithFrame:CGRectZero];
    lab.backgroundColor = [UIColor clearColor];
    lab.textColor = [UIColor whiteColor];
    lab.font = [UIFont fontWithName:@"Helvetica" size:18];
    lab.textAlignment = NSTextAlignmentCenter;
    lab.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return lab;
}

- (UIButton *)button {
    UIButton * b = [UIButton buttonWithType:UIButtonTypeCustom];
    b.backgroundColor = [UIColor clearColor];
    [b setTitle:@"Cancel" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [b setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    b.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
    b.frame = CGRectMake(0, 0, 100, 100);
    
    UIImage * img = s_cancelButtonImageName ? [[UIImage imageNamed:s_cancelButtonImageName] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] : nil;
    [b setBackgroundImage:img forState:UIControlStateNormal];
    img = s_cancelButtonPressedImageName ? [[UIImage imageNamed:s_cancelButtonPressedImageName] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] : nil;
    [b setBackgroundImage:img forState:UIControlStateHighlighted];
    
    return b;
}

+ (void)setCancelButtonImage:(NSString*)cancelImgName withPressedImage:(NSString*)pressedImgName {
    
    s_cancelButtonImageName = cancelImgName;
    s_cancelButtonPressedImageName = pressedImgName;
    
    if(!s_currentProgressView) return;
    
    UIImage * img = cancelImgName ? [UIImage imageNamed:cancelImgName]:nil;
    UIImage * pressedImg = pressedImgName ? [UIImage imageNamed:pressedImgName]:nil;
    
    [s_currentProgressView.cancelButton setImage:img forState:UIControlStateNormal];
    [s_currentProgressView.cancelButton setImage:pressedImg forState:UIControlStateHighlighted];
}

+ (id)showWithTitle:(NSString*)title {
    
    if(s_currentProgressView) {
        s_currentProgressView.labTitle.text = title ?: @"";
        s_currentProgressView.detailProgressViewContainer.hidden = YES;
        s_currentProgressView.mainProgressViewContainer.hidden = YES;
        [s_currentProgressView handleOrientation:NO];
        return s_currentProgressView;
    }
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    
    DSA_ProgressView * progView = [[DSA_ProgressView alloc] initWithFrame:window.frame];
    progView.backgroundColor = [UIColor clearColor];
    progView.alpha = 0.0f;
    progView.labTitle.text = title ?: @"";
    progView.detailProgressViewContainer.hidden = YES;
    progView.mainProgressViewContainer.hidden = YES;
    [window addSubview:progView];
    [progView fadeIn];
    s_currentProgressView = progView;
    
    return s_currentProgressView;
}

+ (id)showWithTitle:(NSString *)title
          overallText:(NSString *)overallText
           detailText:(NSString *)detailText
      overallProgress:(float)overallProg
       detailProgress:(float)detailProg {
    
    if(s_currentProgressView) {
        
        s_currentProgressView.labTitle.text = title ?: @"";
        s_currentProgressView.mainProgressViewContainer.labStatus.text = overallText ?: @"";
        s_currentProgressView.detailProgressViewContainer.labStatus.text = detailText ?: @"";
        s_currentProgressView.detailProgressViewContainer.progressBar.progress = detailProg;
        s_currentProgressView.mainProgressViewContainer.progressBar.progress = overallProg;
        s_currentProgressView.detailProgressViewContainer.hidden = NO;
        s_currentProgressView.mainProgressViewContainer.hidden = NO;
        [s_currentProgressView handleOrientation:NO];
        return s_currentProgressView;
    }
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    
    DSA_ProgressView * progView = [[DSA_ProgressView alloc] initWithFrame:window.frame];
    progView.backgroundColor = [UIColor clearColor];
    progView.alpha = 0.0f;
    progView.labTitle.text = title ?: @"";
    progView.mainProgressViewContainer.labStatus.text = overallText ?: @"";
    progView.detailProgressViewContainer.labStatus.text = detailText ?: @"";
    progView.detailProgressViewContainer.progressBar.progress = detailProg;
    progView.mainProgressViewContainer.progressBar.progress = overallProg;
    [progView fadeIn];
    [window addSubview:progView];
    
    s_currentProgressView = progView;
    
    return s_currentProgressView;
}

+ (void) showNow {
	s_currentProgressView.alpha = 1.0;
}

- (void)fadeIn {
    [UIView animateWithDuration:0.25 animations:^(void) {
        self.alpha = 1.0f;
    } completion:NULL];
}

- (void)setCancelBlock:(voidBlock)cancelBlock {
    _cancelBlock = cancelBlock;

    self.cancelButton.hidden = _cancelBlock ? NO:YES;
    
    [self setNeedsLayout];
}

- (void)hide {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.cancelBlock = nil;
    self.cancelButton.enabled = NO;
    [s_currentProgressView removeFromSuperview];
    s_currentProgressView = nil;
}

+ (void)hide {
    [s_currentProgressView hide];
}

#pragma mark Layout

- (void)layoutSubviews {
    
    _contentView.frame = CGRectMake(CONTENT_INSET, CONTENT_INSET,
                                    self.bounds.size.width - (CONTENT_INSET*2),
                                    self.bounds.size.height - (CONTENT_INSET*2));
    
    self.labTitle.frame = CGRectMake(10, 10, _contentView.bounds.size.width - 20, 50);
    
    self.mainProgressViewContainer.frame = CGRectMake(50, self.labTitle.frame.size.height + self.labTitle.frame.origin.y,
                                                      _contentView.frame.size.width - 100, 80);
    
    self.detailProgressViewContainer.frame = CGRectMake(80, _contentView.bounds.size.height - 185,
                                                        _contentView.frame.size.width - 160, 80);
    
    self.cancelButton.frame = CGRectMake(_contentView.bounds.size.width/2 - 60, _contentView.bounds.size.height - 60, 120, 40);
}

- (void)didMoveToSuperview {
    [self handleOrientation:NO];
}

#pragma mark - Orientation Notificaitons

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    
    if (!self.superview)
		return;
    
    [self handleOrientation:YES];
}

- (void)handleOrientation:(BOOL)animated
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
    {
        if (self.superview)
        {
            self.bounds = self.superview.bounds;
            [self setNeedsLayout];
        }
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        CGFloat rads = 0;
        
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            
            if (orientation == UIInterfaceOrientationLandscapeLeft) {
                rads = -(CGFloat)M_PI_2;
            }
            else {
                rads = (CGFloat)M_PI_2;
            }
            
            self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
            
        } else {
            if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                rads = (CGFloat)M_PI;
            }
            else {
                rads = 0;
            }
        }
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(rads);
        
        if (animated) {
            [UIView animateWithDuration:0.3 delay:0 options: UIViewAnimationOptionCurveEaseInOut animations:^(void){
                self.transform = rotationTransform;
            } completion:NULL];
        }
        else
            self.transform = rotationTransform;
    } else {
        if (self.superview)
        {
            self.frame = self.superview.frame;
            [self setNeedsLayout];
        }
    }
}

#pragma mark Actions

- (void)cancelPressed {
    
    if(self.cancelBlock) {
        //[self hide];
        self.cancelBlock();
    }
}

@end
