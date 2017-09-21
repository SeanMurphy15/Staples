//
//  ZM_ContactSelectionController.m
//  ModelMetrics
//
//  Created by Ben Gottlieb on 9/7/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "DSA_ContactSelectionController.h"
#import "MMSF_ContentVersion.h"
#import "DSA_AppDelegate.h"
#import "ContactsCache.h"
#import "DSARestClient.h"
#import "LeadsSearchController.h"
#import "MMSF_Contact.h"
#import "MMSF_Lead.h"


static NSUInteger s_numberOfContacts = 0;

typedef enum {
	onClose_nothing,
	onClose_email
} onClose_action;

@interface DSA_ContactSelectionController ()

@property (nonatomic, strong) ContactsCache* contactsCache;
@property (nonatomic, assign) BOOL searchActive;
@property (nonatomic, readwrite, strong) NSMutableArray *selectedEntities;
@property (nonatomic, strong) LeadsSearchController *leadsSearchController;

@end


@implementation DSA_ContactSelectionController


+ (void) load {
	BEGIN_AUTORELEASEPOOL();
    
	END_AUTORELEASEPOOL();
}

+ (void) syncFinished {
	s_numberOfContacts = 0;
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (id) controllerToMailContentItem: (MMSF_ContentVersion *) item {
	DSA_ContactSelectionController			*controller = [[DSA_ContactSelectionController alloc] init];
	
	controller.item = item;
	controller.modalPresentationStyle = UIModalPresentationFormSheet;
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	//[controller addAsObserverForName: kNotification_ContactRecordFound selector: @selector(foundContact:)];
	return controller;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { return YES; }

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

//////////////////////////////////////////////////
//
//////////////////////////////////////////////////
- (void) adjustControls
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey: kDefaultsKey_DemoMode])
    {
        self.emailButton.enabled = (self.emailAddress.text.length > 0);
    }
    else
    {
        self.emailButton.enabled = (self.selectedEntities.count > 0);
    }
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) setBusyMode
{
	self.searchBar.userInteractionEnabled = NO;
	self.searchBar.alpha = 0.5;
    [self.loadingActivityIndicator startAnimating];
    self.loadingLabel.hidden = NO;
    self.allContactsTableView.hidden = YES;
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) clearBusyMode
{
    self.searchBar.userInteractionEnabled = YES;
    self.searchBar.alpha = 1.0;
    [self.loadingActivityIndicator stopAnimating];
    self.loadingLabel.hidden = YES;
    self.allContactsTableView.hidden = NO;
    
}


#pragma mark - ViewController
- (NSString *) buildNameStringForLead: (MMSF_Lead *) lead {
    
    NSString    *firstName  = lead.FirstName;
    NSString    *lastName   = lead.LastName;
    NSString    *email      = lead.Email;
    
    NSMutableString *name = [NSMutableString string];
    if (lastName.length > 0)
        [name appendString: lastName];
    
    if (firstName.length > 0) {
        
        if (name.length > 0)
            [name appendString: @", "];
        
        [name appendString: firstName];
    }
    
    if (name.length > 0)
        [name appendString: @" "];
    
    [name appendFormat: @"<%@>", (email.length > 0 ? email : NSLocalizedString(@"NO_EMAIL_ADDRESS_MESSAGE", nil))];
    
    return [NSString stringWithString: name];
}


- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self setBusyMode];
	
	self.searchBar.accessibilityLabel = @"Search Contacts or Leads";
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: kDefaultsKey_DemoMode])
    {
        [self.view addSubview:self.demoOverlay];
        CGRect r = self.demoOverlay.frame;
        r.origin.y = 44;
        r.size.width = self.view.bounds.size.width;
        self.demoOverlay.frame = r;
        [self.view setNeedsLayout];
        
        self.searchBar.hidden = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editValueChanged:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:self.emailAddress];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsLoaded:)
                                                 name:ContactsCacheNotification_ContactsLoaded
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(searchComplete:)
                                                 name:ContactsCacheNotification_SearchComplete
                                               object:nil];
    self.contactsCache = [[[ContactsCache alloc] init] autorelease];
    [self.contactsCache loadCache];
    
    LeadsSearchController *searchController = [[LeadsSearchController alloc] initWithDelegate: self];
    [self setLeadsSearchController: searchController];
    [self.leadsSearchController searchForLeadsWithString: @""];
	
	self.allContactsTableView.accessibilityLabel = @"List of All Contacts and Leads";
	
    for (UIView *subView in self.searchBar.subviews)
    {
        if ([subView isKindOfClass:[UITextField class]])
        {
            UITextField *searchBarTextField = (UITextField *)subView;
            searchBarTextField.placeholder = @"Search Contacts or Leads";
            
            //set font color here
            //searchBarTextField.textColor = [UIColor whiteColor];
            
            break;
        }
        for (UIView *secondLevelSubview in subView.subviews){
            if ([secondLevelSubview isKindOfClass:[UITextField class]])
            {
                UITextField *searchBarTextField = (UITextField *)secondLevelSubview;
                searchBarTextField.placeholder = @"Search Contacts or Leads";
                
                //set font color here
                //searchBarTextField.textColor = [UIColor whiteColor];
                
                break;
            }
        }
    }
}

- (void) editValueChanged:(NSNotification*) notification
{
    [self adjustControls];
}

- (void) viewWillAppear: (BOOL)animated {
    [super viewWillAppear: animated];
	self.selectedEntities = [NSMutableArray array];
    [self adjustControls];
}

- (void) activateLoadingIndicator {
    [self setBusyMode];
}

#pragma mark - Search Bar Delegate

- (void) searchBar: (UISearchBar *) searchBar textDidChange: (NSString *) searchText
{
    if ([searchText isEqualToString:@""]) {
        [self.contactsCache clearSearch];
        [self.leadsSearchController searchForLeadsWithString: searchText];
        [self clearBusyMode];
        [self.allContactsTableView reloadData];
        [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(performSearch) object: nil];
        return;
    }
	if (self.currentSearchString) {
		self.pendingSearchString = searchText;
		return;
	}
	[self cancelAndPerformSelector: @selector(performSearch) withObject: nil afterDelay: 0.5];
}

- (void) performSearch {
 	[self performSelector: @selector(activateLoadingIndicator)];
   [self.contactsCache search:[self.searchBar.text lowercaseString]];
    [self.leadsSearchController searchForLeadsWithString: self.searchBar.text];
}

//=============================================================================================================================
#pragma mark Actions
- (IBAction) cancel
{
	[self.contactSelectionDelegate  contactSelectionControllerCancelPressed:self];
}

- (IBAction) sendEmail
{
	[self.contactSelectionDelegate  contactSelectionControllerSendPressed:self];
}

#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    NSDictionary* contactDict = nil;
	NSString								*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
    BOOL hasSelection = (self.selectedEntities.count > 0);
    
	//MMSF_Contact *contact = (indexPath.section == 1) ? [self.allContacts objectAtIndex: indexPath.row] : [self.selectedContacts objectAtIndex: indexPath.row];
	
	
	if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier] autorelease];
    }
    
    cell.accessoryType = (indexPath.section == 0 && hasSelection) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
    if (hasSelection && indexPath.section == 0)
    {
        id object = [self.selectedEntities objectAtIndex: indexPath.row];
        
        if ([object isKindOfClass: [NSDictionary class]]) {
            
            NSDictionary* contactDict = (NSDictionary *) object;
            cell.textLabel.text =[self.contactsCache nameStringForContact:contactDict];
        }
        else if ([object isKindOfClass: [MMSF_Lead class]]) {
            
            MMSF_Lead *lead = (MMSF_Lead *) object;
            [cell.textLabel setText: [self buildNameStringForLead: lead]];
        }
    }
    else if ((hasSelection && indexPath.section == 1) || (!hasSelection && indexPath.section == 0))
    {
        NSDictionary *contactDict = [self.contactsCache searchContactAtIndex:indexPath.row];
        cell.textLabel.text =[self.contactsCache nameStringForContact:contactDict] ;
    }
    else if ((hasSelection && indexPath.section == 2) || (!hasSelection && indexPath.section == 1))
    {
        MMSF_Lead *lead = [self.leadsSearchController leadAtIndex: indexPath.row];
        [cell.textLabel setText: [self buildNameStringForLead: lead]];
    }
    
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    
    if (self.selectedEntities.count > 0)
    {
        return 3;
    }
    else
    {
        return 2;
    }
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    
    NSInteger count = 0;
    
    if (self.selectedEntities.count > 0) {
        
        switch (section) {
            case 0:
                count = self.selectedEntities.count;
                break;
                
            case 1:
                count = self.contactsCache.searchContactCount;
                break;
                
            case 2:
                count = self.leadsSearchController.numberOfLeads;
                break;
                
            default:
                break;
        }
    }
    else {
        
        switch (section) {
            case 0:
                count = self.contactsCache.searchContactCount;
                break;
                
            case 1:
                count = self.leadsSearchController.numberOfLeads;
                break;
                
            default:
                break;
        }
    }
    
    return count;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    
    NSDictionary* contactDict;
    
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
    
	[tableView beginUpdates];
	
    if ((indexPath.section == 1 && self.selectedEntities.count > 0) || (indexPath.section == 0 && self.selectedEntities.count == 0))
    {
        contactDict = [self.contactsCache searchContactAtIndex:indexPath.row];
        
        if([self.selectedEntities containsObject:contactDict])
        {
            [SA_AlertView showAlertWithTitle: NSLocalizedString(@"Info",@"Info")
									 message: NSLocalizedString(@"This contact has been selected already.",@"This contact has been selected already.")];
            [tableView endUpdates];
            return;
        }
        
        [self.selectedEntities addObject: contactDict];

        if (tableView.numberOfSections == 2)
        {
            [tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        NSIndexPath* insertPath = [NSIndexPath indexPathForRow: [self.selectedEntities indexOfObject: contactDict] inSection: 0];
		[tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: insertPath] withRowAnimation: UITableViewRowAnimationAutomatic];
	}
    else if ((indexPath.section == 2 && self.selectedEntities.count > 0) || (indexPath.section == 1 && self.selectedEntities.count == 0)) {
        
        MMSF_Lead *lead = [self.leadsSearchController leadAtIndex: indexPath.row];
        if (lead) {
            
            if([self.selectedEntities containsObject: lead])
            {
                [SA_AlertView showAlertWithTitle: NSLocalizedString(@"Info",@"Info")
                                         message: NSLocalizedString(@"This lead has been selected already.",@"This lead has been selected already.")];
                [tableView endUpdates];
                return;
            }
            
            [self.selectedEntities addObject: lead];
            
            if (tableView.numberOfSections == 2)
            {
                [tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            NSIndexPath *insertPath = [NSIndexPath indexPathForRow: [self.selectedEntities indexOfObject: lead] inSection: 0];
            [tableView insertRowsAtIndexPaths: @[insertPath] withRowAnimation: UITableViewRowAnimationAutomatic];
        }
    }
    else
    {        
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
        [self.selectedEntities removeObjectAtIndex: indexPath.row];
        
        if (self.selectedEntities.count == 0)
        {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    
	[self.allContactsTableView endUpdates];
    [self adjustControls];
    
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section {
    
    NSString *title = nil;
    
    if (self.selectedEntities.count > 0) {
        
        switch (section) {
            case 0:
                title = @"Send email to these contacts and/or leads";
                break;
                
            case 1:
                title = @"Contacts";
                break;
                
            case 2:
                title = @"Leads";
                break;
                
            default:
                break;
        }
    }
    else {
        
        switch (section) {
            case 0:
                title = @"Contacts";
                break;
                
            case 1:
                title = @"Leads";
                break;
                
            default:
                break;
        }
    }

	return title;
}

- (NSString*) demoEmailAddress
{
    return self.emailAddress.text;
}

#pragma mark - Notifications

- (void) contactsLoaded:(NSNotification*) notification
{
    MMLog(@"%@", @"contacts loaded");
    [self clearBusyMode];
    [self.allContactsTableView reloadData];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) searchComplete:(NSNotification*) notification
{
    [self clearBusyMode];
    [self.allContactsTableView reloadData];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (NSArray*) selectedContacts			//FIXME: should probably pass in a context
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:self.selectedEntities.count];
	MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
    
    for (id entity in self.selectedEntities) {
        
        if ([entity isKindOfClass: [NSDictionary class]]) {
            
            NSDictionary *dict = (NSDictionary *) entity;
            NSString* sfid = [dict objectForKey:ContactsCacheKey_SalesforceId];
            
            MMSF_Contact* contact = [moc anyObjectOfType: [MMSF_Contact entityName]
                                       matchingPredicate: $P(@"Id == %@",sfid)];
            [result addObject:contact];
        }
        else if ([entity isKindOfClass: [MMSF_Lead class]]) {
            
            MMSF_Lead *lead = (MMSF_Lead *) [moc objectWithID: ((NSManagedObject *) entity).objectID];
            [result addObject: lead];
        }
    }
    
    return result;
}


#pragma mark - LeadsSearchControllerDelegate messages


/**
 *
 */
- (void) leadsSearchController: (LeadsSearchController *) controller didFindLeadsWithString: (NSString *) searchString {
    
    if (self.isViewLoaded) {
        
        if ([searchString isEqualToString: self.searchBar.text])
            [self.allContactsTableView reloadData];
        
    }
}


@end
