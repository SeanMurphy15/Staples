//
//  SFRestAPI+ContinuedRequest.m
//  DSA
//
//  Created by Mike McKinley on 4/15/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "SFRestAPI+ContinuedRequest.h"
#import <objc/runtime.h>

@implementation SFRestAPI (ContinuedRequest)

- (void)runQuery:(NSString *)queryString toCompletion:(SFRestArrayResponseBlock)completion {
    self.completionBlock = completion;
    self.allRecords = [NSMutableArray arrayWithCapacity:0];
    
    SFRestFailBlock failBlock = ^(NSError *error) {
        MMLog(@"ContinuedRequest error: %@", error);
        if (self.completionBlock) {
            self.completionBlock(nil);
        }
    };
    
    __weak __block SFRestDictionaryResponseBlock weakContinueBlock;
    SFRestDictionaryResponseBlock continueBlock = ^(NSDictionary *responseInfo) {
        NSArray *records = responseInfo[@"records"];
        if (records && [records count]) {
            [self.allRecords addObjectsFromArray:records];
        }

        // continue?
        NSString *nextRecordsUrl = responseInfo[@"nextRecordsUrl"];
        if (nextRecordsUrl) {
            SFRestRequest *continuedRequest = [SFRestRequest requestWithMethod:SFRestMethodGET path:nextRecordsUrl queryParams:nil];
            SFRestDictionaryResponseBlock strongContinueBlock = weakContinueBlock;
            [self sendRESTRequest:continuedRequest failBlock:failBlock completeBlock:strongContinueBlock];
        } else {
            self.completionBlock(self.allRecords);
        }
    };
    
    weakContinueBlock = continueBlock;
    [self performSOQLQuery:queryString failBlock:failBlock completeBlock:continueBlock];
}

#pragma mark - Associated objects

- (NSMutableArray *)allRecords {
    return objc_getAssociatedObject(self, @selector(allRecords));
}

- (void)setAllRecords:(NSMutableArray *)allRecords {
    objc_setAssociatedObject(self, @selector(allRecords), allRecords, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SFRestArrayResponseBlock)completionBlock {
    return objc_getAssociatedObject(self, @selector(completionBlock));
}

- (void)setCompletionBlock:(SFRestArrayResponseBlock)completionBlock {
    objc_setAssociatedObject(self, @selector(completionBlock), completionBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
