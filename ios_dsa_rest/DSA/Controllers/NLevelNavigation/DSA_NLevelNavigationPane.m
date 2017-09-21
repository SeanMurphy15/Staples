//
//  DSA_NLevelNavigatoinPane.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/29/13.
//
//

#import "DSA_NLevelNavigationPane.h"
#import "DSA_NLevelNavigationController.h"
#import "MMSF_Category__c.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "DSA_NLevelCategoryImageView.h"
#import "MM_FlexibleVisualBrowser.h"
#import "DSA_AppDelegate.h"
#import "Branding.h"

@interface DSA_NLevelNavigationPane ()
@property (nonatomic, strong) NSArray *categories;
@end

static NSOperationQueue			*s_imageQueue = nil;

@implementation DSA_NLevelNavigationPane

- (void) dealloc {
}

+ (id) paneWithCategory: (MMSF_Category__c *) category {
	DSA_NLevelNavigationPane				*pane = [[DSA_NLevelNavigationPane alloc] initWithFrame: CGRectMake(0, 0, [self contentWidth] + [self ridgeWidth], 500)];
	
	//pane.categoryTitleLabel.text = category.Name;
													 
	pane.category = category;
	return pane;
}

+ (CGFloat) contentWidth { return PANE_CONTENT_WIDTH; }
+ (CGFloat) ridgeWidth { return PANE_RIDGE_WIDTH; }

- (id) initWithFrame: (CGRect) frame {
	if (self = [super initWithFrame: frame]) {
		CGFloat					edgeWidth = [[self class] ridgeWidth];
		
		if (s_imageQueue == nil) {
			s_imageQueue = [[NSOperationQueue alloc] init];
			s_imageQueue.maxConcurrentOperationCount = 5;
			s_imageQueue.name = @"com.iosdsa.nlevel.imageQueue";
		}

		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
		self.rightEdgeView = [UIButton buttonWithType: UIButtonTypeCustom];
		self.rightEdgeView.frame = CGRectMake(frame.size.width - edgeWidth, 0, edgeWidth, frame.size.height);
		self.rightEdgeView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
		[self addSubview: self.rightEdgeView];
		
		[(id) self.rightEdgeView addTarget: self action: @selector(reveal:) forControlEvents: UIControlEventTouchUpInside];
		
		if (self.isRootPane) {
			self.rightEdgeView.layer.shadowOffset = CGSizeMake(-10, 0);
			self.rightEdgeView.layer.shadowColor = [UIColor blackColor].CGColor;
			self.rightEdgeView.layer.shadowOpacity = 0.2;
			self.rightEdgeView.layer.shadowRadius = 10;
            self.rightEdgeView.layer.shouldRasterize = YES;
            self.rightEdgeView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            CGPathRef path = [UIBezierPath bezierPathWithRect:self.rightEdgeView.bounds].CGPath;
            self.rightEdgeView.layer.shadowPath = path;
		}

		//TODO: subcategoryBackgroundColor
		self.backgroundColor = [UIColor colorWithWhite: 0.9 alpha: 0.8];
        
		self.categoryTitleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 200, [[self class] ridgeWidth])];
		self.categoryTitleLabel.transform = CGAffineTransformMakeRotation(M_PI / 2);
		self.categoryTitleLabel.text = @"";
		self.categoryTitleLabel.font = [UIFont systemFontOfSize: 15];  // [UIFont fontWithName: @"AmericanTypewriter" size: 15];
		self.categoryTitleLabel.textColor = [UIColor lightGrayColor];
		[self.rightEdgeView addSubview: self.categoryTitleLabel];
		self.rightEdgeView.accessibilityLabel = self.categoryTitleLabel.text.length ? $S(@"Return to parent of %@", self.categoryTitleLabel.text) : @"Return to Parent Category";
        
        CGFloat adjustment = 30;
        
		self.categoryTitleLabel.center = CGPointMake(self.rightEdgeView.bounds.size.width / 2, (self.categoryTitleLabel.bounds.size.width / 2) + adjustment);

		self.categoryTitleLabel.backgroundColor = [UIColor clearColor];
		
		self.layer.shadowOffset = CGSizeMake(10, 0);
		self.layer.shadowColor = [UIColor blackColor].CGColor;
		self.layer.shadowOpacity = 0.2;
		self.layer.shadowRadius = 10;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        CGPathRef path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        self.layer.shadowPath = path;
        
		//	self.backgroundColor = [[@[ [UIColor redColor], [UIColor grayColor], [UIColor orange], [UIColor greenColor], [UIColor yellowColor], [UIColor purpleColor]] anyRandomObject] colorWithAlphaComponent: 0.8];
		//[self setupSubcategoryButtons];
	}
	return self;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor {
	self.rightEdgeView.backgroundColor = self.isRootPane ? [backgroundColor colorWithAlphaComponent: 1.0] : [UIColor clearColor];
	[super setBackgroundColor: backgroundColor];
}

- (BOOL) isRootPane { return NO; }
- (void) willReveal {
	self.backgroundColor = [self.backgroundColor colorWithAlphaComponent: 1.0];
	self.categoryTitleLabel.text = @"";
	self.rightEdgeView.isAccessibilityElement = NO;
}

- (void) willCollapse {
	self.backgroundColor = [self.backgroundColor colorWithAlphaComponent: 1.0];
	self.categoryTitleLabel.text = @"";
}

- (void) reveal: (id) sender {
	self.selectedCategory = nil;
	for (DSA_NLevelCategoryImageView *view in self.scrollView.subviews) {
		view.alpha = 1.0;
	}
	[self.nlevelNavigationController popToPane: self];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	if (self.scrollView.subviews.count == 0) [self setupSubcategoryButtons];
	[self bringSubviewToFront: self.rightEdgeView];
}

- (void) setupSubcategoryButtons {
    
    [DSA_NLevelCategoryImageView setDefaultImageHeight: 20];
        
    NSArray *categories     = self.categories;
    CGSize   defaultSize    = [DSA_NLevelCategoryImageView defaultSize];
    
	CGFloat				contentWidth = defaultSize.width;
    CGFloat				categoryHeight = 50 /*defaultSize.height*/, spacing = 15;
	CGFloat				viewHeight = self.bounds.size.height - 49;
	CGFloat				contentHeight = (categories.count * (categoryHeight + spacing) - spacing) + 40;
	CGFloat				yInset = (contentHeight > viewHeight) ? 20 : (viewHeight - contentHeight) / 2;
	
	if (self.scrollView == nil) {
		self.scrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 0, contentWidth, viewHeight)];
		self.scrollView.center = CGPointMake(self.contentCenter.x, viewHeight / 2);
		self.scrollView.showsHorizontalScrollIndicator = NO;
		self.scrollView.showsVerticalScrollIndicator = NO;
		self.scrollView.contentInset = UIEdgeInsetsMake(70, 0, 70, 0);
		self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview: self.scrollView];
	}
	self.scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
	self.scrollView.contentInset = UIEdgeInsetsMake(yInset, 0, yInset, 0);
	self.scrollView.scrollEnabled = (contentHeight > viewHeight);
	self.scrollView.accessibilityLabel = $S(@"Categories for %@", self.category.Name);
	
    CGRect	categoryBounds = CGRectMake(0, 0, contentWidth, categoryHeight);
    CGFloat offset = categoryHeight / 2;
	
	for (MMSF_Category__c *category in categories.copy) {
		DSA_NLevelCategoryImageView		*imageView = [DSA_NLevelCategoryImageView viewWithCategory: category inBounds: categoryBounds];
	
		imageView.center = CGPointMake(self.scrollView.bounds.size.width / 2, offset);
		offset += (categoryHeight + spacing);
		
		[self.scrollView addSubview: imageView];
		imageView.tag = [categories indexOfObject: category];
		//imageView.showsTouchWhenHighlighted = YES;
		[imageView addTarget: self action: @selector(categoryButtonTouched:) forControlEvents: UIControlEventTouchUpInside];
        if ([category hasAttachment]) {
            [imageView loadImageinQueue: s_imageQueue];
        }
	}
}

- (void) setCategory: (MMSF_Category__c *) category {
    MMSF_MobileAppConfig__c				*mac = [g_appDelegate selectedMobileAppConfig];
    MMSF_CategoryMobileConfig__c		*config = [mac configForCategory: category];
	
	if (config.subcategoryBackgroundColor)
		self.backgroundColor = [config.subcategoryBackgroundColor colorWithAlphaComponent: 0.8];
	else
		self.backgroundColor = [UIColor colorWithWhite: 0.9 alpha: 0.8];
	
	_category = category;
}

- (NSArray *) categories {
    
    NSArray *sortedSubCategories = self.category.sortedSubcategories;
    
#if CATEGORIES_ORDERED_ON
    
    NSSortDescriptor *orderSortDescriptor  = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Order__c")
                                                                           ascending:YES];
    NSSortDescriptor *specialSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:MNSS(@"Todays_Special__c")
                                                                            ascending:NO];
    
    sortedSubCategories = [[sortedSubCategories sortedArrayUsingDescriptors:[NSArray arrayWithObject:orderSortDescriptor]]
                           sortedArrayUsingDescriptors:[NSArray arrayWithObject:specialSortDescriptor]];
#endif
    
    return sortedSubCategories;
}

- (BOOL) expandCategory: (MMSF_Category__c *) category animated: (BOOL) animated {
	BOOL				hasContent = NO;
	
	self.selectedCategory = category;
	for (DSA_NLevelCategoryImageView *view in self.scrollView.subviews) {
		view.alpha = (view.category != category) ? 0.25 : 1.0;
	}

	if (1 || category.sortedContents.count) {
		[self.nlevelNavigationController.parentBrowser showContentsForCategory: category];
		hasContent = YES;
	}
	
	if (category.sortedSubcategories.count) {
		DSA_NLevelNavigationPane	*nextPane = [DSA_NLevelNavigationPane paneWithCategory: category];
		
		[self.nlevelNavigationController pushPane: nextPane animated: animated];
		self.categoryTitleLabel.text = category.Name;
		self.rightEdgeView.isAccessibilityElement = YES;
		self.rightEdgeView.accessibilityLabel = category.Name;
		hasContent = YES;
	}
	return hasContent;
}

- (void) categoryButtonTouched: (UIButton *) button {
	NSArray						*categories = self.categories;
	if (button.tag >= categories.count) return;
	
	MMSF_Category__c	*category = categories[button.tag];
	if (![self expandCategory: category animated: YES]) [self willReveal];
}


@end
