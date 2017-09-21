//
//  ZM_AddFavoriteViewController.m
//  Zimmer
//
//  Created by Chris Cieslak on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DSA_AddFavoriteViewController.h"
#import "DSA_ContentShelvesModel.h"
#import "DSA_CreateFavoriteShelfController.h"

@implementation DSA_AddFavoriteViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.tableView.accessibilityLabel = @"Add To Playst";
    self.tableView.accessibilityIdentifier = @"Add To Playlist";
    self.tableView.isAccessibilityElement = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterDataSourceChange:) name:kNotification_ContentShelfCreated object:nil];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (YES);
}

- (CGSize)preferredContentSize {
    NSInteger shelfCount = [[DSA_ContentShelvesModel sharedModel] addableShelfCount] + 2;
    CGSize contentSize = CGSizeMake(self.view.frame.size.width, shelfCount * 44);
    
    return contentSize;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
//    return [[DSA_ContentShelvesModel sharedModel] shelfCount] + 1;
    return [[DSA_ContentShelvesModel sharedModel] addableShelfCount] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if ([indexPath row] == [[DSA_ContentShelvesModel sharedModel] addableShelfCount]) {
        cell.textLabel.text = @"Create New Playlist...";
    }
    else {
        NSString *shelfName = [[DSA_ContentShelvesModel sharedModel] addableShelfNameForIndex:indexPath.row];
        cell.textLabel.text = shelfName;
        if ([[DSA_ContentShelvesModel sharedModel] contentItemId:self.item.Id isOnShelfNamed:shelfName]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)uiTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row] == [[DSA_ContentShelvesModel sharedModel] addableShelfCount]) {
        [DSA_CreateFavoriteShelfController showFromButton: [self.tableView cellForRowAtIndexPath:indexPath] withItemToAdd: nil];
    }
    else {
        DSA_ContentShelfModel *shelf = [[DSA_ContentShelvesModel sharedModel] addableShelfAtIndex:indexPath.row]; //???
        if ([shelf containsItemId:self.item.Id]) {
            if (![shelf removeContentItemId:self.item.Id updateLayout:YES animated:NO]) {
                SA_AlertView *alert = [SA_AlertView alertWithTitle:@"Protected Shelf" message:@"You cannot add items to, or remove items from, this shelf." tag:0 button:@"OK"];
                [alert show];
            }
        }
        else {
            if (![shelf addContentItemId:self.item.Id updateLayout:YES animated:NO]) {
//                SA_AlertView *alert = [SA_AlertView alertWithTitle:@"Protected Shelf" message:@"You cannot add items to, or remove items from, this shelf." tag:0 button:@"OK"];
//                [alert show];
            }
        }
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)afterDataSourceChange:(NSNotification *) notification {
    [self.tableView reloadData];
}

@end
