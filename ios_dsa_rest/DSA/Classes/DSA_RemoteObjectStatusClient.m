//
//  DSA_RemoteObjectStatusManager.m
//  ios_dsa
//
//  Created by Cory Wiles on 8/22/13.
//
//

NSString * const SFDCCheckForUpdateErrorDomain = @"com.salesforce.update.check.network.error";
NSString * const SFDCLastCheckForUpdateKey     = @"SFDCLastCheckForUpdateKey";
NSString * const SFDCNotifiedSinceLastCheckKey = @"SFDCNotifiedSinceLastCheckKey";

static NSString * const SFDC_OBJECT_UPDATED_QUERY = @"select LastModifiedDate FROM %@ WHERE LastModifiedDate > %@";

#import "DSA_RemoteObjectStatusClient.h"
#import <SalesforceCommonUtils/SFDateUtil.h>
#import "MM_RestOperation.h"
#import "MM_SOQLQueryString.h"
#import "MM_SyncManager.h"
#import "MMSF_ContentVersion.h"
#import "MM_SyncManager.h"

@interface DSA_RemoteObjectStatusClient()

- (void)saveLastCheckForUpdate;
- (NSString *)lastCheckForUpdate;

@end

@implementation DSA_RemoteObjectStatusClient

@synthesize notified = _notified;

- (instancetype)initWithObjectName:(NSString *)anObjName {
    
    self = [super init];
    
    if (self) {
        
        _objectName = [anObjName copy];
    }
    
    return self;
}

- (void)checkForUpdatesUsingSOQL:(MM_SOQLQueryString *)queryString
                         success:(SFDCUpdatedObjectSuccessBlock)successBlock
                           error:(SFDCUpdatedObjectErrorBlock)errorBlock {
    
    MM_RestOperation *operation = [MM_RestOperation operationWithQuery:queryString
                                                              groupTag:nil
                                                       completionBlock:^(NSError *error, id jsonResponse, MM_RestOperation *completedOp){
                                                           
                                                           
                                                           /**
                                                            * Unforunately the operation doesn't return the completionBlock back on the
                                                            * main thread.
                                                            */
                                                           
                                                           void (^mainThreadCompletionBlock)(void) = ^(void){
                                                               if (error) {
                                                                   
                                                                   if (errorBlock) {
                                                                       errorBlock(completedOp, error, jsonResponse);
                                                                   }
                                                                   
                                                               } else {
                                                                   
                                                                   if (jsonResponse) {
                                                                       
                                                                       if (successBlock) {
                                                                           
                                                                           NSDictionary *jsonDict = (NSDictionary *)jsonResponse;
                                                                           
                                                                           if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
                                                                               
                                                                               NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"There was an error parsing the response into dictionary", nil)};
                                                                               NSError *error         = [[NSError alloc] initWithDomain:SFDCCheckForUpdateErrorDomain
                                                                                                                                   code:NSURLErrorCannotParseResponse
                                                                                                                               userInfo:userInfo];
                                                                               
                                                                               if (errorBlock) {
                                                                                   
                                                                                   errorBlock(completedOp, error, jsonResponse);
                                                                               }
                                                                               
                                                                           } else if ([jsonDict[@"totalSize"] integerValue] > 0) {
                                                                               
                                                                               successBlock(YES, completedOp, jsonResponse);
                                                                               
                                                                           } else {
                                                                               
                                                                               successBlock(NO, completedOp, jsonResponse);
                                                                           }
                                                                       }
                                                                       
                                                                   } else {
                                                                       
                                                                       NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"The operation didn't return a response that was valid, but didn't error either", nil)};
                                                                       NSError *error         = [[NSError alloc] initWithDomain:SFDCCheckForUpdateErrorDomain
                                                                                                                           code:NSURLErrorCannotParseResponse
                                                                                                                       userInfo:userInfo];
                                                                       
                                                                       if (errorBlock) {
                                                                           errorBlock(completedOp, error, jsonResponse);
                                                                       }
                                                                   }
                                                                   
                                                                   [self saveLastCheckForUpdate];
                                                               }
                                                           };
                                                           
                                                           dispatch_async(dispatch_get_main_queue(), mainThreadCompletionBlock);
                                                           
                                                           
                                                           /**
                                                            * Don't feel like dequeing myself
                                                            */
                                                           
                                                           return NO;
                                                       }
                                                             sourceTag:nil];
    
    [[MM_SyncManager sharedManager] queueOperation:operation];
}

- (void)checkForUpdatesWithSucess:(SFDCUpdatedObjectSuccessBlock)successBlock
                            error:(SFDCUpdatedObjectErrorBlock)errorBlock {
    
    NSString *queryString = [NSString stringWithFormat:SFDC_OBJECT_UPDATED_QUERY,
                             self.objectName,
                             [self lastCheckForUpdate]];
    
    MM_SOQLQueryString *sfQueryString = [MM_SOQLQueryString queryWithSOQL:queryString];
    
    [self checkForUpdatesUsingSOQL:sfQueryString
                           success:successBlock
                             error:errorBlock];
}

- (void)setNotified:(BOOL)notified {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:notified forKey:SFDCNotifiedSinceLastCheckKey];
    [defaults synchronize];
    
    _notified = notified;
}

+ (BOOL)hasBeenNotifed {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults boolForKey:SFDCNotifiedSinceLastCheckKey];
}

+ (NSDate *)lastCheckDate {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdateCheck  = [defaults objectForKey:SFDCLastCheckForUpdateKey];
    
    /**
     * This is a safe guard against there always being a nil date object even 
     * if the user has sync'd at least once.
     */

    if (!lastUpdateCheck && [MM_SyncManager sharedManager].hasSyncedOnce) {

        lastUpdateCheck = [NSDate distantPast];
    }
    
    return lastUpdateCheck;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"notified: %@, objectName: %@", [NSNumber numberWithBool:self.notified], self.objectName];
}

#pragma mark - Private Methods

- (void)saveLastCheckForUpdate {
    
    NSDate *ts = [NSDate date];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:ts forKey:SFDCLastCheckForUpdateKey];
    [defaults synchronize];
}

- (NSString *)lastCheckForUpdate {
    
    NSString *dateTimeString = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdateCheck  = [defaults objectForKey:SFDCLastCheckForUpdateKey];
    
    if (lastUpdateCheck) {
        dateTimeString = [SFDateUtil toSOQLDateTimeString:[DSA_RemoteObjectStatusClient lastCheckDate] isDateTime:true];
    } else {
        dateTimeString = [SFDateUtil toSOQLDateTimeString:[NSDate date] isDateTime:true];
    }
    
    return dateTimeString;
}



@end