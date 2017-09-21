//
//  RemoteObjectStatusManager.h
//  ios_dsa
//
//  Created by Cory Wiles on 8/22/13.
//
//

#import <Foundation/Foundation.h>

@class MM_RestOperation;
@class MM_SOQLQueryString;

extern NSString * const SFDCCheckForUpdateErrorDomain;
extern NSString * const SFDCLastCheckForUpdateKey;
extern NSString * const SFDCNotifiedSinceLastCheckKey;

typedef void(^SFDCUpdatedObjectSuccessBlock)(BOOL hasUpdate, MM_RestOperation *operation, id jsonResponse);
typedef void(^SFDCUpdatedObjectErrorBlock)(MM_RestOperation *operation, NSError *error, id jsonResponse);

@interface DSA_RemoteObjectStatusClient : NSObject

@property (nonatomic, readonly, copy) NSString *objectName;
@property (nonatomic)BOOL notified;

- (instancetype)initWithObjectName:(NSString *)anObjName;
- (void)checkForUpdatesUsingSOQL:(MM_SOQLQueryString *)queryString
                         success:(SFDCUpdatedObjectSuccessBlock)successBlock
                           error:(SFDCUpdatedObjectErrorBlock)errorBlock;
- (void)checkForUpdatesWithSucess:(SFDCUpdatedObjectSuccessBlock)successBlock
                            error:(SFDCUpdatedObjectErrorBlock)errorBlock;
+ (BOOL)hasBeenNotifed;
+ (NSDate *)lastCheckDate;

@end