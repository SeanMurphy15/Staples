//
//  DSA_NLevelNavigationRootViewController.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/27/13.
//
//

#import <UIKit/UIKit.h>

@class MM_FlexibleVisualBrowser, MMSF_Category__c;

#define kNotification_NLevelNavigationWillShow			@"kNotification_NLevelNavigationWillShow"
#define kNotification_NLevelNavigationDidHide			@"kNotification_NLevelNavigationDidHide"


@class DSA_NLevelNavigationPane;

@interface DSA_NLevelNavigationController : UIViewController

+ (id) animateNavigationIntoViewController: (MM_FlexibleVisualBrowser *) parent withInitiallySelectedCategory: (MMSF_Category__c *) category;

@property (nonatomic, strong) UIView *blockerView;
@property (nonatomic, weak) MM_FlexibleVisualBrowser *parentBrowser;
@property (nonatomic, strong) NSMutableArray *collapsedPanes, *visiblePanes;

- (void) pushPane: (DSA_NLevelNavigationPane *) pane animated: (BOOL) animated;
- (void) popToPane: (DSA_NLevelNavigationPane *) pane;
@end
