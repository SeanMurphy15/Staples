//
//  DSA_ObjectUpdatedStatusView.m
//  ios_dsa
//
//  Created by Cory Wiles on 8/22/13.
//
//

#import "DSA_ObjectUpdatedStatusView.h"

CGFloat const STATUSVIEWHEIGHT = 100.0f;

@interface DSA_ObjectUpdatedStatusView()

@end

@implementation DSA_ObjectUpdatedStatusView

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];
    
    if (self) {

        self.backgroundColor = [UIColor blackColor];
        self.alpha           = 0.0f;
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;

        _messageLabel.text            = NSLocalizedString(@"Updated Content is available. Please re-sync", nil);
        _messageLabel.textColor       = [UIColor whiteColor];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.textAlignment   = NSTextAlignmentCenter;
        
        [self addSubview:_messageLabel];
    }
    
    return self;
}

- (void)layoutSubviews {

    [super layoutSubviews];
    
    CGRect messageLabelFrame = self.bounds;
    
    self.messageLabel.frame = messageLabelFrame;
}


@end
