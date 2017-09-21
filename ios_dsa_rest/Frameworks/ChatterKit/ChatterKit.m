//
//  ChatterDelegate.m
//  chattest
//
//  Created by Guy Umbright on 4/11/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "ChatterKit.h"
#import <SalesforceNativeSDK/SFRestAPI.h>
#import <SalesforceNativeSDK/SFRestRequest.h>
#import "CK_MessageSegment.h"

static ChatterKit *_instance;
static dispatch_once_t _sharedInstanceGuard;

#define REQUEST_KEY @"request"
#define DELEGATE_KEY @"delegate"
#define USERINFO_KEY @"userInfo"
@interface ChatterKit ()

@property (nonatomic, strong) NSMutableSet* outstandingRequests;

@end

@implementation ChatterKit 

@synthesize chatterKitDelegate=_chatterKitDelegate;

@synthesize outstandingRequests;

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
+ (ChatterKit *)sharedInstance
{
    dispatch_once(&_sharedInstanceGuard, 
                  ^{ 
                      _instance = [[ChatterKit alloc] init];
                  });
    return _instance;
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (id) init
{
    if (self = [super init])
    {
        self.outstandingRequests = [NSMutableSet set];
    }
    
    return self;
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (NSString*) version
{
    return @"0.1";
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) send:(SFRestRequest *)request
     delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
     userInfo:(NSObject*) userInfo
{
    NSDictionary* requestDict = [NSDictionary dictionaryWithObjectsAndKeys:request,REQUEST_KEY,
                                 delegate,DELEGATE_KEY,
                                 (userInfo == nil) ? [NSNull null] : userInfo,USERINFO_KEY, nil];
    
    [self.outstandingRequests addObject:requestDict];
    
    [[SFRestAPI sharedInstance] send:request delegate:self];
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) send:(SFRestRequest *)request
     delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
{
    [self send:request delegate:delegate userInfo:nil];
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) postItemToPath:(NSString*) path
        messageSegments:(NSArray*) messageSegments
             attachment:(CK_AttachmentInput*) attachment
               delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
               userInfo:(NSDictionary*) userInfo
{
    NSMutableArray* segments = [NSMutableArray array];
    for (CK_MessageSegmentInput* seg in messageSegments)
    {
        [segments addObject:[seg asDictionary]];
    }
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    
    NSDictionary* segDict = [NSDictionary dictionaryWithObject:segments forKey: @"messageSegments"];
    [params setObject:segDict forKey:@"body"];
    
    if (attachment)
    {
        [params setObject:[attachment asDictionary] forKey:@"attachment"];
    }

    SFRestRequest* request = [SFRestRequest requestWithMethod:SFRestMethodPOST
                                                         path:[NSString stringWithFormat:@"/%@%@",[SFRestAPI sharedInstance].apiVersion,path ]
                                                  queryParams:params];

    NSDictionary* requestDict = [NSDictionary dictionaryWithObjectsAndKeys:request,REQUEST_KEY,
                                 delegate,DELEGATE_KEY,
                                 ((userInfo == nil) ? [NSNull null] : userInfo),USERINFO_KEY, nil];
    
    [self.outstandingRequests addObject:requestDict];
    
    [[SFRestAPI sharedInstance] send:request delegate:self];
    //create the request
    //launch it
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) postItemToPath:(NSString*) path
        messageSegments:(NSArray*) messageSegments
               delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
               userInfo:(NSDictionary*) userInfo
{
    [self postItemToPath:path messageSegments:messageSegments attachment:nil delegate:delegate userInfo:userInfo];
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void) postItemToPath:(NSString*) path
        messageSegments:(NSArray*) messageSegments
               delegate:(id<CK_ChatterKitRestRequestDelegate>)delegate
{
    [self postItemToPath:path messageSegments:messageSegments delegate:delegate userInfo:nil];
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (NSDictionary*) getOutstandingRequest:(SFRestRequest*) request
{
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"request = %@",request];
    NSSet* resultSet = [self.outstandingRequests filteredSetUsingPredicate:pred];
    
    if (resultSet.count)
    {
        NSDictionary* dict = [resultSet anyObject];
        [self.outstandingRequests removeObject:dict];
        return dict;
    }
    
    return nil;
}

#pragma mark SFRestRequestDelegate

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse
{
    NSDictionary* requestDict = [self getOutstandingRequest:request];
    NSObject<CK_ChatterKitRestRequestDelegate>* delegate = [requestDict objectForKey:DELEGATE_KEY];
    
    if ([delegate respondsToSelector:@selector(request:didLoadResponse:userInfo:)])
    {
        NSDictionary* userInfo = [requestDict objectForKey:USERINFO_KEY];
        
        [delegate request:request didLoadResponse: jsonResponse userInfo: (userInfo == (NSDictionary*)[NSNull null]) ? nil : userInfo];
    }
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void)request:(SFRestRequest *)request didFailLoadWithError:(NSError*)error
{
    NSDictionary* requestDict = [self getOutstandingRequest:request];
    NSObject<CK_ChatterKitRestRequestDelegate>* delegate = [requestDict objectForKey:DELEGATE_KEY];

    if ([delegate respondsToSelector:@selector(request:didFailLoadWithError:userInfo:)])
    {
        NSDictionary* userInfo = [requestDict objectForKey:USERINFO_KEY];
        
        [delegate request:request didFailLoadWithError: error userInfo: (userInfo == (NSDictionary*)[NSNull null]) ? nil : userInfo];
    }
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void)requestDidCancelLoad:(SFRestRequest *)request
{
    NSDictionary* requestDict = [self getOutstandingRequest:request];
    NSObject<CK_ChatterKitRestRequestDelegate>* delegate = [requestDict objectForKey:DELEGATE_KEY];
    
    if ([delegate respondsToSelector:@selector(requestDidCancelLoad:userInfo:)])
    {
        NSDictionary* userInfo = [requestDict objectForKey:USERINFO_KEY];
        
        [delegate requestDidCancelLoad:request userInfo: (userInfo == (NSDictionary*)[NSNull null]) ? nil : userInfo];
    }
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (void)requestDidTimeout:(SFRestRequest *)request
{
    NSDictionary* requestDict = [self getOutstandingRequest:request];
    NSObject<CK_ChatterKitRestRequestDelegate>* delegate = [requestDict objectForKey:DELEGATE_KEY];

    if ([delegate respondsToSelector:@selector(requestDidTimeout:userInfo:)])
    {
        NSDictionary* userInfo = [requestDict objectForKey:USERINFO_KEY];
        
        [delegate requestDidTimeout:request userInfo: (userInfo == (NSDictionary*)[NSNull null]) ? nil : userInfo];
    }
}


@end
