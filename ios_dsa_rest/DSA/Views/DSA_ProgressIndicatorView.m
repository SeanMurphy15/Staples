//
//  DSA_ProgressIndicatorView.m
//  ios_dsa
//
//  Created by Steve Deren on 8/20/13.
//
//

#import "DSA_ProgressIndicatorView.h"

@implementation DSA_ProgressIndicatorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.labStatus = [[UILabel alloc] initWithFrame:CGRectZero];
        self.labStatus.font = [UIFont fontWithName:@"Helvetica" size:15];
        self.labStatus.backgroundColor = [UIColor clearColor];
        self.labStatus.textColor = [UIColor whiteColor];
        self.labStatus.textAlignment = NSTextAlignmentCenter;
        self.labStatus.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.labStatus.numberOfLines = 2;
        [self addSubview:self.labStatus];
        
        self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.progressBar.progressTintColor = [UIColor whiteColor];
        self.progressBar.trackTintColor = [UIColor darkGrayColor];
        self.progressBar.progress = 0;
        [self addSubview:self.progressBar];
    }
    return self;
}

- (void)layoutSubviews {
    self.labStatus.frame = CGRectMake(0, 0, self.bounds.size.width, 45);
    self.progressBar.frame = CGRectMake(0, self.bounds.size.height - 35, self.bounds.size.width, 35);
}

@end
