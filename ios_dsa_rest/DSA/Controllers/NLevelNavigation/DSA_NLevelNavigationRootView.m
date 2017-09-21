//
//  DSA_NLevelNavigationRootView.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/29/13.
//
//

#import "DSA_NLevelNavigationRootView.h"
#import "MMSF_User.h"
#import "DSA_NLevelNavigationController.h"

@implementation DSA_NLevelNavigationRootView

- (void) dealloc {
}

+ (CGFloat) contentWidth { return ROOT_PANE_CONTENT_WIDTH; }
+ (CGFloat) ridgeWidth { return ROOT_PANE_RIDGE_WIDTH; }


- (void) setupSubcategoryButtons {
	NSArray					*categories = [[MM_SyncManager currentUserInContext: nil] topLevelCategoriesForCurrentConfig];
	CGFloat					buttonHeight = 50;
	CGFloat					allButtonsHeight = categories.count * buttonHeight;
	CGFloat					buttonsTop = (self.bounds.size.height - allButtonsHeight) / 2;
	
	for (UIButton *button in self.categoryButtons) [button removeFromSuperview];
	for (UIButton *button in self.ridgeButtons) [button removeFromSuperview];
	self.categoryButtons = [NSMutableArray array];
	self.ridgeButtons = [NSMutableArray array];
	
	for (MMSF_Category__c *category in categories.copy) {
		UIButton			*button = [UIButton buttonWithType: UIButtonTypeCustom];
		button.backgroundColor = [self.backgroundColor colorWithAlphaComponent: 0.95];
		button.frame = CGRectMake(0, buttonsTop, self.bounds.size.width, buttonHeight - 1);
		button.titleLabel.font = [UIFont systemFontOfSize: 15];  // [UIFont fontWithName: @"AmericanTypewriter" size: 15];
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
		[button setTitleColor: [UIColor grayColor] forState: UIControlStateNormal];
		[button setTitleColor: [UIColor blackColor] forState: UIControlStateHighlighted];
		[button addTarget: self action: @selector(categoryButtonTouched:) forControlEvents: UIControlEventTouchUpInside];
		button.tag = [categories indexOfObject: category];
		button.accessibilityLabel = $S(@"Menu for %@", category.Name);
		[button setTitle: category.Name forState: UIControlStateNormal];
		[self addSubview: button];
		[self.categoryButtons addObject: button];
		
		button = [UIButton buttonWithType: UIButtonTypeCustom];
		button.titleLabel.font = [UIFont fontWithName: @"Futura-CondensedMedium" size: 14];
		[button setTitle: @">" forState: UIControlStateNormal];
		button.backgroundColor = [UIColor colorWithWhite: 0.8 alpha: 1.0];
		[button setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
		[button setTitleColor: [UIColor whiteColor] forState: UIControlStateHighlighted];
//		[button addTarget: self action: @selector(categoryButtonTouched:) forControlEvents: UIControlEventTouchUpInside];
//		button.tag = [categories indexOfObject: category];
		button.accessibilityLabel = $S(@"Menu Button for %@", category.Name);
		button.frame = CGRectMake(0, buttonsTop, self.rightEdgeView.bounds.size.width, buttonHeight - 1);
		button.userInteractionEnabled = NO;
		
		if (self.selectedCategory == category) {
			button.backgroundColor = [UIColor blackColor];
			[button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
		}
		[self.rightEdgeView addSubview: button];
		[self.ridgeButtons addObject: button];
		
		buttonsTop += buttonHeight;
	}
}
- (void) willReveal {
	[super willReveal];
	for (UIButton *button in self.ridgeButtons) {
		button.backgroundColor = [UIColor colorWithWhite: 0.8 alpha: 1.0];
		[button setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
		[button setTitleColor: [UIColor whiteColor] forState: UIControlStateHighlighted];
	}
}

- (BOOL) isRootPane { return YES; }
- (NSArray *) categories { return [[MM_SyncManager currentUserInContext: nil] topLevelCategoriesForCurrentConfig]; }

- (BOOL) expandCategory: (MMSF_Category__c *) category animated: (BOOL) animated {
	NSUInteger			index = [self.categories indexOfObject: category];
	
	[self willReveal];
	if (index < self.ridgeButtons.count) {
		UIButton			*ridgeButton = self.ridgeButtons[index];
		
		ridgeButton.backgroundColor = [UIColor blackColor];
		[ridgeButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
	}
	return [super expandCategory: category animated: animated];
}

@end