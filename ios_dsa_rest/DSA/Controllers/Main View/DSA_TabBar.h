//
//  DSA_TabBar.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 7/27/13.
//
//

#import <UIKit/UIKit.h>

@class DSA_BaseTabsViewController;

@interface DSA_TabBar : UIView

@property (nonatomic, strong) NSArray *items;
@property (nonatomic) CGFloat tabWidth;
@property (nonatomic, weak) DSA_BaseTabsViewController *tabBarController;
@property (nonatomic, strong) UIColor *tabTintColor, *selectedTabTintColor;
@property (nonatomic) NSUInteger selectedTabIndex;
@property (nonatomic, strong) UIImageView * logo;

- (void) addRightSideButton:(UIButton*) button;  //set nil to clear
@end
