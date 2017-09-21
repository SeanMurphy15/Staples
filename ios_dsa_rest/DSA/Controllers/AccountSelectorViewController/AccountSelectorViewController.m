//
//  AccountSelectorViewController.m
//  DSA
//
//  Created by Jason Barker on 4/23/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "AccountSelectorViewController.h"
#import <dispatch/dispatch.h>
#import "CreateContactViewController.h"
#import "ContactController.h"
#import "MMSF_Account.h"
#import "Branding.h"


static NSUInteger MINIMUM_SEARCH_TEXT_LENGTH    = 1;



@interface AccountSelectorViewController () {
    
    NSManagedObjectContext  *_accountsMOC;
    NSArray                 *_fetchedAccountIdentifiers;
    NSOperationQueue        *_fetchAccountsQueue;
}

@end



@implementation AccountSelectorViewController


/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if (self) {
        
        [self setTitle: @"Select Account"];
        
        _fetchAccountsQueue = [[NSOperationQueue alloc] init];
        [_fetchAccountsQueue setName: @"com.accountSelection.fetchAccounts"];
        
        _accountsMOC = [MM_ContextManager sharedManager].threadContentContext;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.contentSizeForViewInPopover = CGSizeMake(600, 600);
#pragma clang diagnostic pop
    }
    
    return self;
}

- (void) viewDidLoad
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

/**
 *
 */
- (void) viewWillAppear: (BOOL) animated {
    
    [super viewWillAppear: animated];
    
    [self.searchDisplayController.searchBar setBarTintColor: [[Branding blueColor] colorWithAlphaComponent: 0.4]];
}


/**
 *
 */
- (void) fetchAccounts {
    
    NSString *searchString = self.searchDisplayController.searchBar.text;
    
    [_fetchAccountsQueue cancelAllOperations];
    
    __weak AccountSelectorViewController *weakSelf = self;
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    
    [operation addExecutionBlock: ^{
        
        if (weakOperation.isCancelled)
            return;
        
        //  Build predicate based on whether the search string has one or multiple words in it.
        NSPredicate *predicate  = nil;
        NSArray     *words      = [searchString componentsSeparatedByString: @" "];
        
        if (words.count == 0)
            return;
        
        if (words.count == 1) {
            
            predicate  = [NSPredicate predicateWithFormat: @"(Name contains[cd] %@)", words[0]];
        }
        else {
            
            NSMutableArray *subpredicates = [NSMutableArray array];
            for (NSString *word in words) {
                
                if (word.length > 0)
                    [subpredicates addObject: [NSPredicate predicateWithFormat: @"(Name contains[cd] %@)", word]];
                    
            }
            
            if (subpredicates.count > 0)
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates: subpredicates];
                
        }
        
        NSManagedObjectContext  *moc        = [MM_ContextManager sharedManager].contentContextForReading;
        NSEntityDescription     *entity     = [NSEntityDescription entityForName: @"Account" inManagedObjectContext: moc];
        NSFetchRequest          *request    = [[NSFetchRequest alloc] initWithEntityName: entity.name];
        NSSortDescriptor        *sortByName = [[NSSortDescriptor alloc] initWithKey: @"Name" ascending: YES];
        
        [request setResultType: NSManagedObjectIDResultType];
        [request setIncludesPropertyValues: NO];
        [request setFetchBatchSize: 20];
        [request setSortDescriptors: @[sortByName]];
        [request setPredicate: predicate];
        
        NSError *error = nil;
        NSArray *accountIDs = nil;
        
        if (!weakOperation.isCancelled)
            accountIDs = [moc executeFetchRequest: request error: &error];
        
        if (!weakOperation.isCancelled)
            [NSObject performBlockOnMainThread: ^{ [weakSelf loadAccounts: accountIDs matchingSearchString: searchString]; }];
        
    }];
    
    [_fetchAccountsQueue addOperation: operation];
}


/**
 *
 */
- (void) loadAccounts: (NSArray *) accountIdentifiers matchingSearchString: (NSString *) searchString {
    
    NSString *currentSearchString = self.searchDisplayController.searchBar.text;
    
    if ([searchString isEqualToString: currentSearchString]) {
        
        _fetchedAccountIdentifiers = accountIdentifiers;
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}


#pragma mark - UISearchDisplayDelegate messages


/**
 *
 */
- (BOOL) searchDisplayController: (UISearchDisplayController *) controller shouldReloadTableForSearchString: (NSString *) searchString {
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(fetchAccounts)
                                               object: nil];
    
    if (searchString.length >= MINIMUM_SEARCH_TEXT_LENGTH)
        [self performSelector: @selector(fetchAccounts) withObject: nil afterDelay: 0.4];
    
    
    return YES;
}


#pragma mark - UITableViewDataSource messages


/**
 *
 */
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    
    return _fetchedAccountIdentifiers.count;
}


/**
 *
 */
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    
    static NSString *AccountCellIdentifier = @"AccountCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: AccountCellIdentifier];
    if (!cell) {
        
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: AccountCellIdentifier];
    }
    
    if (indexPath.row < _fetchedAccountIdentifiers.count) {
        
        NSManagedObjectID   *objectID   = [_fetchedAccountIdentifiers objectAtIndex: indexPath.row];
        MMSF_Account        *account    = (MMSF_Account *) [_accountsMOC objectWithID: objectID];
        
        [cell.textLabel setText: account.Name];
        
        if ([account respondsToSelector: @selector(AccountNumber)])
            [cell.detailTextLabel setText: account.AccountNumber];
        else
            [cell.detailTextLabel setText: @""];
        
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
    
    NSManagedObjectID *objectID = [_fetchedAccountIdentifiers objectAtIndex: indexPath.row];
    
    MMSF_Account *account = (MMSF_Account *) [_accountsMOC objectWithID: objectID];
    [self.contactController setAccount: account];
    
    CreateContactViewController *viewController = [[CreateContactViewController alloc] init];
    [viewController setContactController: self.contactController];
    [self.navigationController pushViewController: viewController animated: YES];
}


@end

