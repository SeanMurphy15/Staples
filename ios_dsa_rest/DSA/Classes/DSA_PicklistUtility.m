//
//  DSA_PicklistUtility.m
//  DSA
//
//  Created by Adam Walters on 7/13/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "DSA_PicklistUtility.h"

@implementation DSA_PicklistUtility

+ (NSArray *)activePicklistOptionsForField: (NSString *)fieldName onObjectNamed: (NSString *)objectName {
    MM_SFObjectDefinition *def = [MM_SFObjectDefinition objectNamed: objectName inContext: nil];
    NSString *recordTypeId = [def defaultRecordType];

    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    NSPredicate* fetchPredicate = [NSPredicate predicateWithFormat: @"Id = %@", recordTypeId];
    MMSF_Object *recordType = [moc firstObjectOfType:@"RecordType" matchingPredicate:fetchPredicate sortedBy:nil];

    NSArray *picklistOptions = [def picklistOptionsForField:fieldName basedOffRecordType:recordType];

    return picklistOptions;
}

@end
