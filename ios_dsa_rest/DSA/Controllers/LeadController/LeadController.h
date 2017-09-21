//
//  LeadController.h
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void (^boolCompletionBlock)(BOOL value);

typedef NS_ENUM(NSInteger, LeadField) {
    LeadFieldStatus,
    LeadFieldProspectingWeek,
    LeadFieldCompanyName,
    LeadFieldEmployeeCount,
    LeadFieldStreetAddress,
    LeadFieldCity,
    LeadFieldState,
    LeadFieldZipCode,
    LeadFieldSalutation,
    LeadFieldFirstName,
    LeadFieldLastName,
    LeadFieldEmailAddress,
    LeadFieldPhoneNumber,
    LeadFieldTitleGrouping,
	
	LeadFieldNone = 1000
};

#define LeadFieldNames		@[ @"Status", @"Prospecting_Week__c", @"Company", @"NumberOfEmployees", @"Street", @"City", @"State", @"PostalCode", @"Salutation", @"FirstName", @"LastName", @"Email", @"Phone", @"Lead_Contact_s_Title_Grouping__c" ]


@interface LeadController : NSObject
@property (nonatomic, strong) NSMutableDictionary *fields;
@property (nonatomic, copy) boolCompletionBlock completionBlock;


- (void) saveLead;
- (void) toggleOfficeSupplier: (NSString *) supplierName;
- (BOOL) validateValue: (id) value forFieldName: (NSString *) field;

- (NSString *) defaultValueForField: (NSString *) field;
//- (NSString *) valueForField: (NSString *) field;
- (BOOL) validateFieldNamed: (NSString *) fieldName;
@end
