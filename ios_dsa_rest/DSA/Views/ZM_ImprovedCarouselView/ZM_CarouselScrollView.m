//
//  ZM_CarouselScrollView.m
//
//  Created by Chris Cieslak on 5/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZM_CarouselScrollView.h"
#import "ZM_CarouselCategoryView.h"
//#import "ZM_Defines.h"

@implementation ZM_CarouselScrollView

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    MMLog(@"%@", @"touches ended");
    if (!self.dragging) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self];
        for (ZM_CarouselCategoryView *subview in self.subviews) {
            if ([subview isKindOfClass:[ZM_CarouselCategoryView class]]) {
                if (CGRectContainsPoint(subview.frame, location)) {
 //                   LOG(@"view category: %@", subview.category);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CarouselDidTouchSubcategory object:subview.category];
                    [self scrollRectToVisible:subview.frame animated:YES];
                }
            }
        }
            
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void) selectCategory:(MMSF_Category__c*) category
{
//    LOG(@"selectCategory=%@ svframe=%@ offset=%@",category.name,NSStringFromCGRect(self.frame),NSStringFromCGPoint(self.contentOffset));
    
    for (ZM_CarouselCategoryView *subview in self.subviews) {
        if ([subview isKindOfClass:[ZM_CarouselCategoryView class]]) 
        {
//            LOG(@"-- %@ r=%@",subview.category.name,NSStringFromCGRect(subview.frame));
            if (subview.category == category) 
            {
//                LOG(@"--match: set offset to %@",NSStringFromCGPoint(subview.frame.origin));
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_CarouselDidTouchSubcategory object:subview.category];
                [self setContentOffset:subview.frame.origin animated:NO];
//                break;
            }
        }
    }
    
}

@end
