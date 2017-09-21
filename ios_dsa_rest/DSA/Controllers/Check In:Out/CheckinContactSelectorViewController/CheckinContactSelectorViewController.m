//
//  CheckinContactSelectorViewController.m
//  ios_dsa
//
//  Created by Guy Umbright on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CheckinContactSelectorViewController.h"
#import "AccountSelectorViewController.h"
#import "CheckInCheckOutConstants.h"
#import "ContactController.h"
#import "MMSF_Contact.h"
#import "MM_ContextManager.h"
#import "ContactsCache.h"
#import "MM_Log.h"
#import "Branding.h"

static UIPopoverController			*s_popoverController = nil;
static dispatch_queue_t				s_fetchQueue = nil;
static CheckinContactSelectorViewController  *s_controller;

@interface CheckinContactSelectorViewController ()
@property (nonatomic, strong) IBOutlet UITableView* table;
@property (nonatomic, strong) IBOutlet UISearchBar* searchBar;
@property (nonatomic, strong) ContactsCache* contactsCache;
@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) RecentContacts* recentContacts;
@property (nonatomic, assign) BOOL isRecentContactsSelected;
@end

@implementation CheckinContactSelectorViewController

+ (CheckinContactSelectorViewController *) controller {
    if (s_controller == nil) {
        s_controller = [[self alloc] init];
	}
	return s_controller;
}

+ (void) dismissPopover {
	[s_popoverController dismissPopoverAnimated: YES];
	s_popoverController = nil;
    s_controller = nil;
}

+ (UIPopoverController*) popOverFromBarButtonItem: (UIBarButtonItem *) item {
	[[self generatePopoverController] presentPopoverFromBarButtonItem: item permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
    return s_popoverController;
}

+ (UIPopoverController*) popOverFromButton: (UIButton *) item {
	[[self generatePopoverController] presentPopoverFromRect: item.bounds inView: item permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
    return s_popoverController;
}

+ (UIPopoverController *) generatePopoverController {
	if (s_popoverController) return nil;
	
	CheckinContactSelectorViewController *controller = [self controller];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: controller];
    nav.navigationBar.barStyle = UIBarStyleDefault;
	s_popoverController = [[UIPopoverController alloc] initWithContentViewController: nav];
	
	s_popoverController.delegate = controller;

    return s_popoverController;
}

- (id)init {
    self = [super initWithNibName:@"CheckinContactSelector" bundle:nil];
    if (self) {
        self.checkoutMode = NO;
        self.isRecentContactsSelected = NO;

		if (s_fetchQueue == nil)
            s_fetchQueue = dispatch_queue_create("fetch_queue", 0);
        UIBarButtonItem *addContactButton = [[UIBarButtonItem alloc] initWithTitle: @"Create Contact"
                                                                             style: UIBarButtonItemStylePlain
                                                                            target: self
                                                                            action: @selector(showAddContactForm:)];
        [self.navigationItem setRightBarButtonItem: addContactButton];
        }
    
    return self;
}

- (void)dealloc {
    if(!self.checkoutMode) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CHECKIN_POPOVER_DISMISSED object:self];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (RecentContacts*) recentContacts {
    if (_recentContacts == nil) {
        _recentContacts = [[RecentContacts alloc] init];
    }
    return _recentContacts;
}

- (void) searchFieldChanged:(NSNotification*) notification {
	[self cancelAndPerformSelector: @selector(performSearch) withObject: nil afterDelay: 0.5];    
}

- (void) performSearch {
    if ([self.searchBar.text isEqualToString:@""]) {
        self.searchString = self.searchBar.text;
        [self.contactsCache clearSearch];
        [self.table reloadData];
        return;
    }
    
    if(![self.searchBar.text isEqualToString: self.searchString]) {
        self.searchString = self.searchBar.text;
        [self.contactsCache search:[self.searchString lowercaseString]];
    }
}

- (void) searchBar: (UISearchBar *) searchBar textDidChange: (NSString *) searchText {
    
    [self cancelAndPerformSelector: @selector(performSearch) withObject: nil afterDelay: 0.5];
//    [NSObject cancelPreviousPerformRequestsWithTarget: self
//                                             selector: @selector(fetchLeads)
//                                               object: nil];
//    
//    [self performSelector: @selector(fetchLeads) withObject: nil afterDelay: 0.4];
}

- (void)updateChooseLater {
    BOOL hideChooseLater = NO;
    
    if (self.checkoutMode) {
        hideChooseLater = YES;
    } else {
        NSUInteger contactCount = 0;
        
        if (self.isRecentContactsSelected) {
            contactCount = self.recentContacts.sortedContacts.count;
        } else {
            contactCount = self.contactsCache.searchContactCount;
        }
        
        hideChooseLater = contactCount == 0 ? YES : NO;
    }
    
    self.chooseLaterButton.hidden = hideChooseLater;
}

- (IBAction) chooseLaterPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName: kCheckInContactDeferred object: nil];

    [CheckinContactSelectorViewController dismissPopover];
}

- (IBAction) cancelPressed:(id)sender {
    [CheckinContactSelectorViewController dismissPopover];
}

- (IBAction) listTypeChanged:(UISegmentedControl*) sender {
    self.searchBar.text = @"";

	if (self.listSelector.selectedSegmentIndex == 1) {
        self.isRecentContactsSelected = YES;
        self.searchBar.hidden = YES;
		self.table.accessibilityLabel = @"Recent Contacts";
		self.table.accessibilityIdentifier = @"Recent Contacts";
	} else {
        self.isRecentContactsSelected = NO;
        self.searchBar.hidden = NO;
		self.table.accessibilityLabel = @"All Contacts";
		self.table.accessibilityIdentifier = @"All Contacts";
	}
	
    [self.table reloadData];
    [self updateChooseLater];
}


/**
 *
 */
- (IBAction) showAddContactForm: (id) sender {
    
    __weak CheckinContactSelectorViewController *weakSelf = self;
    
    ContactController *contactController = [[ContactController alloc] init];
    [contactController setCompletionBlock: ^(BOOL completed) {
        
        [weakSelf.contactsCache loadCache];
        [weakSelf.navigationController popToViewController: weakSelf animated: YES];
    }];

    AccountSelectorViewController *viewController = [[AccountSelectorViewController alloc] init];
    [viewController setContactController: contactController];
    [self.navigationController pushViewController: viewController animated: YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // avoid being hid under nav bar
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CHECKIN_POPOVER_PRESENTED object:self];
    self.title = @"Select Contact";
	self.searchBar.hidden = YES;
	self.listSelector.hidden = YES;
	self.table.hidden = YES;
	
	self.table.accessibilityLabel = @"All Contacts";
	self.table.accessibilityIdentifier = @"All Contacts";
	[self.loadingActivityIndicator startAnimating];
    
    if (!self.checkoutMode) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    }
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchFieldChanged:) name:UITextFieldTextDidChangeNotification object:self.searchField];
    
    _recentContacts = [[RecentContacts alloc] init];
    
    [self.listSelector addTarget:self
                     action:@selector(listTypeChanged:)
           forControlEvents:UIControlEventValueChanged];
    
    
    self.listSelector.selectedSegmentIndex = 0;
    //self.selectLaterButton.hidden =  _hideSelectLaterButton;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsLoaded:)
                                                 name:ContactsCacheNotification_ContactsLoaded
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchComplete:)
                                                 name:ContactsCacheNotification_SearchComplete
                                               object:nil];

    self.contactsCache = [[ContactsCache alloc] init];
    [self.contactsCache loadCache];

    if (self.navigationItem.rightBarButtonItem)
        [self.navigationItem.rightBarButtonItem setTintColor: [Branding blueColor]];
    
    [self.listSelector setTintColor: [Branding blueColor]];
    //[self.searchField setTintColor: [Branding blueColor]];
    
    [self.searchBar setBarTintColor: [Branding lightBlueColor]];

    [self updateChooseLater];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (CGSize)preferredContentSize {
    return CGSizeMake(600, 600);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (self.isRecentContactsSelected) {
        return [self.recentContacts.sortedContacts count];
    }
    else {
        return self.contactsCache.searchContactCount;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self.table dequeueReusableCellWithIdentifier:@"contactcell"];
	
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"contactcell"];
    }
    
    if (self.isRecentContactsSelected)
    {
        MMSF_Contact* contact = [self.recentContacts.sortedContacts objectAtIndex:indexPath.row];
        NSMutableString *name = [NSMutableString string];
        
        if (contact.LastName.length > 0)
            [name appendString: contact.LastName];
        
        if (contact.FirstName.length > 0) {
            
            if (name.length > 0)
                [name appendString: @", "];
            
            [name appendString: contact.FirstName];
        }
        
        if (contact.Email.length > 0) {
            
            if (name.length > 0)
                [name appendString: @" "];
            
            [name appendFormat: @"<%@>", contact.Email];
        }
        
        [cell.textLabel setText: name];
        
        cell.detailTextLabel.text = contact[CONVERT_EXTRA_FIELD_TO_PROPERTY_NAME(@"Account.Name")];
    }
    else {
        NSDictionary* contactDict = [self.contactsCache searchContactAtIndex:indexPath.row];
        cell.textLabel.text = [self.contactsCache nameStringForContact:contactDict];
        
        cell.detailTextLabel.text = [contactDict objectForKey:ContactsCacheKey_AccountName];
    }
        
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//FIXME			this class should probably have its own context property
	NSString			*sfid = nil;
    MMSF_Contact* cellContact;
    
    if(self.isRecentContactsSelected) {
        cellContact = [self.recentContacts.sortedContacts objectAtIndex:indexPath.row];
    }
    else {
		MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
        NSDictionary* contactDict = [self.contactsCache searchContactAtIndex:indexPath.row];
        sfid = [contactDict objectForKey:ContactsCacheKey_SalesforceId];
        cellContact = [moc anyObjectOfType: @"Contact" matchingPredicate: $P(@"Id == %@", sfid)];
        if (!sfid) {
            NSString *objectIdString = [contactDict objectForKey: @"objectId"];
            if (objectIdString)
                cellContact = [moc objectWithIDString: objectIdString];
            
        }
    }
    
    [self.recentContacts addContact: cellContact];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kCheckInContactSelected object: cellContact];		//FIXME need to NOT pass an object in a notification
    
}

#pragma mark - Popover Stuff

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController {
    s_controller = nil;
	s_popoverController = nil;
}

#pragma mark - Notifications

- (void) contactsLoaded:(NSNotification*) notification {
    MMLog(@"%@", @"contacts loaded");
    self.loadingActivityIndicator.hidden = YES;
    self.loadingLabel.hidden = YES;
    [self.loadingActivityIndicator stopAnimating];
    self.searchBar.hidden = NO;
    self.table.hidden = NO;
    self.listSelector.hidden = NO;
    [self.table reloadData];
    
    [self updateChooseLater];
}

- (void) searchComplete:(NSNotification*) notification {
    [self.table reloadData];
}

@end
