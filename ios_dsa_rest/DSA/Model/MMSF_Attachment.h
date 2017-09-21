//
//  MMSF_Attachment.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_Object.h"

@class MM_SOQLQueryString;

@interface MMSF_Attachment : MMSF_Object

@property(nonatomic,copy) NSString *Body;
@property(nonatomic,strong) NSNumber *BodyLength;

@property(nonatomic,copy) NSString *documentsPath;

- (NSString *) filepath;

+ (MMSF_Attachment*) attachmentWithSalesforceId:(NSString*) salesforceId;
+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs;

@end
