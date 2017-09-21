//
//  NSBundle+SA_Additions.h
//
//  Created by Ben Gottlieb on 7/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSBundle (SAAdditions)

+ (NSDictionary *) info;
+ (id) infoDictionaryObjectForKey: (NSString *) key;
+ (NSString *) version;
+ (NSString *) identifier;
+ (NSString *) visibleName;

- (NSBundle *) bundleNamed: (NSString *) bundleName;
@end
