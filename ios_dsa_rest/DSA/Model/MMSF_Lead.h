//
//  MMSF_Lead.h
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "MMSF_Object.h"



@class MMSF_User;



@interface MMSF_Lead : MMSF_Object

@property (nonatomic, strong) NSDate    *LastModifiedDate;
@property (nonatomic, strong) NSString  *Company;
@property (nonatomic, strong) NSString  *FirstName;
@property (nonatomic, strong) NSString  *LastName;
@property (nonatomic, strong) NSString  *Status;
@property (nonatomic, strong) NSString  *Email;
@property (nonatomic, strong) MMSF_User *OwnerId;

@end
