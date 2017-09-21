//
//  LeadSearchViewController.m
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "LeadSearchViewController.h"
#import "CheckInCheckOutConstants.h"
#import "LeadCompanyDetailViewController.h"
#import "LeadController.h"
#import "MMSF_Lead.h"
#import "Branding.h"


@interface LeadSearchViewController () {
    
    NSManagedObjectContext  *_leadsMOC;
    NSArray                 *_fetchedLeadIdentifiers;
    NSOperationQueue        *_fetchLeadsQueue;
}

@end

static UIPopoverController			*s_popoverController = nil;
static dispatch_queue_t				s_fetchQueue = nil;
static LeadSearchViewController  *s_controller;


@implementation LeadSearchViewController

+ (LeadSearchViewController *) controller {
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
    
    LeadSearchViewController *controller = [self controller];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController: controller];
    //nav.navigationBar.barStyle = UIBarStyleDefault;
    s_popoverController = [[UIPopoverController alloc] initWithContentViewController: nav];
    
    s_popoverController.delegate = controller;
    
    return s_popoverController;
}

/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if (self) {
        
        [self setTitle: @"Select Lead"];
        
        _fetchLeadsQueue = [[NSOperationQueue alloc] init];
        [_fetchLeadsQueue setName: @"com.leadSelection.fetchLeads"];
        
        _leadsMOC = [MM_ContextManager sharedManager].threadContentContext;
        
        UIBarButtonItem *addLeadButton = [[UIBarButtonItem alloc] initWithTitle: @"Create Lead"
                                                                          style: UIBarButtonItemStylePlain
                                                                         target: self
                                                                         action: @selector(showAddLeadForm:)];
        [self.navigationItem setRightBarButtonItem: addLeadButton];
        
        [self setShowsDeferButton: YES];
        
        //  Initially fetch the leads.
        [self fetchLeads];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.contentSizeForViewInPopover = CGSizeMake(600, 600);
#pragma clang diagnostic pop
    }
    
    return self;
}


#pragma mark - View lifecycle


/**
 *
 */
- (void) viewDidLoad {
    
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIView *footerView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(self.leadsTableView.frame), 0)];
    [self.leadsTableView setTableFooterView: footerView];
    
    [self.segmentedControl setTintColor: [Branding blueColor]];
    [self.searchBar setBarTintColor: [Branding lightBlueColor]];
    [self.deferButton.titleLabel setTextColor: [Branding blueColor]];
    [self.deferButton setTitleColor: [Branding blueColor] forState: UIControlStateNormal];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
}


/**
 *
 */
- (void) viewWillAppear: (BOOL) animated {
    
    [super viewWillAppear: animated];
    
    if (self.showsDeferButton) {
        
        [self.deferButton setHidden: NO];
        
        CGRect frame = self.leadsTableView.frame;
        frame.size.height = self.deferButton.frame.origin.y - 8.0 - frame.origin.y;    //  8.0 = vertical gap between top of deferButton and bottom of leads tableView
        [self.leadsTableView setFrame: frame];
    }
    else {
        
        [self.deferButton setHidden: YES];
        
        CGRect frame = self.leadsTableView.frame;
        frame.size.height = CGRectGetHeight(self.view.frame) - frame.origin.y;
        [self.leadsTableView setFrame: frame];
    }
    
    [self.leadsTableView reloadData];
}

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController {
    s_controller = nil;
    s_popoverController = nil;
}

#pragma mark - Actions


/**
 *
 */
- (IBAction) deferSelection: (id) sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName: kCheckInLeadDeferred object: nil];
}


/**
 *
 */
- (IBAction) showAddLeadForm: (id) sender {
    
    __weak LeadSearchViewController *weakSelf = self;
    LeadController *leadController = [[LeadController alloc] init];
    [leadController setCompletionBlock: ^(BOOL completed) {
        
        [weakSelf fetchLeads];
        [weakSelf.navigationController popToViewController: self animated: YES];
    }];
    
    LeadCompanyDetailViewController *detailViewController = [[LeadCompanyDetailViewController alloc] init];
    [detailViewController setDefaultsForLeadController: leadController];
    [self.navigationController pushViewController: detailViewController animated: YES];
}


#pragma mark -


/**
 *
 */
- (void) fetchLeads {
    
    NSString *searchString = self.searchBar.text;
    
    [_fetchLeadsQueue cancelAllOperations];
    
    __weak LeadSearchViewController *weakSelf = self;
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    
    [operation addExecutionBlock: ^{
        
        if (weakOperation.isCancelled)
            return;
        
        //  Build predicate based on whether the search string has one or multiple words in it.
        NSPredicate *predicate  = nil;
        NSArray     *words      = [searchString componentsSeparatedByString: @" "];
        
        if (words.count == 1) {
            
            NSString *letters = words[0];
            if (letters.length > 0) {
                
                NSPredicate *firstNamePredicate = [NSPredicate predicateWithFormat: @"(FirstName CONTAINS[cd] %@)", words[0]];
                NSPredicate *lastNamePredicate  = [NSPredicate predicateWithFormat: @"(LastName CONTAINS[cd] %@)", words[0]];
                NSPredicate *emailPredicate     = [NSPredicate predicateWithFormat: @"(Email CONTAINS[cd] %@)", words[0]];
                NSPredicate *companyPredicate   = [NSPredicate predicateWithFormat: @"(Company CONTAINS[cd] %@)", words[0]];
                
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates: @[firstNamePredicate, lastNamePredicate, emailPredicate, companyPredicate]];
            }
        }
        else if (words.count > 1) {
            
            NSMutableArray *predicates = [NSMutableArray array];
            for (NSString *letters in words) {
                
                if (letters.length > 0) {
                    
                    NSPredicate *firstNamePredicate = [NSPredicate predicateWithFormat: @"(FirstName CONTAINS[cd] %@)", letters];
                    NSPredicate *lastNamePredicate  = [NSPredicate predicateWithFormat: @"(LastName CONTAINS[cd] %@)", letters];
                    NSPredicate *emailPredicate     = [NSPredicate predicateWithFormat: @"(Email CONTAINS[cd] %@)", letters];
                    NSPredicate *companyPredicate   = [NSPredicate predicateWithFormat: @"(Company CONTAINS[cd] %@)", letters];
                    
                    [predicates addObject: [NSCompoundPredicate orPredicateWithSubpredicates: @[firstNamePredicate, lastNamePredicate, emailPredicate, companyPredicate]]];
                }
            }
            
            if (predicates.count > 0)
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates: predicates];
            
        }
        
        NSManagedObjectContext  *moc        = [MM_ContextManager sharedManager].contentContextForReading;
        NSEntityDescription     *entity     = [NSEntityDescription entityForName: @"Lead" inManagedObjectContext: moc];
        NSFetchRequest          *request    = [[NSFetchRequest alloc] initWithEntityName: entity.name];
        NSSortDescriptor        *sortByName = [[NSSortDescriptor alloc] initWithKey: @"FirstName" ascending: YES];
        
        [request setResultType: NSManagedObjectIDResultType];
        [request setIncludesPropertyValues: NO];
        [request setFetchBatchSize: 20];
        [request setSortDescriptors: @[sortByName]];
        
        if (predicate)
            [request setPredicate: predicate];
        
        NSError *error = nil;
        NSArray *leadIDs = nil;
        
        if (!weakOperation.isCancelled)
            leadIDs = [moc executeFetchRequest: request error: &error];
        
        if (!weakOperation.isCancelled)
            [NSObject performBlockOnMainThread: ^{ [weakSelf loadLeads: leadIDs matchingSearchString: searchString]; }];
        
    }];
    
    [_fetchLeadsQueue addOperation: operation];
}


/**
 *
 */
- (void) loadLeads: (NSArray *) leadIdentifiers matchingSearchString: (NSString *) searchString {
    
    NSString *currentSearchString = self.searchBar.text;
    
    if ([searchString isEqualToString: currentSearchString] || (searchString.length == 0 && currentSearchString.length == 0)) {
        
        _fetchedLeadIdentifiers = leadIdentifiers;
        [self.leadsTableView reloadData];
    }
}

- (IBAction) cancelPressed:(id)sender {
    [LeadSearchViewController dismissPopover];
}

#pragma mark - UISearchBarDelegate messages


/**
 *
 */
- (void) searchBar: (UISearchBar *) searchBar textDidChange: (NSString *) searchText {
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(fetchLeads)
                                               object: nil];
    
    [self performSelector: @selector(fetchLeads) withObject: nil afterDelay: 0.4];
}


#pragma mark - UITableViewDataSource messages


/**
 *
 */
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    
    return _fetchedLeadIdentifiers.count;
}


/**
 *
 */
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    
    static NSString *RequiredInfoCellIdentifier = @"RequiredInfoCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: RequiredInfoCellIdentifier];
    if (!cell) {
        
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: RequiredInfoCellIdentifier];
    }
    
    if (indexPath.row < _fetchedLeadIdentifiers.count) {
        
        NSManagedObjectID   *objectID   = [_fetchedLeadIdentifiers objectAtIndex: indexPath.row];
        MMSF_Lead           *lead       = (MMSF_Lead *) [_leadsMOC objectWithID: objectID];
        NSMutableString     *name       = [NSMutableString string];
        
        if (lead.LastName.length > 0)
            [name appendString: lead.LastName];
        
        if (lead.FirstName.length > 0) {
            
            if (name.length > 0)
                [name appendString: @", "];
            
            [name appendString: lead.FirstName];
        }
        
        if (name.length > 0)
            [name appendString: @" "];
        
        if (lead.Email.length > 0)
            [name appendFormat: @"<%@>", lead.Email];
        else
            [name appendFormat: @"<%@>", NSLocalizedString(@"NO_EMAIL_ADDRESS_MESSAGE", nil)];
        
        
        [cell.textLabel setText: name];
        [cell.detailTextLabel setText: lead.Company];
    }
    else {
        
        [cell.textLabel setText: @""];
        [cell.detailTextLabel setText: @""];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate messages


/**
 *
 */
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    
    if (indexPath.row < _fetchedLeadIdentifiers.count) {
        
        NSManagedObjectID   *objectID   = [_fetchedLeadIdentifiers objectAtIndex: indexPath.row];
        MMSF_Lead           *lead       = (MMSF_Lead *) [_leadsMOC objectWithID: objectID];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: kCheckInLeadSelected object: lead];
    }
}

- (CGSize)preferredContentSize {
    return CGSizeMake(600, 600);
}

@end
