//
//  SA_BlockButton.h
//  SABase
//
//  Created by Ben Gottlieb on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SA_BlockButton : UIButton

- (void) addBlock: (simpleBlock) block forControlEvent: (UIControlEvents) event;

@end
