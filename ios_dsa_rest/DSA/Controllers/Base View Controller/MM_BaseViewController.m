//
//  MM_BaseViewController.m
//  ModelMetrics
//
//  Created by Ben Gottlieb on 2/5/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "MM_BaseViewController.h"
#import "DSA_AppDelegate.h"
#import "DSA_SettingsMenuViewController.h"
#import "ZM_SearchResultsController.h"
#if APP_STORE_BUILD
#import "DSA_DemoLoginViewController.h"
#endif
#import "MM_LoginViewController.h"
#import "MM_SyncManager.h"
#import "MMSF_User.h"
#import "MM_Notifications.h"
#import "DSA_ProgressView.h"

@implementation MM_BaseViewController 

@synthesize topToolbar, navigationBar, searchBar, syncButton, settingsButtonItem;
@synthesize logoItem;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(displayLogin:) 
                                                     name:DisplayLoginNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(didLogOut:) 
                                                     name: kNotification_DidLogOut 
                                                   object: nil];
        
#if APP_STORE_BUILD
        [[NSNotificationCenter defaultCenter] addObserver: self 
                                                 selector: @selector(loginViewDismissed:) 
                                                     name: kNotification_LoginViewDismissed 
                                                   object: nil];

#endif    
        
        
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (id) controller {
	return nil;
}

+ (id) navController {
	UIViewController			*controller = [self controller];
	UINavigationController		*navController = [[[UINavigationController alloc] initWithRootViewController: controller] autorelease];
	
	navController.tabBarItem = controller.tabBarItem;
	[navController setNavigationBarHidden: YES];
	return navController;
}


//=============================================================================================================================
#pragma mark Setup
- (void) viewDidLoad {
	UIGestureRecognizer			*holdGesture = [[[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(fullSynchronize:)] autorelease];
	
	[self.syncButton addGestureRecognizer: holdGesture];
	[super viewDidLoad];
}

- (void) viewDidAppear: (BOOL) animated {
	[super viewDidAppear: animated];
}

- (void) viewWillDisappear: (BOOL) animated {
	[super viewWillDisappear: animated];
	[self.navigationController setNavigationBarHidden: YES animated: YES];
}

//=============================================================================================================================
#pragma mark Notifications
- (void) userDidLogOut
{
    //this is an overriable method for derived classes.  
}

- (void) didLogOut: (NSNotification *) note {
	[g_appDelegate login];
}

#if APP_STORE_BUILD
- (void) loginViewDismissed: (NSNotification *) note 
{
    searchBar.text=nil;
	if (self.settingsButtonItem)  [self performSelector: @selector(showLoginController:) withObject: self.settingsButtonItem afterDelay: 0.1];
}

#endif

//=============================================================================================================================
#pragma mark Actions
- (IBAction) showLoginController: (id) sender {

}

- (void) pleaseWaitCancelPressed {
	[[SA_ConnectionQueue sharedQueue] cancelAllConnections];
	[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
}

- (IBAction) synchronize: (id) sender {
	#if PERFORM_FAKE_SYNC
		NSString				*lastDownloadDateKey = @"lastDownloadDateKey";
		
		[SA_PleaseWaitDisplay showPleaseWaitDisplayWithMajorText: @"Synchronizing…" minorText: @"Looking for Changes…" cancelLabel: @"Cancel" showProgressBar: NO delegate: self];
		SA_Connection				*checkConnection = [SA_Connection connectionWithURL: $U(@"http://mm-ipadcontent.s3.amazonaws.com/about/epoch.txt") completionBlock: ^(SA_Connection *incoming, int resultCode, id error) {
			NSTimeInterval				time = [incoming.dataString intValue];
			NSDate						*modDate = [NSDate dateWithTimeIntervalSince1970: time];
			NSDate						*lastDownloadDate = [[NSUserDefaults standardUserDefaults] objectForKey: lastDownloadDateKey];
			
			if (lastDownloadDate == nil || [lastDownloadDate laterDate: modDate] == modDate) {
				SF_ContentItem				*aboutItem = [[SF_Store store].context anyObjectOfType: [SF_ContentItem entityName] matchingPredicate: $P(@"title == 'About This App'")];
				SA_Connection				*downloadConnection = [SA_Connection connectionWithURL: $U(@"http://mm-ipadcontent.s3.amazonaws.com/about/About_This_App.pdf") completionBlock: ^(SA_Connection *incoming, int resultCode, id error) {
					[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
					
					
					[[NSUserDefaults standardUserDefaults] setObject: modDate forKey: lastDownloadDateKey];
					[[NSUserDefaults standardUserDefaults] synchronize];
					
					[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ContentItemDownloaded object: aboutItem];
				}];
				
				[SA_PleaseWaitDisplay pleaseWaitDisplay].minorText = @"Downloading New Content…";
				downloadConnection.filename = aboutItem.fullPath;
				[[SA_ConnectionQueue sharedQueue] queueConnection: downloadConnection];
			} else 
				[NSObject performBlock: ^{ [SA_PleaseWaitDisplay hidePleaseWaitDisplay]; } afterDelay: 1.0];
			
		}];
		[[SA_ConnectionQueue sharedQueue] queueConnection: checkConnection];
	#else
		[g_appDelegate refreshUser: nil];
	#endif
}


- (IBAction) fullSynchronize: (id) sender 
{
	#if PERFORM_FAKE_SYNC
		return;
	#endif
}

//=============================================================================================================================

#pragma mark Search Delegate
- (void) searchBarSearchButtonClicked: (UISearchBar *) inSearchBar {
    
    //To Fix; Defect ID:2618016
    if (![MMSF_User currentUser].isLoggedIn ) {
        return;
    }
    
	NSString				*searchString = inSearchBar.text;
	NSArray					*results = nil;
	Class					resultsClass = [ZM_SearchResultsController class];
	NSPredicate				*predicate = nil;
	
    predicate = [NSPredicate predicateWithFormat: @"(Title CONTAINS[c] %@ OR TagCsv CONTAINS[c] %@)", searchString, searchString];
    
    results = [[MMSF_User currentUser] allDocumentsMatchingPredicate:predicate];
    
	if (results.count) {
		[self.navigationController pushViewController: [resultsClass controllerWithSearchString: searchString andResults: results] animated: YES];
	} else {
		[SA_AlertView showAlertWithTitle: @"Sorry, your search turned up no results." message: nil];
	}
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

//#pragma mark Search Delegate
//- (void) searchBarSearchButtonClicked: (UISearchBar *) inSearchBar {
//    
//    //To Fix; Defect ID:2618016
//    if (![MMSF_User currentUser].isLoggedIn ) {
//        return;
//    }
//    
//	NSString				*searchString = inSearchBar.text;
//	NSArray					*results = nil;
//	Class					resultsClass = [ZM_SearchResultsController class];
//	NSPredicate				*predicate = nil;
//	
//	predicate = [NSPredicate predicateWithFormat: @"(title CONTAINS[c] %@ OR tags CONTAINS[c] %@) && ((documentType == nil) OR (documentType != 'Competitive Information'))", searchString, searchString];
//    results = [[MMSF_User currentUser] allDocumentsMatchingPredicate:predicate];
//    //MMSF_Category__c *obj;
//	//results = [obj allDocumentsMatchingPredicate:predicate includingSubCategories:YES];
//	
//    NSLog(@"results are !!!!!!!!!!!!!!!!!!!!!!!!!!!!! %@",results);
//	if (results.count) {
//		[self.navigationController pushViewController: [resultsClass controllerWithSearchString: searchString andResults: results] animated: YES];
//	} else {
//		[SA_AlertView showAlertWithTitle: @"Sorry, your search turned up no results." message: nil];
//	}
//}


- (void) displayLogin:(NSNotification*) notification
{
	if (self.topToolbar.window) 
    {
        [g_appDelegate login]; 
    }
}



@end
