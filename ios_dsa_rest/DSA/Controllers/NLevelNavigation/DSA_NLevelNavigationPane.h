//
//  DSA_NLevelNavigatoinPane.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/29/13.
//
//

#import <UIKit/UIKit.h>

@class DSA_NLevelNavigationController, MMSF_Category__c;

#define PANE_RIDGE_WIDTH				30
#define PANE_CONTENT_WIDTH				150

#define ROOT_PANE_RIDGE_WIDTH			30
#define ROOT_PANE_CONTENT_WIDTH			170


@interface DSA_NLevelNavigationPane : UIView

+ (id) paneWithCategory: (MMSF_Category__c *) category;

@property (nonatomic, strong) UIView *rightEdgeView;
@property (nonatomic, weak) DSA_NLevelNavigationController *nlevelNavigationController;
@property (nonatomic, strong) MMSF_Category__c *category, *selectedCategory;
@property (nonatomic, readonly) BOOL isRootPane;
@property (nonatomic, strong) NSMutableArray *categoryButtons;
@property (nonatomic, strong) UILabel *categoryTitleLabel;
@property (nonatomic, strong) UIScrollView *scrollView;


+ (CGFloat) contentWidth;
+ (CGFloat) ridgeWidth;

- (void) willReveal;
- (void) willCollapse;
- (BOOL) expandCategory: (MMSF_Category__c *) category animated: (BOOL) animated;
- (void) categoryButtonTouched: (UIButton *) button;

@end
