//
//  DSA_AppDelegate.h
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright Stand Alone, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentItemHistory.h"
#import "DocumentTracker.h"
#import "MMSF_MobileAppConfig__c.h"
#import "MM_LoginViewController.h"

@class DSA_BaseTabsViewController;
@class DocumentTracker;
@class MMSF_Contact;
@class MMSF_MobileAppConfig__c;
@class MMSF_Lead;

typedef NS_ENUM(UInt8, DocumentTrackingType) {
	DocumentTracking_None,
	DocumentTracking_SelectedContact,
	DocumentTracking_DeferredContact,
    DocumentTracking_SelectedLead,
    DocumentTracking_DeferredLead,
	DocumentTracking_AlwaysOn
};

@interface DSA_AppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
	DSA_BaseTabsViewController			*_baseViewController;
    UIWindow							*_window;
    ContentItemHistory*                 _contentItemHistory;
#if TIME_LIMITED_DEMO
    UIAlertView*   demoExpiredAlert;
#endif
    
}

@property (unsafe_unretained, nonatomic, readonly) UINavigationController *topNavigationController;
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet DSA_BaseTabsViewController *baseViewController;
@property (nonatomic, strong) UINavigationController *introViewController;

@property (unsafe_unretained, nonatomic, readonly) ContentItemHistory* contentItemHistory; //???

@property (nonatomic, strong) DocumentTracker *documentTracker;
@property (nonatomic) BOOL enableDocumentTrackingWithoutCheckIn;
@property (nonatomic) DocumentTrackingType currentTrackingType;
//@property (nonatomic, assign) BOOL isTrackingContact;
@property (nonatomic, strong) MMSF_Object   *currentTrackingEntity;
@property (nonatomic, copy) NSString        *currentMeetingNotes;
@property (nonatomic, copy) NSArray         *currentPainPoints;
@property (nonatomic, readonly) BOOL inInternalMode;
@property (nonatomic, strong) NSOperationQueue *contentUpdateCheckQueue;

- (void) logout;
- (void) login;
- (void) showDSAUserOrg;

- (IBAction) refreshUser: (id) sender;
- (IBAction) confirmLogOut: (id) sender;
- (IBAction) refreshUserWithConfirmation;
- (void) clearCurrentUser;

- (void) startDocumentTrackingForContact:(MMSF_Contact*) documentTrackingContact;
- (void) startDocumentTrackingForLead: (MMSF_Lead *) lead;
- (void) stopDocumentTrackingForEntity: (MMSF_Object *) entity;
- (MMSF_Contact*)trackingContactInContext:(NSManagedObjectContext *)context;
//- (void) setTrackingContact:(MMSF_Contact*)contact;
- (BOOL) isTrackingDocuments;
//- (BOOL) isTrackingContact;

- (MMSF_MobileAppConfig__c*) selectedMobileAppConfig;
- (void)updateNavBarForInternalMode;

@end

extern DSA_AppDelegate		*g_appDelegate;
