//
//  DocumentTracker.h
//  ios_dsa
//
//  Created by Guy Umbright on 6/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#define DocumentTrackerStartViewingNotification @"com.modelmetrics.ios_dsa.startviewingdocument"
#define DocumentTrackerStopViewingNotification @"com.modelmetrics.ios_dsa.stopviewingdocument"
#define DocumentTrackerMarkToSendNotification @"com.modelmetrics.ios_dsa.marktosend"
#define DocumentTrackerClearMarkToSendNotification @"com.modelmetrics.ios_dsa.clearmarktosend"
#define DocumentTrackerAllDocumentsRatedNotification @"com.modelmetrics.ios_dsa.alldocumentsrated"

#pragma mark - DocumentHistory

@interface DocumentHistory : NSObject

@property (nonatomic, strong) NSString* salesforceId;
@property (nonatomic, assign) NSInteger viewCount;
@property (nonatomic, assign) NSTimeInterval totalSecondsViewed;
@property (nonatomic, assign) BOOL markedToSend;
@property (nonatomic, assign) NSUInteger sequence;
@property (nonatomic, assign) NSUInteger rating;
@property (nonatomic, strong) NSArray *mailedToContactIDs;
@property (nonatomic, strong) NSArray *mailedToLeadIDs;

- (NSString*) description;
- (NSInteger) incrementViewCount;

@end

#pragma mark - DocumentTracker

@interface DocumentTracker : NSObject<CLLocationManagerDelegate>
{
    NSMutableDictionary* trackedDocuments;
    NSUInteger currentSequence;
}

@property (nonatomic, strong) CLLocation *current;
@property (nonatomic, strong) NSDate* currentDocumentStart;
@property (nonatomic, strong) NSDate* stopTime;
@property (nonatomic, strong) DocumentHistory* currentDocument;
@property (nonatomic, assign) BOOL allDocumentsRated;
@property (nonatomic, strong) NSDate* checkInStart;
@property (nonatomic, strong) NSDate* checkInEnd;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSString *checkoutNotes;

- (id) init;
- (NSUInteger) trackedDocumentCount;

- (DocumentHistory*) trackedDocumentAtIndex:(NSUInteger) index;
- (NSArray *) createReviewObjects;

- (NSArray*) itemsToSend;

- (BOOL) documentMarkedToSendAsEmail:(NSString*) sfid;
- (void) setupLocationManager;
- (void) addMailedToContactIDs: (NSArray *) contactIDs leadIDs: (NSArray *) leadIDs forDocumentID: (NSString *) documentID;

@end
