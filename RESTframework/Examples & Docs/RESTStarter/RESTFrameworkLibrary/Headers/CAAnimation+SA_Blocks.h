//
//  CAAnimation+SA_Blocks.h
//
//  Created by Ben Gottlieb on 9/9/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^animationDidStopBlock)(CAAnimation *anim, BOOL finished);
typedef void (^animationDidStartBlock)(CAAnimation *anim);


@interface CAAnimation (SA_Blocks)

@property (nonatomic, copy) animationDidStartBlock SA_animationDidStartBlock;
@property (nonatomic, copy) animationDidStopBlock SA_animationDidStopBlock;


@end
