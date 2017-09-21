//
//  NSUserDefaults+SA_Additions.h
//
//  Created by Ben Gottlieb on 11/24/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (SA_Additions)

+ (void) setCurrentDefaultsGroup: (NSString *) group;
+ (NSUserDefaults *) standardGroupDefaults;
+ (NSString *) currentDefaultsGroup;

- (BOOL) isSetting: (NSString *) settingKey upToVersion: (int) properVersion updatingIfNeeded: (BOOL) update;

+ (void) syncObject: (id) object forKey: (NSString *) key;

- (id) objectForKeyedSubscript: (id) key;
- (void) setObject: (id) obj forKeyedSubscript: (id) key;
@end
