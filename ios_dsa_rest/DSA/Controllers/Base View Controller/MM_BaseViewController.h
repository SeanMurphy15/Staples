//
//  MM_BaseViewController.h
//  ModelMetrics
//
//  Created by Ben Gottlieb on 2/5/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>


#define DisplayLoginNotification @"com.modelmetrics.dsa.displaylogin"

@interface MM_BaseViewController : UIViewController <SA_PleaseWaitDisplayDelegate> 
{
}

@property (nonatomic, readwrite, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, readwrite, weak) IBOutlet UIToolbar *topToolbar;
@property (nonatomic, readwrite, weak) IBOutlet UIBarButtonItem* logoItem;
@property (nonatomic, readwrite, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *settingsButtonItem;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *syncButton;

+ (id) navController;

- (IBAction) showLoginController: (id) sender;
- (IBAction) synchronize: (id) sender;
- (IBAction) fullSynchronize: (id) sender;

//override for derived classes
- (void) userDidLogOut;

@end
