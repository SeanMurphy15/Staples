//
//  ContactController.m
//  DSA
//
//  Created by Jason Barker on 4/24/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "ContactController.h"
#import "MMSF_Account.h"
#import "DSA_PicklistUtility.h"

@implementation ContactController

- (id) init {
	if (self = [super init]) {
		MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Contact" inContext: nil];
		NSArray							*required = [def requiredFieldsInLayout: nil];

		self.fields = [NSMutableDictionary dictionary];
		
		for (NSDictionary *field in required) {
			NSString			*value = [self defaultValueForField: field];
			
			if (value != nil) { self.fields[field[@"name"]] = value; }
		}
	}
	
	return self;
}



/**
 *
 */
- (void) saveContact {
    
    NSString                *fullName   = [self buildFullName];
    NSManagedObjectContext  *moc        = [MM_ContextManager sharedManager].threadContentContext;
    MMSF_Object             *contact    = [moc insertNewEntityWithName: @"Contact"];
	MM_SFObjectDefinition	*def		= [MM_SFObjectDefinition objectNamed: @"Contact" inContext: nil];
	
    [contact beginEditing];
	
	for (NSString *key in self.fields) {
		NSDictionary		*fieldInfo = [def infoForField: key];
		NSString			*type = fieldInfo[@"soapType"];
		
		if ([type isEqual: @"xsd:double"] || [type isEqual: @"xsd:int"]) {
			[contact setValue: @([self.fields[key] integerValue]) forKey: key];
		} else if ([type isEqual: @"xsd:boolean"]) {
			[contact setValue: @([self.fields[key] boolValue]) forKey: key];
		} else if ([self.fields[key] length] > 0) {
			[contact setValue: self.fields[key] forKey: key];
		}
	}
	
	[contact setValue: fullName forKey: @"Name"];
	[contact setValue: self.account forKey: @"AccountId"];
    [contact setValue: self.account.Name forKey: @"AccountName"];
    [contact finishEditingSavingChanges: YES];
    
    if (self.completionBlock)
        self.completionBlock(YES);
    
}


/**
 *
 */
- (NSString *) buildFullName {
    
    NSMutableString *name = [NSMutableString string];
    
    if ([self.fields[@"FirstName"] length] > 0)
        [name appendString: self.fields[@"FirstName"]];
    
    if ([self.fields[@"LastName"] length] > 0) {
        
        if (name.length > 0)
            [name appendString: @" "];
        
        [name appendString: self.fields[@"LastName"]];
    }
    
    return [NSString stringWithString: name];
}


#pragma mark - Field validation

- (NSString *) defaultValueForField: (NSDictionary *) info {
    NSArray *picklistOptions = [DSA_PicklistUtility activePicklistOptionsForField:info[@"name"] onObjectNamed:@"Contact"];

    for (NSDictionary *option in picklistOptions) {
        if ([option[@"defaultValue"] boolValue]) {
            return option[@"value"];
        }
    }

    return nil;
}

/**
 *
 */

- (BOOL) validateValue: (id) value forFieldName: (NSString *) name {
	if ([name isEqual: @"MailingPostalCode"] || [name isEqual: @"Zip_Postal_Code__c"] || [name isEqual: @"OtherPostalCode"]) return [self isStringValue: value ofMinimumLength: 5];
	
	return [self isStringValue: value ofMinimumLength: 1];
}

- (BOOL) validateFieldNamed: (NSString *) fieldName {
	return [self validateValue: self.fields[fieldName] forFieldName: fieldName];
}

/**
 *
 */
- (BOOL) isStringValue: (id) value ofMinimumLength: (NSInteger) length {
    
    BOOL flag = NO;
    
    if ([value isKindOfClass: [NSString class]]) {
        
        NSString    *string     = (NSString *) value;
        NSString    *trimmed    = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        
        if (trimmed.length >= length)
            flag = YES;
        
    }
    
    return flag;
}



@end
