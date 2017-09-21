//
//  DSA_NLevelCategoryImageView.m
//  ios_dsa
//
//  Created by Chris Cieslak on 7/29/13.
//
//

#import "DSA_NLevelCategoryImageView.h"
#import "UIImage+NLevelIcons.h"
#import "MMSF_Attachment.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "DSA_AppDelegate.h"
#import "MM_ContextManager.h"

#define NLevelImageSize 236
#define kGenerateDynamicCategoryIcon 0

static CGFloat   NLevelImage_DefaultWidth           = 150.0;
static CGFloat   NLevelImage_DefaultImageHeight     = 236.0;
static CGSize    NLevelImage_DefaultSize;
static CGFloat   NLevelImage_DefaultFontSize        = 16.0;
static UIFont   *NLevelImage_DefaultFont;
static int       NLevelImage_MaxNumberOfLines       = 2;

@interface DSA_NLevelCategoryImageView ()

- (void)generateDynamicCategoryIcon;

@end

@implementation DSA_NLevelCategoryImageView


/**
 *
 */
+ (void) initialize {
    
    NLevelImage_DefaultFont = [UIFont boldSystemFontOfSize: NLevelImage_DefaultFontSize];
    
    NLevelImage_DefaultSize = CGSizeMake(NLevelImage_DefaultWidth,
                                         NLevelImage_DefaultImageHeight + NLevelImage_DefaultFont.lineHeight * 2.0);
}


/**
 *
 */
+ (CGSize) defaultSize {
	return NLevelImage_DefaultSize;

#if 0
	CGFloat					imageSize = NLevelImageSize, labelHeight = 14;
	
	imageSize /= 2;
	return CGSizeMake(imageSize, imageSize + labelHeight);
#endif	
}

+ (id) viewWithCategory: (MMSF_Category__c *) category inBounds: (CGRect) bounds {
	DSA_NLevelCategoryImageView	*view = [[DSA_NLevelCategoryImageView alloc] initWithFrame: bounds];
	
    view.category = category;
    
    [view buildLabel];
    [view configureAccessibility];

#if 0
    view.label.text = category.Name;
	view.categoryImageView.accessibilityLabel = $S(@"Image for %@", category.Name);
	view.accessibilityLabel = $S(@"Select %@", category.Name);
	view.isAccessibilityElement = YES;
    
#ifdef kGenerateDynamicCategoryIcon
    if (![category hasAttachment]) {
        [view generateDynamicCategoryIcon];
    }
#endif
#endif    
	return view;
}

/**
 *
 */
+ (CGSize) defaultImageSize {
    
    return CGSizeMake(NLevelImage_DefaultWidth, NLevelImage_DefaultImageHeight);
}


/**
 *
 */
+ (void) setDefaultImageHeight: (CGFloat) height {
    
    NLevelImage_DefaultImageHeight = height;
    
    NLevelImage_DefaultSize = CGSizeMake(NLevelImage_DefaultWidth,
                                         NLevelImage_DefaultImageHeight + NLevelImage_DefaultFont.lineHeight * 2.0);
}

/**
 *
 */
- (void) buildLabel {
    
    NSString    *string     = self.category.Name;
    CGSize       size       = CGSizeZero;
    
    if (RUNNING_ON_70) {
        
        CGRect frame = [string boundingRectWithSize: CGSizeMake(NLevelImage_DefaultSize.width, NLevelImage_DefaultSize.height)
                                            options: (NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                         attributes: @{NSFontAttributeName: NLevelImage_DefaultFont}
                                            context: nil];
        size = frame.size;
    }
    else {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        size = [string sizeWithFont: NLevelImage_DefaultFont
                  constrainedToSize: CGSizeMake(NLevelImage_DefaultSize.width, NLevelImage_DefaultSize.height)
                      lineBreakMode: NSLineBreakByWordWrapping];
        
#pragma clang diagnostic pop
    }
    
    int numberOfLines = size.height / NLevelImage_DefaultFont.lineHeight;
    if (numberOfLines > NLevelImage_MaxNumberOfLines)
        numberOfLines = NLevelImage_MaxNumberOfLines;
    
    CGRect frame = self.bounds;
   
    if (!_label)
        _label = [[UILabel alloc] initWithFrame: frame];
    
    _label.backgroundColor = [UIColor clearColor];
    _label.textColor = [UIColor whiteColor];
    _label.numberOfLines = numberOfLines;
    _label.font = NLevelImage_DefaultFont;
    _label.text = self.category.Name;
    
    [self addSubview: _label];
}


/**
 *
 */
- (void) configureAccessibility {
    
	self.label.accessibilityLabel = $S(@"Label for %@", self.category.Name);
	self.categoryImageView.accessibilityLabel = $S(@"Image for %@", self.category.Name);
	self.accessibilityLabel = $S(@"Select %@", self.category.Name);
    
	self.isAccessibilityElement = YES;
}

// Load the image for this category in the background
- (void)loadImageinQueue:(NSOperationQueue*)queue {
	
    NSBlockOperation *imgOp = [[NSBlockOperation alloc] init];
	CGFloat	maxWidth = CGRectGetWidth(self.categoryImageView.frame);
  
  /**
   * Create weak references vars so that we don't end up with retain cycles
   * in the block operations.
   */
  
    __weak typeof(self) weakSelf       = self;
    __weak typeof(imgOp) weakOperation = imgOp;
	
    [imgOp addExecutionBlock:^{
        if (weakOperation.isCancelled) {
            return;
        }
        
        UIImage *image    = nil;
        MMSF_Attachment *attachment = [weakSelf.category attachment];
        if (!attachment || weakOperation.isCancelled) {
            return;
        }
        
        NSString *attachmentPath = [attachment filepath];
        if (!attachmentPath || weakOperation.isCancelled) {
            return;
        }
		
		CGSize imgSize = [UIImage imageSizeFromPath:attachmentPath];
    
		if ((imgSize.width > NLevelImageSize) || (imgSize.height > NLevelImageSize)) {
            image = [UIImage resizeImageToMaxSize:maxWidth path:attachmentPath];
		} else {
            NSData *imageData = [NSData dataWithContentsOfFile:attachmentPath];
			image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
		}
		
		if (weakOperation.isCancelled || !image) {
			return;
        }
    
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if (weakOperation.isCancelled) {
				return;
            }
      
			weakSelf.categoryImageView.image = image;
        }];
	}];
	
    [queue addOperation:imgOp];
}

#if 0
- (UILabel *) label {
	if (_label == nil) {
        CGFloat	height = 14;
		_label = [[UILabel alloc] initWithFrame: CGRectMake(0, self.bounds.size.height - height, self.bounds.size.width, height)];
		
        _label.textColor = [self labelTextColor];
        _label.accessibilityLabel = $S(@"Label for %@", self.category.Name);
        _label.backgroundColor = [UIColor clearColor];
        _label.font = [UIFont fontWithName: @"AmericanTypewriter" size: 12];
        _label.textAlignment = NSTextAlignmentCenter;
		[self addSubview: _label];
        
	}
	return _label;
}
#endif

- (UIImageView *) categoryImageView {
	if (_categoryImageView == nil) {
		_categoryImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, [DSA_NLevelCategoryImageView defaultSize].width, [DSA_NLevelCategoryImageView defaultSize].width)];
		_categoryImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		_categoryImageView.center = CGPointMake(CGRectMidpoint(self.bounds).x, CGRectMidpoint(_categoryImageView.bounds).y);
		_categoryImageView.contentMode = UIViewContentModeScaleAspectFit;
		_categoryImageView.clipsToBounds = YES;
		_categoryImageView.accessibilityLabel = $S(@"View Category: %@", self.category.Name);
		[self addSubview: _categoryImageView];
	}
	return _categoryImageView;
}

- (UIColor *)labelTextColor {
    MMSF_MobileAppConfig__c	*mac = [g_appDelegate selectedMobileAppConfig];
    MMSF_CategoryMobileConfig__c *config = [mac configForCategory:self.category];
    
    UIColor *textColor = [config galleryHeadingTextColor];

    return textColor;
}

- (void)generateDynamicCategoryIcon {
    // for subcategories without an image
    CALayer *layer = self.categoryImageView.layer;
    CGFloat	maxWidth = CGRectGetWidth(self.categoryImageView.frame);
    CGRect frame = CGRectMake(10, 10, maxWidth - 20, maxWidth - 20);
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:frame].CGPath;
    circleLayer.fillColor = [UIColor colorWithWhite:1.0 alpha:0.85].CGColor;
    [layer addSublayer:circleLayer];
    
    NSString *name = self.category.Name;
    NSUInteger length = name.length > 1 ? 2 : 1;
    NSString * initials = [name substringWithRange:NSMakeRange(0, length)];
    NSArray *words = [name componentsSeparatedByString:@" "];
    if (words.count > 1) {
        NSRange range = NSMakeRange(0, 1);
        initials = [NSString stringWithFormat:@"%@%@", [words[0] substringWithRange:range], [words[1] substringWithRange:range]];
    }
    
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.string = initials;
    UIFont *font = [UIFont fontWithName:@"Helvetica-Light" size:48];
    textLayer.font = (__bridge CFTypeRef)font;
    textLayer.fontSize = 48;
    textLayer.alignmentMode = kCAAlignmentCenter;
    // unfortunately, no CAConstraintLayoutManager for iOS yet
    CGFloat topPadding = (frame.size.height - font.lineHeight)/2;
    frame.origin.y += topPadding;
    frame.size.height = font.lineHeight;
    textLayer.frame = frame;
    textLayer.foregroundColor = [UIColor blackColor].CGColor;
    [layer addSublayer:textLayer];
    
    [layer setNeedsDisplay];
}


@end
