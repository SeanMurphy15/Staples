//
//  MMSF_Contact.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"
#import "MMSF_User.h"

@class MMSF_User;
@interface MMSF_Contact : MMSF_Object


@property(nonatomic, strong) NSDate *LastModifiedDate;
@property(nonatomic, strong) NSString *Name;
@property(nonatomic, strong) NSString *FirstName;
@property(nonatomic, strong) NSString *LastName;
@property(nonatomic, strong) NSString *Email;
@property(nonatomic, strong) MMSF_Object *AccountId;
@property(nonatomic,strong) MMSF_User *OwnerId;
@property(nonatomic, strong) NSString *Phone;


+ (NSInteger) countOfContactsWithEmail;


@end
