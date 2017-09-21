//
//  MobileConfigSelectionViewController.h
//  ios_dsa
//
//  Created by Guy Umbright on 10/25/11.
//  Copyright (c) 2011 Kickstand Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMSF_MobileAppConfig__c.h"

@class MobileConfigSelectionViewController;

@protocol MobileConfigSelectionViewControllerDelegate

- (void) mobileConfigSelectionCanceled:(MobileConfigSelectionViewController*) mobileConfigSelectionViewController;
- (void) mobileConfigSelected:(MMSF_MobileAppConfig__c*) config controller:(MobileConfigSelectionViewController*)mobileConfigSelectionViewController;

@end

@interface MobileConfigSelectionViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITableView* table;
@property (nonatomic, strong) IBOutlet UINavigationBar* navBar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* cancelButton;
@property (nonatomic, assign) BOOL allowCancel;
@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) NSArray *configs;

@property (nonatomic, unsafe_unretained) NSObject<MobileConfigSelectionViewControllerDelegate>* mobileConfigSelectorDelegate;

- (IBAction) cancelPressed:(id) sender;

@end
