//
//  MM_SFObjectDefinition+SOAP_DescribeLayout.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 5/6/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "MM_SFObjectDefinition.h"

@interface MM_SFObjectDefinition (SOAP_DescribeLayout)

- (NSDictionary *) describeLayout;
- (void) refreshDescribeLayout;

+ (void) setupSOAPURL;
+ (void) setupSOAPURLWithCompletionBlock: (simpleBlock) block;
- (void) checkForDeletedRecordsSince: (NSDate *) date;
@end
