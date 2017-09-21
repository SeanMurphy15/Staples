//
//  DSA_CellularDataDefender.h
//  DSA
//
//  Created by Mike Close on 5/3/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SalesforceCommonUtils/SalesforceCommonUtils.h>

typedef NS_OPTIONS(NSUInteger, DSACellularDataDefenderAlertOptions) {
    AlertOptionNone                                 = 0,
    AlertOptionRequireWifiForInitialSync            = 1,
    AlertOptionWarnAboutWifiForInitialSync          = 1 << 1,
    AlertOptionRequireWifiForFullSync               = 1 << 2,
    AlertOptionWarnAboutWifiForFullSync             = 1 << 3,
    AlertOptionWarnAboutCellularDataWhenAvailable   = 1 << 4,
    AlertOptionRequireCellularFileSizeLimit         = 1 << 5,
    AlertOptionWarnAboutCellularFileSizeLimit       = 1 << 6
};

@interface DSA_CellularDataDefender : NSObject

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(DSA_CellularDataDefender, sharedInstance);

/*
 * Compares the network connectivity state (wifi and wwan(wlan)) and executes the appropriate
 * alerting behavior for initial sync, based on the options that were configured on the shared instance.
 * It is up to the caller to alter the behavior of the application according to the status returned.  For example,
 * we're currently using the response from this method to determine whether or not we let user's log in for the
 * first time in MM_FlexibleVisualBrowser.
 */
- (BOOL)willAlertAboutInitialSyncWithDismissBlock:(SFAlertViewDismissBlock)dismissBlock;

/*
 * Compares the network connectivity state (wifi and wwan(wlan)) and executes the appropriate
 * alerting behavior for user-initiated full syncs, based on the options that were configured on the shared instance.
 * It is up to the caller to alter the behavior of the application according to the status returned.  For example,
 * we're currently using the response from this method to determine how we perform full syncs in DSA_SettingsMenuViewController.
 */
- (BOOL)willAlertAboutFullSyncWithDismissBlock:(SFAlertViewDismissBlock)dismissBlock;

/*
 * Compares the network connectivity state (wifi and wwan(wlan)) and executes the appropriate
 * alerting behavior regarding file size limits, based on the options that were configured on the shared instance.
 * It is up to the caller to alter the behavior of the application according to the status returned.  For example,
 * we're currently calling this method from MMSF_ContentVersion, and if it returns YES, we set a file size limit on
 * the ContentVersion query.
 */
- (BOOL)willAlertAboutFileSizeWithDismissBlock:(SFAlertViewDismissBlock)dismissBlock;

/*
 * A convenience method that converts the specified filesize (in MB) to bytes.
 */
- (NSNumber *)fileSizeLimitInBytes;

/*
 * A bitmask of DSACellularDataDefenderAlertOptions options that define the Alerting behavior of the class.
 */
@property (nonatomic)   DSACellularDataDefenderAlertOptions options;

/*
 * When AlertOptionWarnAboutCellularFileSizeLimit or AlertOptionRequireCellularFileSizeLimit are set,
 * this is the threshold used to in the query created by the MMSF_ContentVersion class. Specified in megabytes.
 */
@property (nonatomic)   NSUInteger  fileSizeLimit;


/*
 *
 * We don't want to alert for every single file, so we only alert one time and this flag is set to NO.
 * When the MM_SyncManager posts the kNotification_SyncComplete notification, we reset the flag to YES.
 *
 */
@property (nonatomic)   BOOL        shouldAlertAboutFileSize;

@end
