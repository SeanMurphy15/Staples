 //
//  DSA_SyncProgressViewController.m
//  DSA
//
//  Created by Mike McKinley on 3/19/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_SyncProgressViewController.h"
#import "MM_SyncManager.h"
#import "MM_Config.h"
#import "UIColor+DSA.h"
#import "DSA_SyncProgressImageView.h"
#import "MMSF_Attachment.h"
#import "MMSF_ContentVersion.h"
#import "SFRestAPI+ContinuedRequest.h"
#import "DSARestClient.h"
#import "DSA_Defines.h"

typedef NS_ENUM(NSUInteger, DSA_SyncProgressImageViewTags) {
    DSA_StepOneImageViewTag = 101,
    DSA_StepTwoImageViewTag,
    DSA_StepThreeImageViewTag,
    DSA_StepFourImageViewTag
};

typedef NS_ENUM(NSUInteger, DSA_SyncProgressLabelTags) {
    DSA_StepOneLabelTag = 201,
    DSA_StepTwoLabelTag,
    DSA_StepThreeLabelTag,
    DSA_StepFourLabelTag
};

typedef NS_ENUM(NSUInteger, DSA_SyncProgressStep) {
    DSA_SyncProgressStepOne = 1,
    DSA_SyncProgressStepTwo,
    DSA_SyncProgressStepThree,
    DSA_SyncProgressStepFour
};

static CGFloat const StepZeroProgress = 100.0/640.0;
static CGFloat const StepOneProgress = 260.0/640.0;
static CGFloat const StepTwoProgress = 420.0/640.0;
static CGFloat const StepThreeProgress = 580.0/640.0;
static CGFloat const StepFourProgress = 1.0;

static NSString * const titleStringFormat = @"Step %d - %@";

@interface DSA_SyncProgressViewController ()

// track block based notification obervers
@property (assign, nonatomic) CGFloat progressBarWidth;
@property (assign, nonatomic) BOOL detailVisible;
@property (assign, nonatomic) int64_t syncingDownloadSize;
@property (assign, nonatomic) int64_t completedDownloadSize;
@property (assign, nonatomic) int64_t bps;
@property (assign, nonatomic) CFTimeInterval downloadStartTime;
@property (assign, nonatomic) DSA_SyncProgressStep step;
@property (assign, nonatomic) DSA_SyncProgressState lastState;
@property (assign, nonatomic) CGFloat blobProgressIncrement;
@property (assign, nonatomic) BOOL firstBlobDownloaded;
@property (assign, nonatomic) BOOL completed;

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) int64_t secondsRemaining;
@property (assign, nonatomic) int64_t contentSize, attachmentSize;

- (void)observe;
- (void)setState:(DSA_SyncProgressState)state forStep:(DSA_SyncProgressStep)step;
- (void)showDetailView;
- (void)updateTimeRemaining:(NSTimer*)timer;

@end

@implementation DSA_SyncProgressViewController

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder: aDecoder]) {
		[self observe];
	}
	return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil]) {
		[self observe];
	}
	return self;
}

- (void)prepare {
    self.titleLabel.textColor = [UIColor darkBlueTextColor];
    self.titleLabel.text = @"Preparing to Synchronize";
    self.timeRemainingLabel.textColor = [UIColor darkBlueTextColor];
    self.timeRemainingLabel.text = @"";
    
    self.overallProgressView.progress = StepZeroProgress;
    self.overallProgressView.progressTintColor = [UIColor sfdcPrimaryBlue];
    self.overallProgressView.trackTintColor = [UIColor lightGrayColor];
    
    [self setState:DSA_SyncProgressState_Waiting forStep:DSA_SyncProgressStepOne];
    [self setState:DSA_SyncProgressState_Waiting forStep:DSA_SyncProgressStepTwo];
    [self setState:DSA_SyncProgressState_Waiting forStep:DSA_SyncProgressStepThree];
    [self setState:DSA_SyncProgressState_Waiting forStep:DSA_SyncProgressStepFour];
    
    self.detailLabel.text = @"";
        
    self.syncingDownloadSize = 0;
    self.completedDownloadSize = 0;
    
    self.bps = 1000000;
    self.completed = NO;
    self.firstBlobDownloaded = NO;
    
    self.step = DSA_SyncProgressStepOne;
    self.lastState = DSA_SyncProgressState_Waiting;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nibHeight = CGRectGetHeight(self.view.frame);
    self.nibWidth = CGRectGetWidth(self.view.frame);
    self.progressBarWidth = CGRectGetWidth(self.overallProgressView.frame);
    
    self.detailVisible = NO;
    self.detailView.alpha = 0;

    self.cancelButton.hidden = ![MM_SyncManager sharedManager].hasSyncedOnce;
    
    [self prepare];
}

 - (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
     
    // override UIModalPresentationStyle size constraints for iOS 7
    if (NSClassFromString(@"UIPresentationController") == nil) {
        self.view.superview.bounds = CGRectMake(0, 0, self.nibWidth, self.nibHeight);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setState:self.lastState forStep:self.step];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimeRemaining:) userInfo:nil repeats:YES];
    self.timer.fireDate = [NSDate distantFuture];
    
    [DSARestClient sharedInstance].isShowingSyncProgress = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timer invalidate];
    self.timer = nil;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [DSARestClient sharedInstance].isShowingSyncProgress = NO;
    [super viewDidDisappear:animated];
}

- (CGSize)preferredContentSize {
    // override UIModalPresentationStyle size constraints for iOS 8
    CGSize preferredSize = CGSizeMake(self.nibWidth, self.nibHeight);
    
    return preferredSize;
}

#pragma mark - Content Time Remaing Estimate

- (int64_t)syncingDownloadSize {
    return self.contentSize + self.attachmentSize;
}

- (NSString *)hoursMinutesSecondsString:(int64_t)totalSeconds {
    NSString *outString = @"";
    
    if (totalSeconds > 0) {
        int64_t seconds = totalSeconds % 60;
        int64_t minutes = (totalSeconds / 60) % 60;
        int64_t hours = totalSeconds / 3600;
        
        if (hours) {
            outString = [NSString stringWithFormat:@"%02lluh %02llum %02llus", hours, minutes, seconds];
        } else {
            outString = [NSString stringWithFormat:@"%02llum %02llus", minutes, seconds];
        }
    }
    
    return outString;
}

- (void)markPreviousStepsFinished {
    // insure prior steps show finished
    DSA_SyncProgressStep i;
    DSA_SyncProgressImageView *imageView;
    UILabel *label;
    for (i = DSA_SyncProgressStepOne; i < self.step; i++) {
        imageView = (DSA_SyncProgressImageView *)[self.view viewWithTag:100 + i];
        imageView.syncState = DSA_SyncProgressState_Finished;
        label = (UILabel *)[self.view viewWithTag:200 + i];
        label.textColor = [UIColor sfdcPrimaryBlue];
    }
}

- (void)setState:(DSA_SyncProgressState)state forStep:(DSA_SyncProgressStep)step {
    if (step < self.step) {
        return;
    }
    
    self.step = step;
    self.lastState = state;
    
    DSA_SyncProgressImageView *stepImageView = (DSA_SyncProgressImageView *)[self.view viewWithTag:100 + step];
    stepImageView.syncState = state;
    UILabel *stepLabel = (UILabel *)[self.view viewWithTag:200 + step];
    stepLabel.textColor = (state == DSA_SyncProgressState_Finished) ? [UIColor sfdcPrimaryBlue] : [UIColor lightGrayColor];
    
    if (state == DSA_SyncProgressState_Syncing) {
        [self markPreviousStepsFinished];
        [self updateTitle];
    }
    
    if (state == DSA_SyncProgressState_Finished) {
        [self markPreviousStepsFinished];
        
        CGFloat minProgressForStep = StepZeroProgress;
        switch (step) {
            case DSA_SyncProgressStepOne:
                minProgressForStep = StepOneProgress;
                  break;
            case DSA_SyncProgressStepTwo:
                minProgressForStep = StepTwoProgress;
                break;
            case DSA_SyncProgressStepThree:
                minProgressForStep = StepThreeProgress;
                break;
            case DSA_SyncProgressStepFour:
                minProgressForStep = StepFourProgress;
                self.completed = YES;
                break;
        }
        if (self.overallProgressView.progress < minProgressForStep) {
            self.overallProgressView.progress = minProgressForStep;
        }
        [self updateTitle];
    }
}

- (void)updateTitle {
    NSString *stepName = @"";
    
    switch (self.step) {
        case DSA_SyncProgressStepOne:   stepName = @"Queueing"; break;
        case DSA_SyncProgressStepTwo:   stepName = @"Configuring"; break;
        case DSA_SyncProgressStepThree: stepName = @"Downloading Content"; break;
        case DSA_SyncProgressStepFour:  stepName = @"Finishing"; break;
        default:                        stepName = @"Synchronizing"; break;
    }
    self.titleLabel.text = [NSString stringWithFormat:titleStringFormat, self.step, stepName];
    
    if (self.updatingMetaData) {
        self.titleLabel.text = @"[Updating Metadata]";
    }
}

- (void)updateTimeRemaining:(NSTimer*)timer {
    NSString *timeRemainingString = @"";
    
    // must have syncingDownloadSize
    if (self.syncingDownloadSize > 0) {
        // report the time remaining after the second blob to avoid wild estimates
        if (!self.firstBlobDownloaded) {
            timeRemainingString = @"Estimating time to sync content...";
            self.firstBlobDownloaded = YES;
        }
        
        if (self.completedDownloadSize > 0) {
            if (timer) { self.secondsRemaining--; }
            NSString *timeString = [self hoursMinutesSecondsString:self.secondsRemaining];
            if (self.secondsRemaining < 75) {
                timeString = @"About a minute";
            }
            timeRemainingString = [NSString stringWithFormat:@"%@ remaining", timeString];
            // MMLog(@"Remaining: %llu seconds, %@", self.secondsRemaining, timeRemainingString);
        }
        
        if (self.secondsRemaining < 1) {
            timeRemainingString = @"";
        }
        
        // done
        if (self.completed) {
            timeRemainingString = @"Completed";
            [timer invalidate];
        }        
    }
    
    self.timeRemainingLabel.text = timeRemainingString;
}

- (void)dismiss {
    if ([self.delegate respondsToSelector:@selector(syncProgressControllerDidFinish:)]) {
        [self.delegate syncProgressControllerDidFinish:self];
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Actions

- (IBAction)cancelTouched:(id)sender {
    self.titleLabel.text = @"Canceling Sync...";

    [[MM_SyncManager sharedManager] cancelSync: mm_sync_cancel_reason_user];
    
    // initial sync interupted
    if ([MM_SyncManager sharedManager].syncInterrupted && ![MM_SyncManager sharedManager].hasSyncedOnce ) {
        [MM_LoginViewController logout];
        //[[MM_LoginViewController currentController] clearLoginState];
    }
        
    [self dismiss];
}

- (void)showDetailView {
    BOOL visible = self.detailVisible;
    CGFloat alpha = 0;
    
    if (!visible) {
        self.detailVisible = YES;
        alpha = 1;
    } else if (visible) {
        self.detailVisible = NO;
        alpha = 0;
    }
    
    // changed
    if (self.detailVisible != visible) {
        [UIView animateWithDuration:0.5 animations:^ {
            self.detailView.alpha = alpha;
        }];
    }
}

- (IBAction)doubleTapRecognized:(UITapGestureRecognizer*)sender {
    if(sender.state == UIGestureRecognizerStateEnded) {
        [self showDetailView];
    }
}

#pragma mark - Content Size

- (MM_SOQLQueryString*)soqlQueryForContentVersionSum {
    MM_SOQLQueryString *mmQueryString = [MMSF_ContentVersion baseQueryIncludingData:NO];
//FIXME    mmQueryString.aggregateField = @"ContentSize";
//FIXME    mmQueryString.aggregateOperation = @"SUM";
    
    if ([MM_SyncManager sharedManager].currentSyncType == syncType_delta) {
        mmQueryString.lastModifiedDate = [MM_Config sharedManager].lastSyncDate;
    }
    return mmQueryString;
}

- (MM_SOQLQueryString*)soqlQueryForAttachmentSum {
    MM_SOQLQueryString *mmQueryString = [MMSF_Attachment baseQueryIncludingData:NO];
//FIXME    mmQueryString.aggregateField = @"BodyLength";
//FIXME    mmQueryString.aggregateOperation = @"SUM";
    
    if ([MM_SyncManager sharedManager].currentSyncType == syncType_delta) {
        mmQueryString.lastModifiedDate = [MM_Config sharedManager].lastSyncDate;
    }
    return mmQueryString;
}

- (void)queryContentDownloadSize {
    MM_SOQLQueryString *mmQueryString = [self soqlQueryForContentVersionSum];
    NSString *queryString = mmQueryString.queryString;
    if ([queryString hasSuffix:@"LIMIT 1"]) { return; }
    
    // only pulls the first 300 due to FILTERED_ID_CHUNK_SIZE
    [[SFRestAPI sharedInstance] performSOQLQuery:queryString failBlock:^(NSError *error) {
        MMLog(@"Error: %d, %@", error.code, error.description);
    } completeBlock:^(NSDictionary *completionInfo) {
        NSArray *records = completionInfo[@"records"];
        if (records) {
            NSNumber *sumNumber = records[0][@"expr0"];
            if ( sumNumber && sumNumber != (NSNumber*)[NSNull null]) {
                self.contentSize = [sumNumber longLongValue];
                MMLog(@"Content download size: %@", sumNumber);
            }
        }
    }];
}

- (void)queryAttachmentDownloadSize {
    MM_SOQLQueryString *mmQueryString = [self soqlQueryForAttachmentSum];
    NSString *queryString = mmQueryString.queryString;
    if ([queryString hasSuffix:@"LIMIT 1"]) { return; }
    
    // only pulls the first 300 due to FILTERED_ID_CHUNK_SIZE
    [[SFRestAPI sharedInstance] performSOQLQuery:queryString failBlock:^(NSError *error) {
        MMLog(@"Error: %d, %@", error.code, error.description);
    } completeBlock:^(NSDictionary *completionInfo) {
        NSArray *records = completionInfo[@"records"];
        if (records.count) {
            NSNumber *sumNumber = records[0][@"expr0"];
            if ( sumNumber && sumNumber != (NSNumber*)[NSNull null]) {
                self.attachmentSize = [sumNumber longLongValue];
                MMLog(@"Attachment download size: %@", sumNumber);
            }
        }
    }];
}

- (void) calculateBlobDownloadSize {
    [self queryContentDownloadSize];
    [self queryAttachmentDownloadSize];
    
    // moveme
    self.downloadStartTime = CACurrentMediaTime();
}

- (void)calculateDownloadSizeForObject:(NSString*)objectName {
    // context used for importing
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].contentContextForWriting;
    NSPredicate *datePredicate = nil;
    
    if ([MM_SyncManager sharedManager].currentSyncType == syncType_delta) {
        datePredicate = [NSPredicate predicateWithFormat:@"LastModifiedDate > %@", [MM_Config sharedManager].lastSyncDate];
    }
    
    if ([objectName isEqualToString:[MMSF_ContentVersion entityName]]) {
        MM_SOQLQueryString *mmQueryString = [self soqlQueryForContentVersionSum];
        NSString *queryString = mmQueryString.queryString;
        if ([queryString hasSuffix:@"LIMIT 1"]) { return; }

        NSArray *contentArray = [moc allObjectsOfType:objectName matchingPredicate:datePredicate];
        NSDecimalNumber *sizeSum = [contentArray valueForKeyPath:@"@sum.ContentSize"];
        MMLog(@"ContentVersion size sum: %@", sizeSum);
        self.contentSize = [sizeSum longLongValue];
         
        // approximate Attachments (not complete yet)
        if (!self.attachmentSize) {
             [self queryAttachmentDownloadSize];
        }

        self.downloadStartTime = CACurrentMediaTime();
    } else if ([objectName isEqualToString:[MMSF_Attachment entityName]]) {
        // update downloading size
        NSArray *contentArray = [moc allObjectsOfType:objectName matchingPredicate:datePredicate];
        NSDecimalNumber *sizeSum = [contentArray valueForKeyPath:@"@sum.BodyLength"];
        MMLog(@"Attachment size sum: %@", sizeSum);
        self.attachmentSize = [sizeSum longLongValue];
    }
}

#pragma mark - Notifications

// kNotification_BlobDownloaded
- (void) blobDownloaded:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@, %@", note.name, note.object);

    @synchronized(self) {
        CFTimeInterval now = CACurrentMediaTime();
        CFTimeInterval elapsedDownloadTime = now - self.downloadStartTime;
        
        [self.timer setFireDate:[NSDate distantFuture]];
        
        NSInteger downloadSize = 0;
        NSManagedObjectContext *moc = [[MM_ContextManager sharedManager] threadContentContext];
        NSPredicate* predicate = [NSPredicate predicateWithFormat: @"Id BEGINSWITH %@", note.object];
        // NSInteger count = 0;
        
        MMSF_Attachment *attachment = [moc anyObjectOfType:@"Attachment" matchingPredicate:predicate];
        if(!attachment) {
            MMSF_ContentVersion *content = [moc anyObjectOfType:@"ContentVersion" matchingPredicate:predicate];
            //count = [moc numberOfObjectsOfType:@"ContentVersion" matchingPredicate:nil];
            downloadSize = [content[@"ContentSize"] unsignedIntegerValue];
            if (content) {
                self.detailLabel.text = [NSString stringWithFormat:@"Downloaded Content - %@", content[@"Title"]];
            }
        } else {
            //count = [moc numberOfObjectsOfType:@"Attachment" matchingPredicate:nil];
            self.detailLabel.text = [NSString stringWithFormat:@"Downloaded Attachment - %@", attachment[@"Name"]];
            downloadSize = [attachment[@"BodyLength"] unsignedIntegerValue];
        }
        
        if (downloadSize) {
            self.completedDownloadSize += downloadSize;
            self.bps = self.completedDownloadSize / elapsedDownloadTime;
            int64_t remaining = self.syncingDownloadSize - self.completedDownloadSize;
            self.secondsRemaining = remaining / self.bps;
            
            NSString *byteCountString = [NSByteCountFormatter stringFromByteCount:self.completedDownloadSize countStyle:NSByteCountFormatterCountStyleFile];
            self.detailDownloadedLabel.text = byteCountString;
            byteCountString = [NSByteCountFormatter stringFromByteCount:self.syncingDownloadSize countStyle:NSByteCountFormatterCountStyleFile];
            self.detailTotalLabel.text = [NSString stringWithFormat:@"of %@", byteCountString];
            self.detailRateLabel.text = [NSString stringWithFormat:@"%llu KBps", self.bps/1000];
            
            MMLog(@"Downloaded %llu bytes in %f seconds, rate = %llu KBps", self.completedDownloadSize, elapsedDownloadTime, self.bps/1000);
            [self updateTimeRemaining:nil];
            [self.timer setFireDate:[NSDate date]];
            
            // progress bar
            double blobCompletion = (double)self.completedDownloadSize / self.syncingDownloadSize;
            double distance = StepThreeProgress - StepTwoProgress;
            self.overallProgressView.progress = StepTwoProgress + blobCompletion * distance;
        }
    }
}

// kNotification_MetaDataFetchStarted
- (void)metaDataFetchStarted:(NSNotification*)note {
    MMLog(@"Sync progress notification: name:%@", note.name);
    self.detailLabel.text = @"Fetching Meta Data";
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepOne];
    
    if (self.updatingMetaData) {
        // display Configuration step when refreshing metadata only
        [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepTwo];
    }
}

// kNotification_MetaDataDownloadsComplete
- (void)metaDataDownloadsComplete:(NSNotification*)note {
    MMLog(@"Sync progress notification: name:%@", note.name);
    self.detailLabel.text = @"Meta Data Successfully Downloaded";
}

// kNotification_MissingLinksConnectionStarting
- (void)missingLinksConnectionStarting:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Connecting Missing Links";
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepFour];
}

// kNotification_MissingLinksConnectingObject
- (void)missingLinksConnectingObject:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = [NSString stringWithFormat:@"Connecting Missing Links For: %@", note.name];
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepFour];
}

// kNotification_ModelUpdateBegan
- (void)modelUpdateBegan:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Model Update Began";
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepOne];
}

// kNotification_ModelUpdateComplete
- (void)modelUpdateComplete:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Model Update Complete";
    [self setState:DSA_SyncProgressState_Finished forStep:DSA_SyncProgressStepOne];
}

// kNotification_ObjectDataBeginning
- (void)objectDataBegining:(NSNotification*)note {
    NSString *title = note.userInfo[@"title"];
    MMLog(@"Sync progress notification: %@, %@", note.name, title);
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepThree];
    self.detailLabel.text = [NSString stringWithFormat:@"Downloading %@", title];
}

// kNotification_ObjectDefinitionsImported
- (void)objectDefinitionsImported:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Object Definitions downloaded";
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepOne];
}

// kNotification_ObjectsImported
- (void)objectsImported:(NSNotification*)note {
    NSString *importedName = note.userInfo[@"name"];
    MMLog(@"Sync progress notification: name:%@, object:%@", note.name, importedName);
    self.detailLabel.text = [NSString stringWithFormat:@"ObjectsImported - %@", importedName];
    if ([importedName hasPrefix:[MMSF_ContentVersion entityName]] || [importedName hasPrefix:[MMSF_Attachment entityName]]) {
        [self calculateDownloadSizeForObject:importedName];
        [self updateTimeRemaining:nil];
    }
}

// kNotification_ObjectSyncBegan
- (void)objectSyncBegan:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@, %@", note.name, note.object);
    self.detailLabel.text = [NSString stringWithFormat:@"Object Sync Began for: %@", note.object];
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepTwo];
}

// kNotification_ObjectSyncCompleted
- (void)objectSyncCompleted:(NSNotification*)note {
    NSString *objectName = note.object;
    MMLog(@"Sync progress notification: name:%@, object:%@", note.name, objectName);
    self.detailLabel.text = [NSString stringWithFormat:@"Object Complete - %@", objectName];
}

// kNotification_SyncBegan
- (void)syncBegan:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Sync Started";
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepTwo];
}

// kNotification_SyncResumed
- (void)syncResumed:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Sync Resuming";
    [self setState:DSA_SyncProgressState_Syncing forStep:DSA_SyncProgressStepTwo];
	self.cancelButton.hidden = ![MM_SyncManager sharedManager].hasSyncedOnce;
}

// kNotification_SyncComplete
- (void)syncComplete:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    self.detailLabel.text = @"Sync Complete";
    [self setState:DSA_SyncProgressState_Finished forStep:DSA_SyncProgressStepFour];
    self.overallProgressView.progress = 1.0;
    self.cancelButton.hidden = YES;
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:3.0];
}

// kNotification_WillLogOut
- (void)willLogOut:(NSNotification*)note {
    MMLog(@"Sync progress notification: %@", note.name);
    if (self.isViewLoaded) {
        [self dismiss];
    }
}

- (void) syncCancelled: (NSNotification *) Note {
    if (self.isViewLoaded) {
        [self dismiss];
    }
}

- (void) observe {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // sync and download
    [center addObserver:self selector:@selector(blobDownloaded:) name:kNotification_BlobDownloaded object:nil];
    [center addObserver:self selector:@selector(metaDataDownloadsComplete:) name:kNotification_MetaDataDownloadsComplete object:nil];
    [center addObserver:self selector:@selector(metaDataFetchStarted:) name:kNotification_MetaDataFetchStarted object:nil];
    [center addObserver:self selector:@selector(missingLinksConnectionStarting:) name:kNotification_MissingLinksConnectionStarting object:nil];
    [center addObserver:self selector:@selector(missingLinksConnectingObject:) name:kNotification_MissingLinksConnectingObject object:nil];
    [center addObserver:self selector:@selector(modelUpdateBegan:) name:kNotification_ModelUpdateBegan object:nil];
    [center addObserver:self selector:@selector(modelUpdateComplete:) name:kNotification_ModelUpdateComplete object:nil];
    [center addObserver:self selector:@selector(objectDataBegining:) name:kNotification_ObjectDataBeginning object:nil];
    [center addObserver:self selector:@selector(objectDefinitionsImported:) name:kNotification_ObjectDefinitionsImported object:nil];
    [center addObserver:self selector:@selector(objectsImported:) name:kNotification_ObjectsImported object:nil];
    [center addObserver:self selector:@selector(objectSyncBegan:) name:kNotification_ObjectSyncBegan object:nil];
    [center addObserver:self selector:@selector(objectSyncCompleted:) name:kNotification_ObjectSyncCompleted object:nil];
    [center addObserver:self selector:@selector(syncBegan:) name:kNotification_SyncBegan object:nil];
    [center addObserver:self selector:@selector(syncComplete:) name:kNotification_SyncComplete object:nil];
    [center addObserver:self selector:@selector(syncCancelled:) name:kNotification_SyncCancelled object:nil];
    [center addObserver:self selector:@selector(syncResumed:) name:kNotification_SyncResumed object:nil];
    
    // logout
    [center addObserver:self selector:@selector(willLogOut:) name:kNotification_WillLogOut object:nil];
    [center addObserver:self selector:@selector(willLogOut:) name:kNotification_OAuthCredsExpired object:nil];
}

// sync paused, connection offline
- (void)noticeSyncInterupted:(NSNotification*)note {
    MMLog(@"%s - %@", __FUNCTION__, note.name);
    
    self.titleLabel.text = @"Waiting for Connectivity to Resume Synchronization…";
    [self.timer invalidate];
    self.timeRemainingLabel.text = @"";

 	if ([MM_SyncManager sharedManager].syncInterrupted && ![MM_SyncManager sharedManager].hasSyncedOnce ) {
        self.cancelButton.hidden = NO;
	}
}

@end
