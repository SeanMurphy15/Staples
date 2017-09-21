//
//  DSA_NLevelNavigationRootViewController.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/27/13.
//
//

#import "DSA_NLevelNavigationController.h"
#import "MMSF_User.h"
#import "MM_FlexibleVisualBrowser.h"
#import "DSA_NLevelNavigationRootView.h"
#import "DSA_AppDelegate.h"
#import "DSA_BaseTabsViewController.h"
#import "DSA_TabBar.h"

@interface DSA_NLevelNavigationController ()
@end

@implementation DSA_NLevelNavigationController

- (void) dealloc {
}

+ (id) animateNavigationIntoViewController: (MM_FlexibleVisualBrowser *) parent withInitiallySelectedCategory: (MMSF_Category__c *) category {
	DSA_NLevelNavigationController			*controller = [[self alloc] init];
//	MMSF_ModelM__MobileAppConfig__c					*mac = [[MM_SyncManager currentUserInContext: nil] currentConfig];
	
	controller.view = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 0, parent.view.bounds.size.height)];
	controller.view.backgroundColor = [UIColor clearColor];
	controller.blockerView = [parent.view blockingViewWithTappedBlock: ^(UIView *v) {
		[controller dismissAnimated: YES];
	}];
    controller.blockerView.alpha = 0.5;
	controller.blockerView.backgroundColor = [UIColor clearColor];
	controller.parentBrowser = parent;
	 //	controller.view.backgroundColor = [[mac titleBarColor] colorWithAlphaComponent: 0.7];
	
	controller.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
	[parent.view addSubview: controller.view];
	[parent addChildViewController: controller];

	DSA_NLevelNavigationPane		*rootPane =  [[DSA_NLevelNavigationRootView alloc] initWithFrame: controller.nextPaneFrame];
	//controller.collapsedPanes = @[ rootPane ].mutableCopy;
	
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_NLevelNavigationWillShow object: nil];
	[controller pushPane: rootPane animated: NO];
	if (category) [rootPane expandCategory: category animated: NO];
	//[UIView animateWithDuration: 0.2 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations: ^{
	//	controller.blockerView.alpha = 0.45;
	//} completion: ^(BOOL completed) {
	//}];

	parent.currentSubCategory = nil;
//	parent.currentCategoryConfig = nil;

	return controller;
}

- (UIButton*) homeButton
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];

    [button setBackgroundImage:[UIImage imageNamed:@"HomeButton"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(dismissAnimated:) forControlEvents:UIControlEventTouchUpInside];
    button.tintColor = [UIColor yellowColor];
    button.frame = CGRectMake(0, 0, 40, 40);
    return button;
}


- (void) viewWillAppear:(BOOL)animated
{
    [g_appDelegate.baseViewController.tabBar addRightSideButton:[self homeButton]];
}

- (void) viewDidDisappear:(BOOL)animated
{
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [g_appDelegate.baseViewController.tabBar addRightSideButton:nil]; 
}

- (void) dismissAnimated: (BOOL) animated {
	if (!animated) {
		[self.parentBrowser showContentsForCategory: nil];
		[self.parentBrowser showButtonsWithDelay: 0.0];
		[self.blockerView removeFromSuperview];
		[self removeFromParentViewController];
		[self.view removeFromSuperview];
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_NLevelNavigationDidHide object: nil];
	} else {
		[self.parentBrowser showContentsForCategory: nil];

		[UIView animateWithDuration: 0.0 delay: 0 options: UIViewAnimationOptionCurveEaseIn animations: ^{
			[self.parentBrowser showButtonsWithDelay: 0.0];
			self.blockerView.alpha = 0.0;
			self.view.center = CGPointMake(-self.view.bounds.size.width / 2, self.view.center.y);
			[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_NLevelNavigationDidHide object: nil];
		} completion:^(BOOL finished) {
			[self dismissAnimated: NO];
		}];
	}
}

//=============================================================================================================================
#pragma mark Panes
- (void) pushPane: (DSA_NLevelNavigationPane *) pane animated: (BOOL) animated {
	CGFloat			width = (self.collapsedPanes.count ? ((self.collapsedPanes.count - 1) * PANE_RIDGE_WIDTH) : 0) + ROOT_PANE_RIDGE_WIDTH;
	
	width += self.collapsedPanes.count ? (PANE_CONTENT_WIDTH + PANE_RIDGE_WIDTH) : ROOT_PANE_CONTENT_WIDTH;
	pane.nlevelNavigationController = self;
	[pane willReveal];
	if (self.visiblePanes == nil) self.visiblePanes = [NSMutableArray array];
	[self.visiblePanes addObject: pane];
	pane.frame = CGRectMake(-pane.bounds.size.width, 0, pane.bounds.size.width, self.view.bounds.size.height);
	self.view.frame = CGRectMake(0, 0, width, self.view.superview.bounds.size.height);
	[self.view insertSubview: pane atIndex: 0];
	[UIView animateWithDuration: animated ? 0.2 : 0.0 delay: 0.0 options: UIViewAnimationOptionCurveEaseOut animations: ^{
		if (self.visiblePanes.count > 1 || (self.visiblePanes.count > 1 && ![self.visiblePanes[0] isRootPane])) {
		//	if ([self.visiblePanes[0] isRootPane]) [self collapseBottomPane];
			[self collapseBottomPane];
		} else
			pane.center = CGPointMake(self.view.bounds.size.width - pane.bounds.size.width / 2, pane.bounds.size.height / 2);
		
	} completion: ^(BOOL completed) {
	}];
	
}

- (void) collapseBottomPane {
	DSA_NLevelNavigationPane				*collapsee = self.visiblePanes[0];
	
	[collapsee willCollapse];
	if (self.collapsedPanes == nil) self.collapsedPanes = [NSMutableArray array];
	
	[self.collapsedPanes addObject: collapsee];
	[self.visiblePanes removeObject: collapsee];
	
	CGFloat				rightEdge = (self.collapsedPanes.count * PANE_RIDGE_WIDTH) + ROOT_PANE_RIDGE_WIDTH - PANE_RIDGE_WIDTH;
	if ([collapsee isKindOfClass: [DSA_NLevelNavigationRootView class]])
		collapsee.frame = CGRectMake(rightEdge - (ROOT_PANE_RIDGE_WIDTH + ROOT_PANE_CONTENT_WIDTH), 0, ROOT_PANE_RIDGE_WIDTH + ROOT_PANE_CONTENT_WIDTH, self.view.bounds.size.height);
	else
		collapsee.frame = CGRectMake(rightEdge - (PANE_RIDGE_WIDTH + PANE_CONTENT_WIDTH), 0, PANE_RIDGE_WIDTH + PANE_CONTENT_WIDTH, self.view.bounds.size.height);
	
	for (DSA_NLevelNavigationPane *pane in self.visiblePanes) {
		pane.frame = CGRectMake(rightEdge, 0, PANE_RIDGE_WIDTH + PANE_CONTENT_WIDTH, self.view.bounds.size.height);
		rightEdge += pane.frame.size.width;
	}

}

- (void) popToPane: (DSA_NLevelNavigationPane *) pane {
	NSUInteger			index = [self.visiblePanes indexOfObject: pane];
	NSMutableArray		*panesToRemove = [NSMutableArray array];
	NSArray				*visible = self.visiblePanes.copy, *collapsed = self.collapsedPanes.copy;
    
    [self.parentBrowser showContentsForCategory:pane.category];
	
	if (index == NSNotFound) index = -1;
	[UIView animateWithDuration: 0.2 animations:^{
		for (NSUInteger i = index + 1; i < visible.count; i++) {
			DSA_NLevelNavigationPane	*removee = visible[i];
			
			[panesToRemove addObject: removee];
			[self.visiblePanes removeObject: removee];
			removee.center = CGPointMake(-removee.bounds.size.width / 2, removee.bounds.size.height / 2);
		}
		
		NSUInteger		collapsedIndex = [collapsed indexOfObject: pane];
		
		if (collapsedIndex == NSNotFound) return;
		for (NSUInteger i = collapsedIndex; i < collapsed.count; i++) {
			DSA_NLevelNavigationPane	*removee = collapsed[i];
			
			[self.collapsedPanes removeObject: removee];
			[panesToRemove addObject: removee];
			removee.center = CGPointMake(-removee.bounds.size.width / 2, removee.bounds.size.height / 2);
		}
		if (![self.visiblePanes containsObject: pane]) [self pushPane: pane animated: YES];
	} completion: ^(BOOL finished) {
        
		for (DSA_NLevelNavigationPane *removee in panesToRemove) {
			if (pane == removee) continue;
			[removee removeFromSuperview];
		}
	}];
	
}

- (CGRect) nextPaneFrame {
	if (self.collapsedPanes.count + self.visiblePanes.count == 0) {
		return CGRectMake(0, 0, ROOT_PANE_RIDGE_WIDTH + ROOT_PANE_CONTENT_WIDTH, self.view.bounds.size.height);
	}
	return CGRectMake(0, 0, PANE_RIDGE_WIDTH + PANE_CONTENT_WIDTH, self.view.bounds.size.height);
}

@end



