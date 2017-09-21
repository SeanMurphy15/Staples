//
//  ZM_AddFavoriteViewController.h
//  Zimmer
//
//  Created by Chris Cieslak on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMSF_ContentVersion;

@interface DSA_AddFavoriteViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) MMSF_ContentVersion* item;

@end