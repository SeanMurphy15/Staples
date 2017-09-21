//
//  DSA_CellularDataDefender.m
//  DSA
//
//  Created by Mike Close on 5/3/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_CellularDataDefender.h"

@implementation DSA_CellularDataDefender

SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(DSA_CellularDataDefender, sharedInstance);

- (id)init
{
    if (self = [super init])
    {
        // by default, this class will not alert about anything.
        [self setOptions:AlertOptionNone];
        
        // TODO: set this from a value defined in the MAC, if the CellularDataDefender feature is turned on in the MAC.
        [self setFileSizeLimit:(NSUInteger)5];
        
        // This flag ensures that we only show the cellular data file size limit once. The AlertOption still guides whether it is shown at all.
        [self setShouldAlertAboutFileSize:YES];
        
        // We reset the alert flag after sync is complete
        [self addAsObserverForName: kNotification_SyncComplete selector: @selector(resetAlertFlags)];
    }
    return self;
}

- (BOOL)willAlertAboutInitialSyncWithDismissBlock:(SFAlertViewDismissBlock)dismissBlock;
{
    if (![[SA_ConnectionQueue sharedQueue] wifiAvailable]) {
        if ([self options] & AlertOptionRequireWifiForInitialSync)
        {
            // blocking alert for initial sync
            UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Notice"
                                                         message:@"You are not connected to a WIFI network. Your organization requires that you connect to WIFI when logging in for the first time."
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil
                                                 didDismissBlock:dismissBlock];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            return YES;
        }
        if ([self options] & AlertOptionWarnAboutWifiForInitialSync)
        {
            // warning alert for initial sync
            UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Warning"
                                                         message:@"You are not connected to a WIFI network. Your organization requests that you connect to WIFI when logging in for the first time."
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@[@"Continue"]
                                                 didDismissBlock:dismissBlock];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            return YES;
        }
    }
    
    if ([self willAlertToDisableCellular:dismissBlock])
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)willAlertAboutFullSyncWithDismissBlock:(SFAlertViewDismissBlock)dismissBlock;
{
    if (![[SA_ConnectionQueue sharedQueue] wifiAvailable]) {
        if ([self options] & AlertOptionRequireWifiForFullSync)
        {
            // blocking alert for full sync
            UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Notice"
                                                         message:@"You are not connected to a WIFI network. Your organization requires that you connect to WIFI before perform a full synchronization."
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil
                                                 didDismissBlock:dismissBlock];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            return YES;
        }
        if ([self options] & AlertOptionWarnAboutWifiForFullSync)
        {
            // warning alert for full sync
            UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Warning"
                                                         message:@"You are not connected to a WIFI network. Your organization requests that you connect to WIFI before perform a full synchronization."
                                               cancelButtonTitle:@"Cancel Sync"
                                               otherButtonTitles:@[@"Continue Sync"]
                                                 didDismissBlock:dismissBlock];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            return YES;
        }
    }
    
    if ([self willAlertToDisableCellular:dismissBlock])
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)willAlertAboutFileSizeWithDismissBlock:(SFAlertViewDismissBlock)dismissBlock;
{
    if (![[SA_ConnectionQueue sharedQueue] wifiAvailable]) {
        
        if ([self options] & AlertOptionRequireCellularFileSizeLimit)
        {
            if ([self shouldAlertAboutFileSize])
            {
                // blocking alert for file size limits (doesn't allow the user to say, "download them anyway"
                UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Notice"
                                                             message:[NSString stringWithFormat:@"You are not connected to a WIFI network. Files larger than %dMB will not be downloaded to your device. You must connect to wifi and synchronize again in order to download the missing content.", [self fileSizeLimit]]
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil
                                                     didDismissBlock:dismissBlock];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
                [self setShouldAlertAboutFileSize:NO];
                
            }
            return YES;
        }
        
        if ([self options] & AlertOptionWarnAboutCellularFileSizeLimit)
        {
            if ([self shouldAlertAboutFileSize])
            {
                // warning alert for file size limits (allows the user to say, "download them anyway"
                UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Notice"
                                                             message:[NSString stringWithFormat:@"You are not connected to a WIFI network. Files larger than %dMB will not be downloaded to your device. You must connect to wifi and synchronize again in order to download the missing content.", [self fileSizeLimit]]
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:@[@"Emergency Download"]
                                                     didDismissBlock:dismissBlock];
                [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
                [self setShouldAlertAboutFileSize:NO];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL)willAlertToDisableCellular:(SFAlertViewDismissBlock)dismissBlock
{
    if ([[SA_ConnectionQueue sharedQueue] wifiAvailable] && [[SA_ConnectionQueue sharedQueue] wlanAvailable] && ([self options] & AlertOptionWarnAboutCellularDataWhenAvailable))
    {
        // warning alert for full sync
        UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Warning"
                                                     message:@"You are connected to both Cellular Data and WIFI networks. In order to prevent accidental use of the cellular network, it may be wise to disable Cellular Data in your device's System Settings."
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@[@"Continue"]
                                             didDismissBlock:dismissBlock];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
        return YES;
    }
    
    return NO;
}

- (NSNumber *)fileSizeLimitInBytes;
{
    return [NSNumber numberWithInteger:([self fileSizeLimit] * 1024 * 1024)];
}

- (void)resetAlertFlags
{
    [self setShouldAlertAboutFileSize:YES];
}

@end
