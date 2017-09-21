//
//  CheckoutReviewViewController.m
//  ios_dsa
//
//  Created by Guy Umbright on 9/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CheckoutReviewViewController.h"
#import "CheckoutReviewCell.h"
#import "DSA_AppDelegate.h"
#import "LeadSearchViewController.h"
#import "CheckinContactSelectorViewController.h"
#import "MMSF_ContentVersion.h"
#import "MMSF_Contact.h"
#import "MMSF_Lead.h"

static UIPopoverController			*s_popoverController = nil;
static CheckoutReviewViewController  *s_controller;

@interface CheckoutReviewViewController()

@property (nonatomic, strong, readwrite) UITextView *notesTextView;

@end

@implementation CheckoutReviewViewController
- (void) dealloc {
	[self removeAsObserver];
}
///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
+ (CheckoutReviewViewController *) controller 
{
    if (s_controller == nil)
    {
        s_controller = [[self alloc] init];
		[s_controller addAsObserverForName: kNotification_DocumentWasRated selector: @selector(ratingsChanged:)];
	}
	return s_controller;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
+ (void) dismissPopover 
{
	[s_popoverController dismissPopoverAnimated: YES];
	s_popoverController = nil;
    s_controller = nil;
}

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
+ (void) popOverFromBarButtonItem: (UIBarButtonItem *) item 
{
	[[self generatePopoverController] presentPopoverFromBarButtonItem: item permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

+ (void) popOverFromButton: (UIButton *) button {
	[[self generatePopoverController] presentPopoverFromRect: button.bounds inView: button permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

+ (UIPopoverController *) generatePopoverController {
	if (s_popoverController) return nil;
	
	CheckoutReviewViewController *controller = [self controller];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: controller];
    
    nav.preferredContentSize = CGSizeMake(550, 600);
    
    // the global tint color makes these difficult to see
    // TODO: revisit tint color and appearance attributes
    nav.navigationBar.tintColor = [UIColor whiteColor];
    //nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: nav];
	
	s_popoverController.delegate = (id<UIPopoverControllerDelegate>) controller;
    
	return s_popoverController;
}

#pragma mark Popover Stuff
///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController 
{
    s_popoverController = nil;
    s_controller = nil;
}

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:CHECKOUT_POPOVER_PRESENTED
                                                        object:self];
    [self.view setBackgroundColor: [UIColor whiteColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactSelectedAtCheckout:)
                                                 name:kContactSelectedAtCheckout
                                               object:nil];

    self.tableView.rowHeight = 120;
    self.title = @"Review Materials";
	self.tableView.accessibilityLabel = @"Rating List";

    UIBarButtonItem *rightButton    = nil;

    if (!g_appDelegate.currentTrackingEntity) {
        NSString *buttonTitle = nil;
        if (g_appDelegate.currentTrackingType == DocumentTracking_DeferredContact)
            buttonTitle = @"Choose Contact";
        else if (g_appDelegate.currentTrackingType == DocumentTracking_DeferredLead)
            buttonTitle = @"Choose Lead";
        
        rightButton = [[UIBarButtonItem alloc] initWithTitle: buttonTitle
                                                       style: UIBarButtonItemStyleBordered
                                                      target: self
                                                      action: @selector(chooseEntityPressed:)];
    }
    else {
        
        rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                    target: self
                                                                    action: @selector(donePressed:)];
    }
    [self.navigationItem setRightBarButtonItem: rightButton];
    [self.navigationItem.rightBarButtonItem setTintColor: [Branding blueColor]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.allowsSelection = NO;
    
    // Notes as custom header of the tableview
    // Headerview -- frame is hardcoded to match the popover size
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 550.0, 190.0)];
    
    UILabel *notesLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 20.0, 510.0, 20.0)];
    notesLabel.text = @"Notes";
    notesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
    notesLabel.textAlignment = NSTextAlignmentCenter;
    
    // place UITextView below the label
    self.notesTextView = [[UITextView alloc] initWithFrame:CGRectMake(20.0, 60.0, 510.0, 100.0)];
    self.notesTextView.font = [UIFont fontWithName:@"Helvetica" size:18.0];
    self.notesTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.notesTextView.keyboardType = UIKeyboardAppearanceDefault;
    self.notesTextView.returnKeyType = UIReturnKeyDone;
    self.notesTextView.delegate = self;
    
    self.notesTextView.accessibilityLabel = @"Notes TextBox";
    self.notesTextView.isAccessibilityElement = YES;

    // setting the border so it looks similar to textfield
    [self.notesTextView.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [self.notesTextView.layer setBorderWidth:1.0];
    
    // Rounded corners
    self.notesTextView.layer.cornerRadius = 8;
    self.notesTextView.clipsToBounds = YES;
    
    NSString *notes = g_appDelegate.documentTracker.checkoutNotes;
    self.notesTextView.text = notes ? notes : @"";
    
    UIView *divider = [[UIView alloc]initWithFrame:CGRectMake(10.0, 180.0, 550.0, 1.0)];
    divider.backgroundColor = [UIColor lightGrayColor];
    
    [headerView addSubview:notesLabel];
    [headerView addSubview:self.notesTextView];
    [headerView addSubview:divider];
    
    //self.tableView.tableHeaderView = headerView;

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CHECKOUT_POPOVER_DISMISSED object:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (CGSize)preferredContentSize {
    return CGSizeMake(550, 600);
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (IBAction) chooseEntityPressed: (id) sender {
    
    DSA_AppDelegate *appDelegate = (DSA_AppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.currentTrackingType == DocumentTracking_DeferredContact) {
        
        CheckinContactSelectorViewController* vc = [[CheckinContactSelectorViewController alloc] init];
        vc.checkoutMode = YES;
        //vc.hideSelectLaterButton=YES;
        [self.navigationController pushViewController:vc animated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: CHECKOUT_POPOVER_PRESENTED object: nil];
    }
    else if (appDelegate.currentTrackingType == DocumentTracking_DeferredLead) {
        
        LeadSearchViewController *viewController = [[LeadSearchViewController alloc] init];
        [viewController setShowsDeferButton: NO];
        [self.navigationController pushViewController: viewController animated: YES];
    }
}
#if 0
- (IBAction) chooseContactPressed:(id)sender {
    CheckinContactSelectorViewController* vc = [[CheckinContactSelectorViewController alloc ] init];
    vc.checkoutMode = YES;
    
    [self.navigationController pushViewController:vc animated:YES];
        
    [[NSNotificationCenter defaultCenter] postNotificationName: CHECKOUT_POPOVER_PRESENTED object: nil];
}
#endif
- (void)contactSelectedAtCheckout:(NSNotification*)notif {
    [self donePressed:nil];
}


- (BOOL) allDocumentsRated {
	for (NSInteger i = 0; i < [g_appDelegate.documentTracker trackedDocumentCount]; i++) {
		DocumentHistory* documentHistory = [g_appDelegate.documentTracker trackedDocumentAtIndex: i];
		
		if (documentHistory.rating <= 0) return NO;
	}
	return YES;
}

- (void) ratingsChanged: (NSNotification *) note {
//	self.navigationItem.rightBarButtonItem.enabled = self.allDocumentsRated;
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (IBAction) donePressed:(id)sender
{
	NSMutableArray			*itemsToSend = [NSMutableArray array];
    g_appDelegate.documentTracker.checkoutNotes = [self.notesTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	for (NSInteger i = 0; i < [g_appDelegate.documentTracker trackedDocumentCount]; i++) {
		DocumentHistory* documentHistory = [g_appDelegate.documentTracker trackedDocumentAtIndex: i];
		
		if (documentHistory.markedToSend) [itemsToSend addObject: documentHistory.salesforceId];
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kCheckoutDone object: itemsToSend];
}

///////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////
- (IBAction) cancelPressed:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName: kCheckoutCanceled object: nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [g_appDelegate.documentTracker trackedDocumentCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DocumentHistory* documentHistory = [g_appDelegate.documentTracker trackedDocumentAtIndex:[indexPath row]];
    MMSF_ContentVersion* contentItem = [MMSF_ContentVersion contentItemBySalesforceId:documentHistory.salesforceId];
    
    CheckoutReviewCell* cell = (CheckoutReviewCell*)[self.tableView dequeueReusableCellWithIdentifier:@"ratingCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CheckoutReviewCell" owner:self options:nil];
        cell = (CheckoutReviewCell *)[nib objectAtIndex:0];
    }
    
    [cell displayDocumentHistory:documentHistory];
    cell.documentTitle.text = contentItem.Title;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    NSString *notes = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (notes.length != 0) {
        g_appDelegate.documentTracker.checkoutNotes = notes;
    }
}

@end
