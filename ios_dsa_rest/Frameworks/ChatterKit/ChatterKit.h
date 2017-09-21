//
//  ChatterDelegate.h
//  chattest
//
//  Created by Guy Umbright on 4/11/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SalesforceNativeSDK/SFRestAPI.h>
#import "CK_FeedItem.h"
#import "CK_CommentPage.h"
#import "CK_LikePage.h"
#import "CK_MessageSegmentInput.h"
#import "CK_AttachmentInput.h"

@protocol CK_ChatterKitRestRequestDelegate <NSObject>
@optional
- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse userInfo:(NSDictionary*) userInfo;
- (void)request:(SFRestRequest *)request didFailLoadWithError:(NSError*)error userInfo:(NSDictionary*) userInfo;
- (void)requestDidCancelLoad:(SFRestRequest *)request userInfo:(NSDictionary*) userInfo;
- (void)requestDidTimeout:(SFRestRequest *)request userInfo:(NSDictionary*) userInfo;

@end

@interface ChatterKit : NSObject <SFRestDelegate>

@property (nonatomic, unsafe_unretained) NSObject<CK_ChatterKitRestRequestDelegate>* chatterKitDelegate;

+ (ChatterKit *)sharedInstance;

- (NSString*) version;

- (void) send:(SFRestRequest *)request
     delegate:(NSObject<CK_ChatterKitRestRequestDelegate>*)delegate;

- (void) postItemToPath:(NSString*) path
        messageSegments:(NSArray*) messageSegments
               delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate;

- (void) postItemToPath:(NSString*) path
        messageSegments:(NSArray*) messageSegments
               delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
               userInfo:(NSDictionary*) userInfo;

- (void) postItemToPath:(NSString*) path
        messageSegments:(NSArray*) messageSegments
             attachment:(CK_AttachmentInput*) attachment
               delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
               userInfo:(NSDictionary*) userInfo;

@end

#import "ChatterKitPaths.h"

