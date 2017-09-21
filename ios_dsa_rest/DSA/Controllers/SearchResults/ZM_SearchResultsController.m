    //
//  ZM_SearchResultsController.m
//
//  Created by Ben Gottlieb on 8/26/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "ZM_SearchResultsController.h"
#import "DSA_MediaDisplayViewController.h"



@implementation ZM_SearchResultsController
@synthesize results, resultsTableView;
@synthesize movieController;


+ (id) controllerWithSearchString: (NSString *) string andResults: (NSArray *) results {
	ZM_SearchResultsController			*controller = [[[ZM_SearchResultsController alloc] init] autorelease];
	
	controller.title = [NSString stringWithFormat: @"Search Results for “%@”", string];
	controller.results = results;
	return controller;
}


//=============================================================================================================================
#pragma mark ViewController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void) viewWillAppear: (BOOL) animated {
	[super viewWillAppear: animated];
	[self.navigationController setNavigationBarHidden: NO];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	self.resultsTableView.accessibilityLabel = @"Search Results Table";
	self.resultsTableView.accessibilityIdentifier = @"Search Results Table";
}

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSString								*cellIdentifier = @"cell";
	UITableViewCell							*cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	MMSF_ContentVersion	*content = [self.results objectAtIndex: indexPath.row];
	
	if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: cellIdentifier] autorelease];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.textLabel.text = content.Title;
	cell.detailTextLabel.text = @"";// content.breadcrumbPathString;
    
    CGSize thumbSize = CGSizeMake(40.f, 40.f);
    
    [content generateThumbnailSize:thumbSize completionBlock:^(UIImage *image) {
        cell.imageView.image = image;
    }];
    
    if (cell.imageView.image == nil) cell.imageView.image = [content tableCellImage];
	
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
	return 1;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
	return self.results.count;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	MMSF_ContentVersion	*contentItem = [self.results objectAtIndex: indexPath.row];
	
    if(contentItem) {
        DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controller];
        vc.sendDocumentTrackerNotifications = YES;
        vc.item = contentItem;
        vc.mediaDisplayViewControllerDelegate = (NSObject<DSA_MediaDisplayViewControllerDelegate>*)  self;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:!contentItem.isMovieFile completion:nil];
    }

	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}

///////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////
- (void) donePressed:(DSA_MediaDisplayViewController*) controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
