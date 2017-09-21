//
//  ZM_SearchResultsController.h
//
//  Created by Ben Gottlieb on 8/26/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ZM_SearchResultsController : UIViewController {

}

@property (nonatomic, readwrite, weak) IBOutlet UITableView *resultsTableView;

@property (nonatomic, readwrite, strong) NSArray *results;
@property (nonatomic, readwrite, strong) MPMoviePlayerViewController *movieController;


+ (id) controllerWithSearchString: (NSString *) string andResults: (NSArray *) results;

@end
