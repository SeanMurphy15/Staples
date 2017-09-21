//
//  DSARestClient.h
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSA_SyncProgressViewController.h"



#define		kNotification_ContentDownloadComplete		@"KContentItemsDownloaded"
#define		kNotification_ContentDownloadStarted		@"KContentItemsDownloadStarted"
#define	    kDefaults_CurrentLoggedInUserID				@"CurrentLoggedInUserID"
#define	    kDefaults_LastUserID                        @"LastUserID"
#define		kDefaults_PreviousUserName					@"kDefaults_PreviousUserEmail"
#define     kNotification_DownloadCompleted             @"com.modelmetrics.dsa.downloadCompleted"
#define     kNotification_PostSyncOpsDone               @"com.modelmetrics.dsa.postSyncOperationsDone"
#define     kNotification_UserChange                    @"userChanged"
#define     kNotification_SyncProgressDidDismiss        @"kNotification_SyncProgressDidDismiss"

@interface DSARestClient : NSObject <DSA_SyncProgressViewControllerDelegate> {
    NSInteger attachmentCounter;
    NSInteger contentCounter;
    NSMutableArray * completedSyncObjects;
}

@property (nonatomic) BOOL resyncingDueToNoActiveConfigurations;
@property (weak, nonatomic) DSA_SyncProgressViewController *syncProgressViewController;
@property (assign, nonatomic) BOOL isShowingSyncProgress;
@property (nonatomic, strong) NSArray *featuredContentIdArray;

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(DSARestClient, sharedInstance);

- (void) connectWithSalesForce:(NSNotification*)note;
- (void) deltaSync;
- (void) fullSync;

- (BOOL)refreshMetaDataIfNeeded;

@end
