//
//  SFRestAPI+ContinuedRequest.h
//  DSA
//
//  Created by Mike McKinley on 4/15/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <SalesforceNativeSDK/SFRestAPI+Blocks.h>


@interface SFRestAPI (ContinuedRequest)

@property (nonatomic, strong) NSMutableArray *allRecords;
@property (nonatomic, strong) SFRestArrayResponseBlock completionBlock;

- (void)runQuery:(NSString *)queryString toCompletion:(SFRestArrayResponseBlock)completion;

@end
