//
//  UILabel+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (SA_textAdditions)
- (CGSize) sizeOfCurrentTextInExistingWidth;
- (void) autosizeForExistingWidth: (float) width;
- (void) autosizeForExistingSize;
@end