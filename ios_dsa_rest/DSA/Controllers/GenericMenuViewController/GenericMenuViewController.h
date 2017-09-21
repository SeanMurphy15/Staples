//
//  GenericMenuViewController.h
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol GenericMenuViewControllerDelegate;



@interface GenericMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <GenericMenuViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) NSArray *menuValues;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic) NSIndexSet *selectedIndices;
@property (weak, nonatomic) IBOutlet UITableView *menuTableView;
@property (nonatomic, strong) NSString *field;
@property (nonatomic) NSInteger fieldIndex;

@end




@protocol GenericMenuViewControllerDelegate <NSObject>

- (void) menuViewController: (GenericMenuViewController *) controller didSelectItem: (NSString *) item atIndex: (NSInteger) index;

@optional
- (void) menuViewController: (GenericMenuViewController *) controller didDeselectItem: (NSString *) item atIndex: (NSInteger) index;

@end