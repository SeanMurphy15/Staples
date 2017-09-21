//
//  MMSF_Cat_Content_Junction__c.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 11/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"
#import "MM_SOQLQueryString.h"


@class MMSF_Category__c, MMSF_ContentVersion;
@interface MMSF_Cat_Content_Junction__c : MMSF_Object

@property (nonatomic, readonly) MMSF_ContentVersion *contentVersion;

+ (void) processCategory:(MMSF_Category__c*) category categorySet:(NSMutableSet*) categorySet;

+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs;
@end
