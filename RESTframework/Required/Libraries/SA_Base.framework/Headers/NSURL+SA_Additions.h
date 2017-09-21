//
//  NSURL+SA_Additions.h
//
//  Created by Ben Gottlieb on 12/26/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (NSURL_SA_Additions)

- (NSDictionary *) keyValuedParameters;
+ (NSURL *) URLWithFormat: (NSString *) format, ...;

@end
