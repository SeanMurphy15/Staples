//
//  ContactController.h
//  DSA
//
//  Created by Jason Barker on 4/24/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void (^boolCompletionBlock)(BOOL value);

#define ContactFieldNames		@[ @"FirstName", @"LastName", @"Email", @"Phone", @"Salutation" ]


@class MMSF_Account;



@interface ContactController : NSObject


@property (nonatomic, strong) MMSF_Account *account;
@property (nonatomic, strong) NSMutableDictionary *fields;

//@property (nonatomic, strong) NSString *salutation;
//@property (nonatomic, strong) NSString *firstName;
//@property (nonatomic, strong) NSString *lastName;
//@property (nonatomic, strong) NSString *emailAddress;
//@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, copy) boolCompletionBlock completionBlock;

- (void) saveContact;
//- (BOOL) validateValue: (id) value forField: (NSString *) field;
- (BOOL) validateValue: (id) value forFieldName: (NSString *) name;
- (BOOL) validateFieldNamed: (NSString *) fieldName;
@end
