//
//  DSA_PicklistUtility.h
//  DSA
//
//  Created by Adam Walters on 7/13/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSA_PicklistUtility : NSObject

+ (NSArray *)activePicklistOptionsForField: (NSString *)fieldName onObjectNamed: (NSString *)objectName;

@end
