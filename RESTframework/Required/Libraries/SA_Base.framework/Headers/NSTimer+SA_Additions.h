//
//  NSTimer+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SA_Utilities.h"
#import "NSObject+SA_Additions.h"

@interface NSTimer (SA_SA_Additions)

+ (NSTimer *) scheduledTimerWithTimeInterval: (NSTimeInterval) ti block: (idArgumentBlock) block repeats: (BOOL) repeats;
@end
