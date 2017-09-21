//
//  LeadController.m
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "LeadController.h"
#import "MMSF_User.h"
#import "MM_SFObjectDefinition.h"



@interface LeadController () {
    
    NSMutableArray *_officeSuppliers;
}

@end



@implementation LeadController

- (BOOL) validateFieldNamed: (NSString *) fieldName {
	return [self validateValue: self.fields[fieldName] forFieldName: fieldName];
}

/**
 *
 */
- (id) init {
    if (self = [super init]) {
        _officeSuppliers = [[NSMutableArray alloc] init];
		
		MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
		NSArray							*required = [def requiredFieldsInLayout: nil];
		
		self.fields = [NSMutableDictionary dictionary];
		
		for (NSDictionary *field in required) {
			NSString			*value = [self defaultValueForField: field[@"name"]];
			
			if (value != nil) { self.fields[field[@"name"]] = value; }
		}
    }
    
    return self;
}


#pragma mark - Getters and setters

/**
 *
 */
- (void) saveLead {
    
    NSString                *fullName           = [self buildFullName];
    NSManagedObjectContext  *moc                = [MM_ContextManager sharedManager].threadContentContext;
    MMSF_Object             *lead               = [moc insertNewEntityWithName: @"Lead"];
	MM_SFObjectDefinition	*def				= [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
	
    [lead beginEditing];
	
	for (NSString *key in self.fields) {
		NSDictionary		*fieldInfo = [def infoForField: key];
		NSString			*type = fieldInfo[@"soapType"];
		
		if ([type isEqual: @"xsd:double"] || [type isEqual: @"xsd:int"]) {
			[lead setValue: @([self.fields[key] integerValue]) forKey: key];
		} else if ([type isEqual: @"xsd:boolean"]) {
			[lead setValue: @([self.fields[key] boolValue]) forKey: key];
		} else if ([self.fields[key] length] > 0) {
			[lead setValue: self.fields[key] forKey: key];
		}
	}

	if (fullName.length > 0) [lead setValue: fullName forKey: @"Name"];
	
    [lead setValue: [MMSF_User currentUser].Id forKey: @"OwnerId"];
    [lead setValue: @"Entered on DSA" forKey: @"LeadSource"];
//    [lead setValue: @"" forKey: @"RecordType"];
    [lead finishEditingSavingChanges: YES];
    
    if (self.completionBlock)
        self.completionBlock(YES);
    
}


/**
 *
 */
- (void) toggleOfficeSupplier: (NSString *) supplierName {
    
    if ([_officeSuppliers containsObject: supplierName])
        [_officeSuppliers removeObject: supplierName];
    else
        [_officeSuppliers addObject: supplierName];
    
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


/**
 *
 */

- (NSString *) defaultValueForField: (NSString *) fieldName {
	MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
	NSDictionary					*info = [def infoForField: fieldName];
	NSArray							*picklistValues = info[@"picklistValues"];
	
	for (NSDictionary *item in picklistValues) {
		if ([item[@"defaultValue"] integerValue] == 1) {
			return item[@"value"];
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


/**
 *
 */
- (BOOL) isIntegerValue: (id) value {
    
    BOOL flag = NO;
    
    if ([value isKindOfClass: [NSString class]]) {
        
        NSString    *string     = (NSString *) value;
        NSString    *trimmed    = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        
        if (trimmed.length > 0) {
            
            NSString *number = [NSString stringWithFormat: @"%d", trimmed.integerValue];
            flag = ([number isEqualToString: trimmed]);
        }
    }
    
    return flag;
}


@end
