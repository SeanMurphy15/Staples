//
//  ContentItemHistoryController.m
//  ios_dsa
//
//  Created by Guy Umbright on 9/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ContentItemHistoryController.h"
#import "DSA_AppDelegate.h"
#import "MMSF_ContentVersion.h"

@interface ContentItemHistoryController ()
@property (nonatomic, strong) NSArray *availableHistory;
@end

@implementation ContentItemHistoryController

- (void)loadHistory {
    NSArray *contentHistory = g_appDelegate.contentItemHistory.contentItemHistory;
    
    BOOL internalMode = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
    if (internalMode) {
        self.availableHistory = contentHistory;
    } else {
        NSMutableArray *externalContent = [NSMutableArray arrayWithCapacity:contentHistory.count];
        for (NSDictionary *historyItem in contentHistory) {
            MMSF_ContentVersion *content = [MMSF_ContentVersion contentItemBySalesforceId:historyItem[@"contentVersionID"]];
            if (content && [content[MNSS(@"Internal_Document__c")] boolValue] != YES) {
                [externalContent addObject:historyItem];
            }
        }
        self.availableHistory = externalContent.copy;
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.tableView.accessibilityLabel = @"History Table";
    self.tableView.accessibilityIdentifier = @"History Table";

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadHistory];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (CGSize)preferredContentSize {
    return CGSizeMake(475, 44*15);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(self.availableHistory.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //FIXME: this class should probably have its own context property
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    
    if(self.availableHistory.count == 0 ) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"No Documents Found";
        
    }
    else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        NSDictionary *currentHistory = [self.availableHistory objectAtIndex:[indexPath row]];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"Id = %@",[currentHistory objectForKey:@"contentVersionID"]];
		MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
		MMSF_ContentVersion* ci = (id) [moc anyObjectOfType:@"ContentVersion" matchingPredicate:pred];

        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",[currentHistory objectForKey:@"configName"],ci.Title];         
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *itemDict = self.availableHistory[indexPath.row];
    if (itemDict) {
        [[NSNotificationCenter defaultCenter] postNotificationName: kContentItemHistoryItemSelectedNotification object:itemDict[@"contentVersionID"]];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *selectedIndexPath = nil;
    
    if (self.availableHistory.count > 0) {
        selectedIndexPath = indexPath;
    }
    
    return selectedIndexPath;
}

@end
