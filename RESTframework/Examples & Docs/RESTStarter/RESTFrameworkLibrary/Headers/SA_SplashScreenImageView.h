//
//  SA_SplashScreenImageView.h
//
//  Created by Ben Gottlieb on 9/1/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SA_SplashScreenImageView : UIImageView {

}

+ (id) splashScreenViewInParent: (UIView *) parent;
- (void) fadeOutOverPeriod: (NSTimeInterval) period;

@end
