//
//  DSA_ProgressView.h
//  ios_dsa
//
//  Created by Steve Deren on 8/19/13.
//
//

#import <UIKit/UIKit.h>
#import "DSA_ProgressIndicatorView.h"

typedef void (^voidBlock)(void);

@interface DSA_ProgressView : UIView

@property (nonatomic,strong) UILabel * labTitle;

@property (nonatomic,strong) DSA_ProgressIndicatorView * detailProgressViewContainer;
@property (nonatomic,strong) DSA_ProgressIndicatorView * mainProgressViewContainer;
@property (nonatomic,strong) UIButton * cancelButton;
@property (nonatomic,copy) voidBlock cancelBlock;

+ (id)showWithTitle:(NSString*)title;

+ (id)showWithTitle:(NSString*)title
          overallText:(NSString*)overallText
           detailText:(NSString*)detailText
      overallProgress:(float)overallProg
       detailProgress:(float)detailProg;

+ (void)hide;
+ (void) showNow;

+ (void)setCancelButtonImage:(NSString*)cancelImgName withPressedImage:(NSString*)pressedImgName;
@end
