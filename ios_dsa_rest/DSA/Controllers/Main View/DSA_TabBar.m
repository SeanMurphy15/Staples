//
//  DSA_TabBar.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/27/13.
//
//

#import "DSA_TabBar.h"
#import "DSA_BaseTabsViewController.h"
#import "DSA_AppDelegate.h"

#define kLogoImage_Width    150
#define kLogoImage_Height   29

@interface DSA_TabBarButton : UIButton

@end

@interface DSA_TabBar ()
@property (nonatomic, strong) NSArray *tabs;
@property (nonatomic, strong) UIButton* rightSideButton;
@end

@implementation DSA_TabBar

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (Class) layerClass { return [CAGradientLayer class]; }

- (id) initWithFrame: (CGRect) frame {
	if (self = [super initWithFrame: frame]) {
		CAGradientLayer			*layer = (id) self.layer;
		UIColor					*clear = [UIColor colorWithWhite: 0.0 alpha: 0.15];
		UIColor					*black = [UIColor colorWithWhite: 0.0 alpha: 0.85];
		
		layer.colors = @[ (id) clear.CGColor, (id) black.CGColor, (id) black.CGColor, (id) clear.CGColor ];
		layer.startPoint = CGPointMake(1.0, 0.5);
		layer.endPoint = CGPointMake(0, 0.5);
        
        [self addAsObserverForName: kNotification_MobileAppConfigurtionChanged selector: @selector(setupLogo)];
        [self addAsObserverForName: kNotification_SyncComplete selector: @selector(setupLogo)];

		self.tabTintColor = [UIColor darkGrayColor];
		self.selectedTabTintColor = [UIColor whiteColor];
		self.tabWidth = 84;
        
        self.logo = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.logo.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.logo.contentMode = UIViewContentModeScaleAspectFit;
        self.logo.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void) setItems: (NSArray *) items {
	_items = items;
	
	[self setNeedsLayout];
}

- (void) setFrame:(CGRect)frame {
	[self setNeedsLayout];
	[super setFrame: frame];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	[self removeAllSubviews];
	
	if (self.tabWidth == 0) self.tabWidth = 84;
	CGFloat				tabLeft = (self.bounds.size.width - self.items.count * self.tabWidth) / 2;
	NSMutableArray		*tabs = [NSMutableArray array];
	
	for (UITabBarItem *item in self.items) {
		DSA_TabBarButton			*tabButton = [DSA_TabBarButton buttonWithType: UIButtonTypeCustom];
		UIImage						*highlightImage = [self maskFromImage: item.image withTintColor: self.selectedTabTintColor];
		
		[tabButton setImage: [self maskFromImage: item.image withTintColor: self.tabTintColor] forState: UIControlStateNormal];
		[tabButton setImage: highlightImage forState: UIControlStateHighlighted];
		[tabButton setImage: highlightImage forState: UIControlStateSelected];
		
		[tabButton setTitleColor: self.tabTintColor forState: UIControlStateNormal];
		[tabButton setTitleColor: self.selectedTabTintColor forState: UIControlStateHighlighted];
		[tabButton setTitleColor: self.selectedTabTintColor forState: UIControlStateSelected];
		
		tabButton.titleLabel.font = [UIFont boldSystemFontOfSize: 10];
		if (tabs.count == self.selectedTabIndex) [tabButton setSelected: YES];
		tabButton.titleLabel.textAlignment = NSTextAlignmentCenter;
		tabButton.imageView.contentMode = UIViewContentModeCenter;
		tabButton.frame = CGRectMake(tabLeft, 0, self.tabWidth, self.bounds.size.height);
		tabButton.tag = self.subviews.count;
		tabButton.showsTouchWhenHighlighted = YES;
		[tabButton addTarget: self action: @selector(tabTouched:) forControlEvents: UIControlEventTouchUpInside];
		[tabButton setTitle: item.title forState: UIControlStateNormal];
		[self addSubview: tabButton];
		tabLeft += self.tabWidth;
		[tabs addObject: tabButton];
	}
	self.tabs = tabs;
    
    [self setupLogo];
    [self addSubview:self.logo];
    
    if (self.rightSideButton != nil)
    {
        [self addSubview:self.rightSideButton];
    }
}

- (void)setupLogo {
    UIImage * img = [[g_appDelegate selectedMobileAppConfig] logoImage];
    if(img) {
        self.logo.image = img;
        self.logo.hidden = NO;
        
        CGFloat barHeight = self.bounds.size.height;
        CGFloat verticalPadding = (barHeight - kLogoImage_Height) / 2;
        self.logo.frame = CGRectMake(30, verticalPadding, kLogoImage_Width, kLogoImage_Height);
        self.logo.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.logo.hidden = YES;
    }
}

- (void) setSelectedTabIndex: (NSUInteger) selectedTabIndex {
	if (_selectedTabIndex < self.tabs.count) [self.tabs[_selectedTabIndex] setSelected: NO];

	_selectedTabIndex = selectedTabIndex;
	if (_selectedTabIndex < self.tabs.count) [self.tabs[_selectedTabIndex] setSelected: YES];
}

- (void) tabTouched: (DSA_TabBarButton *) button {
	self.tabBarController.selectedIndex = button.tag;
	self.selectedTabIndex = [self.tabs indexOfObject: button];
}

- (UIImage *) maskFromImage: (UIImage *) image withTintColor: (UIColor *) color {
	UIGraphicsBeginImageContext(image.size);
	
	CGContextRef				ctx = UIGraphicsGetCurrentContext();
	
	[image drawAtPoint: CGPointZero];
	CGContextSetBlendMode(ctx,  kCGBlendModeSourceAtop);
	CGContextBeginPath(ctx);
	CGContextAddRect(ctx, CGRectMake(0, 0, image.size.width, image.size.height));
	CGContextClosePath(ctx);
	CGContextSetFillColorWithColor(ctx, color.CGColor);
	CGContextFillPath(ctx);
	
	UIImage			*result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return result;
}

//add an arbitary button to the right side off the tab bar.  Why? Because a customer wants it there despite
//being told it goes against HIG and decent UI. They are paying the monies, so...
- (void) addRightSideButton:(UIButton*) button
{
    //Remove any existing button
    if (self.rightSideButton != nil)
    {
        [self.rightSideButton removeFromSuperview];
        self.rightSideButton = nil;
    }
    
    if (button != nil)
    {
        [self addSubview:button];
        self.rightSideButton = button;
        button.frame = CGRectMake((self.bounds.size.width - button.bounds.size.width)-10,
                                  (self.bounds.size.height - button.bounds.size.height)/2.0 ,
                                  button.bounds.size.width, button.bounds.size.height);
    }
}
@end

@implementation DSA_TabBarButton

- (CGRect) imageRectForContentRect: (CGRect) bounds {
	bounds.size.height -= 12;
	bounds.origin.x = CGRectGetMidX(bounds) - bounds.size.height / 2;
	bounds.size.width = bounds.size.height;
	return CGRectInset(bounds, 4, 4);
}

- (CGRect) titleRectForContentRect: (CGRect) bounds {
	bounds.origin.y += (bounds.size.height - 12);
	bounds.size.height = 12;
	return bounds;
}

@end
