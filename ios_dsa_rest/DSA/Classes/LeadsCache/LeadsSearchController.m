//
//  LeadsSearchController.m
//  DSA
//
//  Created by Jason Barker on 5/8/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "LeadsSearchController.h"
#import "MMSF_Lead.h"



@interface LeadsSearchController () {
    
    NSManagedObjectContext  *_leadsMOC;
    NSArray                 *_fetchedLeadsIdentifiers;
    NSOperationQueue        *_fetchLeadsQueue;
}

@end



@implementation LeadsSearchController


/**
 *
 */
- (id) initWithDelegate: (id <LeadsSearchControllerDelegate>) delegate {
    
    self = [super init];
    
    if (self) {
        
        [self setDelegate: delegate];
        
        _fetchLeadsQueue = [[NSOperationQueue alloc] init];
        [_fetchLeadsQueue setName: @"com.leads.search"];
        
        _leadsMOC = [MM_ContextManager sharedManager].threadContentContext;
    }
    
    return self;
}


/**
 *
 */
- (void) searchForLeadsWithString: (NSString *) searchString {
    
    @synchronized (self) {
        
        [_fetchLeadsQueue cancelAllOperations];
        
        _fetchedLeadsIdentifiers = nil;
        _searchString = nil;
    }
    
    __weak LeadsSearchController *weakSelf = self;
    
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
            [NSObject performBlockOnMainThread: ^{
                
                _searchString = [searchString copy];
                _fetchedLeadsIdentifiers = leadIDs;
                
                if (weakSelf.delegate)
                    [weakSelf.delegate leadsSearchController: weakSelf didFindLeadsWithString: searchString];
                
            }];
        
    }];
    
    [_fetchLeadsQueue addOperation: operation];
}


/**
 *
 */
- (NSInteger) numberOfLeads {
    
    return _fetchedLeadsIdentifiers.count;
}


/**
 *
 */
- (MMSF_Lead *) leadAtIndex: (NSInteger) index {
    
    MMSF_Lead *lead = nil;
    
    @synchronized (self) {
        
        if (index >= 0 && index < _fetchedLeadsIdentifiers.count) {
            
            NSManagedObjectContext  *moc        = [MM_ContextManager sharedManager].threadContentContext;
            NSManagedObjectID       *objectID   = _fetchedLeadsIdentifiers[index];
            
            lead = (MMSF_Lead *) [moc objectWithID: objectID];
        }
    }
    
    return lead;
}


@end