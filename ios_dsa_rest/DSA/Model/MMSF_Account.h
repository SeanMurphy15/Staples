//
//  MMSF_Account.h
//  DSA
//
//  Created by Jason Barker on 4/23/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "MMSF_Object.h"



@class MMSF_Account;



@interface MMSF_Account : MMSF_Object

@property (nonatomic, strong) NSString *Name;
@property (nonatomic, strong) NSString *AccountNumber;
@property (nonatomic, strong) NSString *Id;

@end
