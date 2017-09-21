//
//  IP_ShoppingCartViewController.h
//  CareFusion
//
//  Created by Ben Gottlieb on 3/29/12.
//  Copyright 2012 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface IP_ShoppingCartViewController : UIViewController {

}

@property (retain, nonatomic) IBOutlet UITableView *cartTableView;
@property (nonatomic, retain) IBOutlet UIView *attachedDocumentsHeader, *linkedDocumentsHeader, *recentHeader;
@property (nonatomic, assign) IBOutlet UILabel *attachedDocumentsLabel, *linkedDocumentsLabel, *attachedSizelabel;
@property (nonatomic, retain) NSMutableArray *cartAttachments, *cartLinks, *recentItems;
@property (nonatomic, assign) IBOutlet UIToolbar *topToolbar;
+ (id) controller;

- (void) reloadCartDisplay: (BOOL) reloadTable;
- (void) setupToolbar;
@end
