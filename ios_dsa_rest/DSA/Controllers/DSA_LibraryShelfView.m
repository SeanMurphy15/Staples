//
//  ZM_LibraryShelfView.m
//  Zimmer
//
//  Created by Ben Gottlieb on 5/7/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "DSA_LibraryShelfView.h"
#import "MMSF_ContentVersion.h"
#import "DSA_LibraryShelfItemView.h"
#import "DSA_FavoriteShelf.h"

@implementation DSA_LibraryShelfView
@synthesize  contentItems, viewController, shadowView, contentView, shelfName;

+ (NSString *) identifier { return @"shelf"; }

+ (id) tableCellWithContentItems: (NSArray *) contentItems inViewController: (UIViewController *) controller {
	UITableViewCell				*cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: [self identifier]];
	DSA_LibraryShelfView			*view = [[DSA_LibraryShelfView alloc] initWithFrame: cell.contentView.bounds];
	
	[[NSNotificationCenter defaultCenter] addObserver: view selector: @selector(favoriteChanged:) name: kNotification_FavoriteAssigned object: nil];
	view.viewController = controller;
	view.backgroundColor = [UIColor clearColor];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[cell.contentView addSubview: view];
	view.contentItems = contentItems;
	
	return cell;
}

- (void) setContentItems: (NSArray *) newContentItems {
//	CGFloat					left = 0;
	
	[contentItems autorelease];
	contentItems = newContentItems;
	
	if (self.contentView)
		[self.contentView reloadData];
	else {
		self.contentView = [[SA_LazyLoadingScrollView alloc] initWithFrame: self.bounds];
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.contentView.dataSource = self;
		self.contentView.pageWidth = 200;
		[self addSubview: self.contentView];
	}
}

- (void) favoriteChanged: (NSNotification *) note {
	if (self.shelfName == nil) return;
	
	NSArray				*shelfItems = [DSA_FavoriteShelf itemsForShelfName: self.shelfName];
	
	if (![self.contentItems isEqualToArray: shelfItems]) {
		self.contentItems = shelfItems;
		[self.contentView reloadData];
	}
}

- (NSInteger) numberOfPagesInScrollView: (SA_LazyLoadingScrollView *) lazyLoadingScrollView {
	return self.contentItems.count;
}

- (SA_LazyLoadingScrollViewPage *) pageViewAtIndex: (NSInteger) index {
	DSA_LibraryShelfItemView			*view = [DSA_LibraryShelfItemView viewWithParent: self];

	view.viewController = self.viewController;
	view.pageIndex = index;
	return view;
}

- (void) configurePageView: (SA_LazyLoadingScrollViewPage *) pageView forIndex: (NSInteger) index;
{
    NSLog(@"configurePageView:forIndex: called by SA_LazyLoadingScrollViewPage");
}
- (void) scrollView: (SA_LazyLoadingScrollView *) scrollView didChangeMainIndexTo: (NSInteger) index;
{
    NSLog(@"scrollView:didChangeMainIndexTo: called by SA_LazyLoadingScrollViewPage");
}

//
//	[self removeAllSubviews];
//	
//	for (SF_ContentItem *item in newContentItems) {
//		ZM_LibraryShelfItemView			*view = [ZM_LibraryShelfItemView viewWithContentItem: item];
//		view.center = CGPointMake(view.bounds.size.width / 2 + left, view.bounds.size.height / 2);
//		view.viewController = self.viewController;
//		[self addSubview: view];
//		left += view.bounds.size.width;
//		//if (left >= self.bounds.size.width) break;
//	}
//	
//	self.contentSize = CGSizeMake(left, self.bounds.size.height);
//	if (self.shadowView == nil && newContentItems.count) {
//		self.shadowView = [[[UIImageView alloc] initWithFrame: CGRectMake(0, 0, 44, self.bounds.size.height)] autorelease];
//		self.shadowView.image = [UIImage imageNamed: @"thumbnail-last-image-shadow.png"];
//		[self addSubview: self.shadowView];
//		self.shadowView.contentMode = UIViewContentModeScaleAspectFit;
//		self.shadowView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
//	} else if (newContentItems.count) {
//		[self addSubview: self.shadowView];
//	} else {
//		[self.shadowView removeFromSuperview];
//	}
//	
//	self.shadowView.center = CGPointMake(left + self.shadowView.bounds.size.width / 2, self.shadowView.bounds.size.height / 2);
//}

@end


@implementation UITableViewCell (ZM_LibraryShelfView) 
- (void) setContentItems: (NSArray *) items {
	if (self.contentView.subviews.count == 0) return;
	
	DSA_LibraryShelfView				*view = [self.contentView.subviews objectAtIndex: 0];
	
	view.contentItems = items;
}

- (void) setShelfName: (NSString *) name {
	if (self.contentView.subviews.count == 0) return;
	
	DSA_LibraryShelfView				*view = [self.contentView.subviews objectAtIndex: 0];
	
	view.shelfName = name;
}
@end