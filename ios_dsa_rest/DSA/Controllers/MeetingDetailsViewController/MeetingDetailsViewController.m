//
//  MeetingDetailsViewController.m
//  DSA
//
//  Created by Jason Barker on 5/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "MeetingDetailsViewController.h"
#import "CheckinContactSelectorViewController.h"
#import "CheckoutReviewViewController.h"
#import "DSA_AppDelegate.h"
#import "LeadSearchViewController.h"


static NSString* sEnteredMeetingNotes = nil;

@interface MeetingDetailsViewController () {
    
    NSMutableArray  *_selectedPainPoints;
    NSDictionary    *_allSwitches;
}

@end



@implementation MeetingDetailsViewController

+ (void) resetMeetingNotes
{
    sEnteredMeetingNotes = nil;
}

/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if (self) {
        
        [self setTitle: @"Meeting Notes"];
        
        _selectedPainPoints = [[NSMutableArray alloc] init];
    }
    
    return self;
}


/**
 *
 */
- (void) viewDidLoad {
    
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    _allSwitches = @{@"Accounting":             self.accountingSwitch,
                     @"Account Management":     self.accountManagementSwitch,
                     @"Customer Service":		self.customerServiceSwitch,
                     @"Invoicing":              self.invoicingSwitch,
                     @"Multiple Vendors":		self.multipleVendorsSwitch,
                     @"Ordering":				self.orderingSwitch,
                     @"Placement Method":		self.placementMethodSwitch,
                     @"Pricing":				self.pricingSwitch,
                     @"Procurement":			self.procurementSwitch,
                     @"Product Assortment":     self.productAssortmentSwitch,
                     @"Reporting":              self.reportingSwitch,
                     @"Shipping / Receiving":	self.shippingReceivingSwitch};
}

/**
 *
 */
- (void) viewWillAppear: (BOOL) animated {
    
    [super viewWillAppear: animated];
    
    DSA_AppDelegate *appDelegate = (DSA_AppDelegate *) [[UIApplication sharedApplication] delegate];
    if (appDelegate.documentTracker.trackedDocumentCount > 0) {
        
        UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle: @"Next"
                                                                       style: UIBarButtonItemStylePlain
                                                                      target: self
                                                                      action: @selector(showRatings:)];
        [self.navigationItem setRightBarButtonItem: nextButton];
    }
    else if (appDelegate.currentTrackingType == DocumentTracking_DeferredContact) {
        
        UIBarButtonItem *chooseButton = [[UIBarButtonItem alloc] initWithTitle: @"Choose Contact"
                                                                         style: UIBarButtonItemStylePlain
                                                                        target: self
                                                                        action: @selector(chooseEntity:)];
        [self.navigationItem setRightBarButtonItem: chooseButton];
    }
    else if (appDelegate.currentTrackingType == DocumentTracking_DeferredLead) {
        
        UIBarButtonItem *chooseButton = [[UIBarButtonItem alloc] initWithTitle: @"Choose Lead"
                                                                         style: UIBarButtonItemStylePlain
                                                                        target: self
                                                                        action: @selector(chooseEntity:)];
        [self.navigationItem setRightBarButtonItem: chooseButton];
    }
    else {
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle: @"Done"
                                                                       style: UIBarButtonItemStylePlain
                                                                      target: self
                                                                      action: @selector(completeCheckout:)];
        [self.navigationItem setRightBarButtonItem: doneButton];
    }
    
    if (sEnteredMeetingNotes != nil)
    {
        self.notesTextView.text = sEnteredMeetingNotes;
        sEnteredMeetingNotes = nil;
        [self.notesPlaceholderLabel setHidden: YES];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    sEnteredMeetingNotes = nil;
    if (self.notesTextView.text != nil && self.notesTextView.text.length > 0)
    {
        sEnteredMeetingNotes = [self.notesTextView.text copy];
    }
}

/**
 *
 */
- (void) didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -


/**
 *
 */
- (void) saveUserInput {
    
    DSA_AppDelegate *appDelegate = (DSA_AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate setCurrentPainPoints: [NSArray arrayWithArray: _selectedPainPoints]];
    [appDelegate setCurrentMeetingNotes: _notesTextView.text];
    _notesTextView.text = nil;
}


#pragma mark - Actions


/**
 *
 */
- (IBAction) chooseEntity: (id) sender {
    
    [self saveUserInput];
    
    DSA_AppDelegate *appDelegate = (DSA_AppDelegate *) [[UIApplication sharedApplication] delegate];
    if (appDelegate.currentTrackingType == DocumentTracking_DeferredContact) {
        
        CheckinContactSelectorViewController* vc = [[CheckinContactSelectorViewController alloc] init];
        vc.checkoutMode = YES;
        vc.hideChooseLaterButton=YES;  
        [self.navigationController pushViewController:vc animated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: CHECKOUT_POPOVER_PRESENTED object: nil];
    }
    else if (appDelegate.currentTrackingType == DocumentTracking_DeferredLead) {
        
        LeadSearchViewController *viewController = [[LeadSearchViewController alloc] init];
        [viewController setShowsDeferButton: NO];
        [self.navigationController pushViewController: viewController animated: YES];
    }
}


/**
 *
 */
- (IBAction) completeCheckout: (id) sender {
    
    [self saveUserInput];
    [[NSNotificationCenter defaultCenter] postNotificationName: kCheckoutDone object: nil];
}


/**
 *
 */
- (IBAction) showRatings: (id) sender {
    
    [self saveUserInput];
    
    CheckoutReviewViewController *viewController = [[CheckoutReviewViewController alloc] init];
    [self.navigationController pushViewController: viewController animated: YES];
}


/**
 *
 */
- (IBAction) flippedSwitch: (id) sender {
    
    if (self.notesTextView.isFirstResponder)
        [self.notesTextView resignFirstResponder];
    
    NSArray *switches = [_allSwitches allKeysForObject: sender];
    if (switches.count > 0) {
        
        NSString *name = switches.firstObject;
        if ([_selectedPainPoints containsObject: name])
            [_selectedPainPoints removeObject: name];
        else
            [_selectedPainPoints addObject: name];
        
    }
}


#pragma mark - UITextViewDelegate messages


/**
 *
 */
- (void) textViewDidBeginEditing:(UITextView *)textView {
    
    [self.notesPlaceholderLabel setHidden: YES];
}


/**
 *
 */
- (void) textViewDidEndEditing:(UITextView *)textView {
    
    if (textView.text.length > 0) {
        [self.notesPlaceholderLabel setHidden: YES];
    }
    else {
        [self.notesPlaceholderLabel setHidden: NO];
    }
}


@end
