//
//  SA_SelfDrawingView.h
//
//  Created by Ben Gottlieb on 3/11/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSObject+SA_Additions.h"

@class SA_SelfDrawingView;

#if NS_BLOCKS_AVAILABLE
typedef void (^simpleDrawingBlock)(SA_SelfDrawingView *view, CGRect rect);
#endif

@interface SA_SelfDrawingView : UIView {

}


#if NS_BLOCKS_AVAILABLE
@property (nonatomic, readwrite, copy) simpleDrawingBlock drawBlock;
#endif


@end
