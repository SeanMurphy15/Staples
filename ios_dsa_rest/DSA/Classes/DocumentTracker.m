//
//  DocumentTracker.m
//  ios_dsa
//
//  Created by Guy Umbright on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DocumentTracker.h"
#import "MMSF_ContentVersion.h"
#import "MM_SFChange.h"
#import "DSA_AppDelegate.h"
#import "MMSF_Contact.h"
#import "CLLocationManager+DSA.h"
#import "MMSF_Lead.h"

#define kHoldPushUntilChangesCount  10
#define kContentReviewSubmitted @"com.modelmetrics.dsa.contentReviewSubmitted"


#pragma mark - DocumentHistory

@implementation DocumentHistory

/////////////////////////////////////////
//
/////////////////////////////////////////
- (id) init
{
    self = [super init];
    if (self != nil)
    {
        self.sequence = 0;
        self.totalSecondsViewed = 0;
        self.viewCount = 0;
        self.markedToSend = NO;
    }
    
    return self;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSInteger) incrementViewCount {
    ++_viewCount;
    return self.viewCount;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSString*) description
{
    return [NSString stringWithFormat:@"sfid: %@, viewcount: %ld, totalSecondsViewed: %f, markedToSend: %u, sequence: %lu",self.salesforceId,(long)self.viewCount,self.totalSecondsViewed,self.markedToSend,(unsigned long)self.sequence];
}
@end

#pragma mark - DocumentTracker

@interface DocumentTracker ()
@property (nonatomic, strong) CLGeocoder* geocoder;
@property (nonatomic, copy) NSString *currentLocationPlaceMark;
@end

@implementation DocumentTracker

/////////////////////////////////////////
//
/////////////////////////////////////////
- (id) init {
    self = [super init];
    if (self != nil)
    {
        trackedDocuments = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setupLocationManager)
                                                     name:kNotification_SyncComplete
                                                   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startViewingDocument:)
                                                     name:DocumentTrackerStartViewingNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopViewingDocument:) 
                                                     name:DocumentTrackerStopViewingNotification 
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(markToSend:) 
                                                     name:DocumentTrackerMarkToSendNotification 
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(clearMarkToSend:) 
                                                     name:DocumentTrackerClearMarkToSendNotification 
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(didEnterBackground:) 
                                                     name:UIApplicationDidEnterBackgroundNotification 
                                                   object:nil];
                
        
        self.currentDocument = nil;
        currentSequence = 0;
        
		if ([MM_LoginViewController isLoggedIn]) [self setupLocationManager];
    }
    return self;
}

- (void) setupLocationManager {
	if (self.locationManager) return;			//already setup
	self.currentLocationPlaceMark = @"";
	
	self.locationManager = [[CLLocationManager alloc] init];
	[self.locationManager startUpdatingLocation];
	//    [self.locManager stopUpdatingLocation];
	
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.delegate=self;
	[self.locationManager startUpdatingLocation];
	self.geocoder = [[CLGeocoder alloc] init];
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[self.locationManager stopUpdatingLocation];
    
}

- (void)startMonitoringLocation {
    // iOS 8 goodness
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        // asynchronous, startUpdatingLocation is called from delegate
        [self.locationManager performSelector:@selector(requestWhenInUseAuthorization)];
    } else {
        // if the user allows location services, start reporting
        if ([CLLocationManager locationServicesAllowed]) {
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (void) startViewingDocument:(NSNotification*) note {
    NSString *selectedId = note.object;
    MMSF_ContentVersion *item = [MMSF_ContentVersion contentItemBySalesforceId:selectedId];
    
    [self startMonitoringLocation];

    DocumentHistory* history = [trackedDocuments objectForKey:item.Id];
    if (history == nil)
    {
        history = [[DocumentHistory alloc] init];
        history.salesforceId = item.Id;
        history.sequence = currentSequence++;
        [trackedDocuments setObject:history forKey:item.Id];
    }
    
	if (self.checkInStart == nil) {
        self.checkInStart = [NSDate date];
    }
    self.currentDocument = history;
    
    [self.currentDocument incrementViewCount];
    self.currentDocumentStart = [NSDate date];  
        
    MMLog(@"Start tracking %@",item.Title);
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (void) stopViewingDocument:(NSNotification*) notification {
    self.stopTime = [NSDate date];
    if (self.currentDocument != nil)
    {
        NSTimeInterval diff = [self.stopTime timeIntervalSinceDate:self.currentDocumentStart];
        
        self.currentDocument.totalSecondsViewed += diff;
        //self.currentDocumentStart = nil;
        self.currentDocument = nil;
    }
    
	if (g_appDelegate.currentTrackingType == DocumentTracking_AlwaysOn && self.trackedDocumentCount > 0) {
        [self createReviewObjects];
    }
        
    MMLog(@"%@", @"Stop tracking");
}


- (void) addMailedToContactIDs: (NSArray *) contactIDs leadIDs: (NSArray *) leadIDs forDocumentID: (NSString *) documentID {
    DocumentHistory* history = [trackedDocuments objectForKey: documentID];
	
	history.markedToSend = YES;
	history.mailedToContactIDs = contactIDs;
    history.mailedToLeadIDs = leadIDs;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (void) markToSend:(NSNotification*) notification
{
    if (self.currentDocument == nil) {
        DocumentHistory* hist = [trackedDocuments objectForKey:(NSString*) notification.object];
        if (hist != nil)
        {
            hist.markedToSend = YES;
        }
    }else {
        self.currentDocument.markedToSend = YES;
        
    }
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (void) clearMarkToSend:(NSNotification*) notification
{
    if (self.currentDocument == nil) {
        DocumentHistory* hist = [trackedDocuments objectForKey:(NSString*) notification.object];
        if (hist != nil)
        {
            hist.markedToSend = NO;
        }
    }else {
        self.currentDocument.markedToSend = NO;
        
    }
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (void) didEnterBackground:(NSNotification*) notification
{
	if ([MM_SyncManager sharedManager].hasSyncedOnce) [self stopViewingDocument:nil];
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSUInteger) trackedDocumentCount
{
    return [trackedDocuments count];
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (DocumentHistory*) trackedDocumentAtIndex:(NSUInteger) index
{
    DocumentHistory* matchingHistory = nil;
    
    if (index < [self trackedDocumentCount])
    {
        for (DocumentHistory* dh in [trackedDocuments allValues])
        {
            if (dh.sequence == index)
            {
                matchingHistory = dh;
                break;
            }
        }
    }
    
    return matchingHistory;
}

- (MMSF_ContentVersion *)createReviewObjectWithContact:(MMSF_Contact*)contact history:(DocumentHistory*)reviewedContent {
    NSManagedObjectContext *reviewContext = [MM_ContextManager sharedManager].threadContentContext;
    MMSF_Object *reviewObject = [reviewContext insertNewEntityWithName:@"ContentReview__c"];
    [reviewObject beginEditing];
    MMSF_ContentVersion* contentItem = [MMSF_ContentVersion contentItemBySalesforceId:reviewedContent.salesforceId];
    
    reviewObject[MNSS(@"ContentTitle__c")] = contentItem.Title;
    
    if (contact) {
        MMSF_Contact *reviewContact = [contact objectInContext:reviewContext];
        reviewObject[MNSS(@"ContactId__c")] = reviewContact;
    }
    reviewObject[MNSS(@"Rating__c")] = @(reviewedContent.rating);
    reviewObject[MNSS(@"Document_Emailed__c")] = @(reviewedContent.markedToSend);
    reviewObject[MNSS(@"TimeViewed__c")] = @(reviewedContent.totalSecondsViewed);
    reviewObject[MNSS(@"ContentId__c")] = contentItem.documentID;
    
    if ([reviewObject hasValueForKeyPath: MNSS(@"Geolocation__Longitude__s")] && [reviewObject hasValueForKeyPath: MNSS(@"Geolocation__Latitude__s")]) {
        reviewObject[MNSS(@"Geolocation__Latitude__s")] = @(self.current.coordinate.latitude);
        reviewObject[MNSS(@"Geolocation__Longitude__s")] = @(self.current.coordinate.longitude);
    }
    
    [reviewObject finishEditingSavingChanges: YES andPushingToServer: NO];
    
    return contentItem;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSMutableArray *) createReviewObjects
{
    NSMutableArray *itemsToSend = [NSMutableArray array];

    NSMutableArray *titleList = [NSMutableArray array];
    NSManagedObjectContext *reviewContext = [MM_ContextManager sharedManager].threadContentContext;
    //MMSF_Contact *reviewContact = [g_appDelegate trackingContactInContext:reviewContext];    // may be nil

    self.checkInEnd = [NSDate date];

    NSLog(@"starting reviews");
    
	for (NSString *key in trackedDocuments.copy) {
		DocumentHistory* docHist = trackedDocuments[key];
        NSString        *entityName     = nil;

        // should the history store the Contact?
		NSArray	*identifiers = nil;
        if(g_appDelegate.currentTrackingEntity != nil)
        {
            identifiers = @[g_appDelegate.currentTrackingEntity];
            
            if ([g_appDelegate.currentTrackingEntity isKindOfClass: [MMSF_Contact class]])
                entityName = [MMSF_Contact entityName];
            else if ([g_appDelegate.currentTrackingEntity isKindOfClass: [MMSF_Lead class]])
                entityName = [MMSF_Lead entityName];
            
            [self createContentReviewOfHistory: docHist
                                forIdentifiers: identifiers
                                        ofType: entityName
                                     inContext: reviewContext];
            
        } else
        {
            identifiers = docHist.mailedToContactIDs;
            entityName = [MMSF_Contact entityName];
            
            [self createContentReviewOfHistory: docHist
                                forIdentifiers: identifiers
                                        ofType: entityName
                                     inContext: reviewContext];
            
            identifiers = docHist.mailedToLeadIDs;
            entityName = [MMSF_Lead entityName];
            
            [self createContentReviewOfHistory: docHist
                                forIdentifiers: identifiers
                                        ofType: entityName
                                     inContext: reviewContext];
        }

        MMSF_ContentVersion *contentItem    = [MMSF_ContentVersion contentItemBySalesforceId: docHist.salesforceId];
        [itemsToSend addObject:contentItem.Id];
        [titleList addObject:contentItem.Title];
        
#if 0 //4.0 version
        if (!identifiers && g_appDelegate.currentTrackingType == DocumentTracking_AlwaysOn) {
            MMSF_ContentVersion *reviewedContent = [self createReviewObjectWithContact:nil history:docHist];
            if (reviewedContent) {
                [itemsToSend addObject:reviewedContent.Id];
                [titleList addObject:reviewedContent.Title];
            }
        } else {
            for (NSString *contactID in identifiers) { //!!!identifiers could be lead, yes?
                MMSF_Contact *contact = [reviewContext anyObjectOfType: [MMSF_Contact entityName] matchingPredicate: $P(@"Id == %@", contactID)];
                MMSF_ContentVersion *reviewedContent = [self createReviewObjectWithContact:contact history:docHist];
                if (reviewedContent) {
                    [itemsToSend addObject:reviewedContent.Id];
                    [titleList addObject:reviewedContent.Title];
                }
            }
        }
#endif
        [trackedDocuments removeObjectForKey: key];
	}
    
	if (g_appDelegate.currentTrackingEntity != nil) {
		MMSF_Object *event = [reviewContext insertNewEntityWithName:@"Event"];
		[event beginEditing];
        
		[event setValue:@"DSA Presentation" forKey:@"Subject"];
		[event setValue: self.checkInStart ?: self.checkInEnd forKey:@"StartDateTime"];
		[event setValue:self.checkInEnd forKey:@"EndDateTime"];
		event[@"DurationInMinutes"] = @(self.checkInStart ? ABS([self.checkInEnd timeIntervalSinceDate: self.checkInStart]) / 60 : 0);
		[event setValue:g_appDelegate.currentTrackingEntity forKey:@"WhoId"];
        //[event setValue:g_appDelegate.currentTrackingEntity.AccountId forKey:@"WhatId"];

        // Description contatins a list of presented documents and, optionally, notes entered at Checkout
         NSString *description = [NSString stringWithFormat:@"Presented the following documents using DSA application: %@", [titleList componentsJoinedByString:@", "]];
         if (g_appDelegate.documentTracker.checkoutNotes.length > 0) {
             description = [NSString stringWithFormat:@"%@; Notes: %@", description, g_appDelegate.documentTracker.checkoutNotes];
         }

        DSA_AppDelegate *appDelegate = (DSA_AppDelegate *) [[UIApplication sharedApplication] delegate];
        
        NSMutableString *eventDescription = [NSMutableString stringWithString: @"Presented the following documents using DSA application: "];
        
        if (titleList.count > 0)
            [eventDescription appendString: [titleList componentsJoinedByString: @", "]];
        else
            [eventDescription appendString: @"NONE"];
        
        
        if (appDelegate.currentPainPoints.count > 0) {
            
            [eventDescription appendString: @"\r\n\r\n"];
            [eventDescription appendFormat: @"The following pain points were identified: %@", [appDelegate.currentPainPoints componentsJoinedByString: @", "]];
        }
        
        if (appDelegate.currentMeetingNotes.length > 0) {
            
            [eventDescription appendString: @"\r\n\r\n"];
            [eventDescription appendFormat: @"Other notes: %@", appDelegate.currentMeetingNotes];
        }
        event[@"Description"] = eventDescription;
        
		[event setValue:self.currentLocationPlaceMark forKey:@"Location"];
		
		[event finishEditingSavingChanges:YES];
		[MM_SFChange pushPendingChangesWithCompletionBlock: nil];
	} else {
        // postpone Review push until number of changes exceeds threshold
		if ([MM_SFChange numberOfPendingChanges] >= kHoldPushUntilChangesCount) {
            [MM_SFChange pushPendingChangesWithCompletionBlock: nil];
        }
	}

    return itemsToSend;
}


/**
 *
 */
- (void) createContentReviewOfHistory: (DocumentHistory *) docHist forIdentifiers: (NSArray *) identifiers ofType: (NSString *) entityName inContext: (NSManagedObjectContext *) context {
    
    for (id identifier in identifiers) {
        
        MMSF_Object         *entity         = nil;
        MMSF_ContentVersion *contentItem    = [MMSF_ContentVersion contentItemBySalesforceId: docHist.salesforceId];
        
        if ([identifier isKindOfClass: [NSString class]])
            entity = [context anyObjectOfType: entityName matchingPredicate: $P(@"Id == %@", identifier)];
        else if ([identifier isKindOfClass: [MMSF_Object class]])
            entity = identifier;
        
        MMSF_Object *reviewObject = [context insertNewEntityWithName:@"ContentReview__c"];
        [reviewObject beginEditing];
        [reviewObject setValue:contentItem.Title forKey:MNSS(@"ContentTitle__c")];
        
        if ([entityName isEqualToString: [MMSF_Contact entityName]])
            reviewObject[MNSS(@"ContactId__c")] = entity;
        else if ([entityName isEqualToString: [MMSF_Lead entityName]])
            reviewObject[@"Lead__c"] = entity;
        
        reviewObject[MNSS(@"Rating__c")] = @(docHist.rating);
        reviewObject[MNSS(@"Document_Emailed__c")] = @(docHist.markedToSend);
        reviewObject[MNSS(@"TimeViewed__c")] = @(docHist.totalSecondsViewed);
        reviewObject[MNSS(@"ContentId__c")] = contentItem.documentID;
        
        if ([reviewObject hasValueForKeyPath: MNSS(@"Geolocation__Longitude__s")] && [reviewObject hasValueForKeyPath: MNSS(@"Geolocation__Latitude__s")]) {
            reviewObject[MNSS(@"Geolocation__Latitude__s")] = @(self.current.coordinate.latitude);
            reviewObject[MNSS(@"Geolocation__Longitude__s")] = @(self.current.coordinate.longitude);
        }
        
        [reviewObject finishEditingSavingChanges: YES andPushingToServer: NO];
    }
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (NSArray*) itemsToSend
{
    NSMutableArray* result = [NSMutableArray array];
    
    for (DocumentHistory* dh in [trackedDocuments allValues])
    {
        if (dh.markedToSend)
        {
            [result addObject:dh.salesforceId];
        }
    }
    
    return result;
}

/////////////////////////////////////////
//
/////////////////////////////////////////
- (BOOL) documentMarkedToSendAsEmail:(NSString*) sfid
{
    DocumentHistory* hist = [trackedDocuments objectForKey:sfid];
	return hist.markedToSend;
}

#pragma mark - Core Location Delegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	[manager stopUpdatingLocation];
    
	// Set the current location
	self.current = newLocation;

    [self.geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemark, NSError *error) {
        if (error == nil) {
            CLPlacemark* locationPlacemark = [placemark lastObject];
            self.currentLocationPlaceMark = [[locationPlacemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@","];
        }
        else {
            MMLog(@"Reverse geocoder error: %@", [error description]);
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if ([CLLocationManager locationServicesAllowed]) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	MMLog(@"Location manager error: %@",[error description]);
    
    if ([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorDenied) {
        // Access to location or ranging has been denied by the user
        [manager stopUpdatingLocation];
    }
}

@end
