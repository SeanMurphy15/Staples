//
//  ZM_CarouselScrollView.h
//
//  Created by Chris Cieslak on 5/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_Category__c.h"

@interface ZM_CarouselScrollView : UIScrollView {
    
}

- (void) selectCategory:(MMSF_Category__c*) category;

@end
