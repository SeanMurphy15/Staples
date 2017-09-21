//
//  NSSortDescriptor+SA_Additions.h
//
//  Created by Ben Gottlieb on 1/28/10.
//  Copyright 2010 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSSortDescriptor (ConvenienceAdditions)

+ (NSSortDescriptor *) SA_descWithKey: (NSString *) key ascending: (BOOL) ascending;
+ (NSSortDescriptor *) SA_descWithKey: (NSString *) key ascending: (BOOL) ascending selector: (SEL) selector;


+ (NSArray *) SA_arrayWithDescWithKey: (NSString *) key ascending: (BOOL) ascending;
@end
