//
//  ZM_ContactSelectionController.h
//  ModelMetrics
//
//  Created by Ben Gottlieb on 9/7/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LeadsSearchController.h"

@class MMSF_ContentVersion;
@class DSA_ContactSelectionController;

@protocol DSA_ContactSelectionControllerDelegate

@required
- (void) contactSelectionControllerSendPressed: (DSA_ContactSelectionController*) contactSelectionController;
- (void) contactSelectionControllerCancelPressed: (DSA_ContactSelectionController*) contactSelectionController;

@end

@interface DSA_ContactSelectionController : UIViewController <LeadsSearchControllerDelegate> {
}

@property (nonatomic, readwrite, weak) IBOutlet UITableView *allContactsTableView;
@property (nonatomic, readwrite, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, readwrite, weak) IBOutlet UIBarButtonItem* emailButton;
@property (nonatomic, weak) IBOutlet UIView* demoOverlay;
@property (nonatomic, weak) IBOutlet UITextField* emailAddress;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *loadingLabel;

@property (nonatomic, readwrite, strong) MMSF_ContentVersion *item;
//@property (nonatomic, readwrite, retain) NSMutableArray *allContacts, *selectedContacts, *masterContacts;
@property (unsafe_unretained, nonatomic, readonly) NSArray *selectedContacts;
@property (unsafe_unretained, nonatomic, readonly) NSString* demoEmailAddress;
@property (nonatomic, unsafe_unretained) NSObject<DSA_ContactSelectionControllerDelegate>* contactSelectionDelegate;
@property (nonatomic, strong) NSString *pendingSearchString, *currentSearchString;
@property (atomic, assign) BOOL isTableViewRefreshCompleted;

+ (id) controllerToMailContentItem: (MMSF_ContentVersion *) item;


- (IBAction) cancel;
- (IBAction) sendEmail;

@end
