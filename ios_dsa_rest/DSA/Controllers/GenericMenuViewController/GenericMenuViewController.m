//
//  GenericMenuViewController.m
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "GenericMenuViewController.h"


@implementation GenericMenuViewController


/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if (self) {
        
        [self setSelectedIndex: NSNotFound];
    }
    
    return self;
}


/**
 *
 */
- (void) viewWillAppear: (BOOL) animated {
    
    [super viewWillAppear: animated];
    
    [self.menuTableView reloadData];
    [self.menuTableView setAllowsMultipleSelection: self.allowsMultipleSelection];
}


#pragma mark - UITableViewDataSource messages


/**
 *
 */
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    
    return self.menuItems.count;
}


/**
 *
 */
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    
    [cell.textLabel setText: [self.menuItems objectAtIndex: indexPath.row]];
    
    UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
    if (self.allowsMultipleSelection) {
        
        if ([self.selectedIndices containsIndex: indexPath.row])
            accessoryType = UITableViewCellAccessoryCheckmark;
        else
            accessoryType = UITableViewCellAccessoryNone;
        
    }
    else {
        
        if (indexPath.row == self.selectedIndex)
            accessoryType = UITableViewCellAccessoryCheckmark;
        
    }
    
    [cell setAccessoryType: accessoryType];
    
    return cell;
}


/**
 *
 */
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    
	NSString *item = indexPath.row < self.menuValues.count ? self.menuValues[indexPath.row] :  self.menuItems[indexPath.row];
	
    if (self.allowsMultipleSelection) {
        
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] initWithIndexSet: self.selectedIndices];
        if ([indexSet containsIndex: indexPath.row]) {
            
            [indexSet removeIndex: indexPath.row];
            [self setSelectedIndices: indexSet];
            
            if (self.delegate && [self.delegate respondsToSelector: @selector(menuViewController:didDeselectItem:atIndex:)])
                [self.delegate menuViewController: self didDeselectItem: item atIndex: indexPath.row];
            
        }
        else {
            
            [indexSet addIndex: indexPath.row];
            [self setSelectedIndices: indexSet];
            
            if (self.delegate)
                [self.delegate menuViewController: self didSelectItem: item atIndex: indexPath.row];
            
        }
        
        [tableView reloadData];
        [tableView selectRowAtIndexPath: indexPath animated: NO scrollPosition: UITableViewScrollPositionNone];
        [tableView deselectRowAtIndexPath: indexPath animated: YES];
    }
    else {
        
        [self setSelectedIndex: indexPath.row];
        
        if (self.delegate)
            [self.delegate menuViewController: self didSelectItem: item atIndex: indexPath.row];
        
        [self.navigationController popViewControllerAnimated: YES];
    }
}


@end
