//
//  ZM_LibraryShelfItemView.m
//  Zimmer
//
//  Created by Ben Gottlieb on 5/7/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "DSA_LibraryShelfItemView.h"
#import "MMSF_ContentVersion.h"
#import "DSA_LibraryShelfView.h"
#import "DSA_MediaDisplayViewController.h"
#import "DSA_FavoriteShelf.h"

//166x200

@implementation DSA_LibraryShelfItemView
@synthesize contentItem, viewController, parent;

+ (BOOL) showThumbnailImages {
	return YES;
	static BOOL				showImages = NO, setup = NO;
	
	if (!setup) {
		showImages = !RUNNING_ON_50;
	}
	
	return showImages;
}

+ (id) viewWithParent: (DSA_LibraryShelfView *) parent {
	DSA_LibraryShelfItemView				*view = [self viewWithContentItem: nil];
	
	view.parent = parent;
	return view;
}

+ (id) viewWithContentItem: (MMSF_ContentVersion *) item {
	DSA_LibraryShelfItemView			*view = [[[self alloc] initWithFrame: CGRectMake(0, 0, 200, 200)] autorelease];
	
	view.bounds = CGRectMake(0, 0, [self size].width, [self size].height);
	view.contentItem = item;
	view.clipsToBounds = YES;
//	[view addTarget: view action: @selector(documentTapped) forControlEvents: UIControlEventTouchUpInside];
    
	UIGestureRecognizer		*recog = [[[UILongPressGestureRecognizer alloc] initWithTarget: view action: @selector(documentPressed:)] autorelease];
	[view addGestureRecognizer: recog];
	
	recog = [[[UITapGestureRecognizer alloc] initWithTarget: view action: @selector(documentTapped)] autorelease];
	[view addGestureRecognizer: recog];
	return view;
}

+ (CGSize) size {
	return CGSizeMake(166, 200);
}

//=============================================================================================================================
#pragma mark - Properties

- (void) setPageIndex: (NSInteger) pageIndex {
	[super setPageIndex: pageIndex];
	if (pageIndex < self.parent.contentItems.count) 
		self.contentItem = [self.parent.contentItems objectAtIndex: pageIndex];
	else
		self.contentItem = nil;
}

- (void) setContentItem: (MMSF_ContentVersion *) newContentItem {
	if (contentItem == newContentItem) return;
	[contentItem autorelease];
	contentItem = newContentItem;
	[self setNeedsDisplay];
}

- (void) drawRect: (CGRect) rect {
	CGRect				bounds = self.bounds;
//	CGRect				textArea = CGRectMake(0, 136, bounds.size.width, bounds.size.height - 136);
	
	[[UIColor whiteColor] setFill];
	UIRectFill(bounds);
    
    //hack - force object into known good context
    // self.contentItem = (id) [[[DSARestClient sharedInstance] context] objectWithID: self.contentItem.objectID];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"Id = %@",self.contentItem.objectIDString];
    MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
    self.contentItem = (id) [moc anyObjectOfType:@"ContentVersion" matchingPredicate:pred];
	
	if (self.contentItem) LOG(@"Drawing: %@", self.contentItem.Title);
	
	if ([DSA_LibraryShelfItemView showThumbnailImages]) {
		UIImage				*thumbnail;
		
        thumbnail = self.contentItem.thumbnailImage;
        
		if (thumbnail)
        {
            CGSize sz = thumbnail.size;
            CGFloat scale = 164/sz.height;
            if (scale > 1) scale = 198/sz.width;
            
            CGFloat width = ceil(sz.width * scale);
            CGFloat height = ceil(sz.height * scale);
            
            CGRect thumbFrame = CGRectMake(((bounds.size.width-width)/2)+1,  ((164-height)/2)+1, width, height);
            CGRect frameFrame = CGRectInset(thumbFrame, -1, -1);
            
            LOG(@"thumbframe = %@",NSStringFromCGRect(thumbFrame));
            LOG(@"frameframe = %@",NSStringFromCGRect(frameFrame));
            
            UIColor *color = [UIColor colorWithHexString:@"ACACAC"];
            [color set];
            
            UIRectFrame(frameFrame);
            
            CGRect r =  CGRectMake(0, 0, bounds.size.width, 166);
            [thumbnail drawInRect: r withContentMode: UIViewContentModeScaleAspectFit];
        }
        else
        {
            thumbnail = [self.contentItem tableCellImage];
            CGRect thumbFrame = CGRectMake(0,38 , bounds.size.width, 80);
            [thumbnail drawInRect: thumbFrame withContentMode: UIViewContentModeScaleAspectFit];
        }
	}
	
	UIRectFrame(CGRectInset(bounds, 0, 0));
	
//	if (self.contentItem.isProtectedContent)
//		[[UIColor redColor] setFill];
//	else
//		[[UIColor whiteColor] setFill];
	
    CGRect titleRect = CGRectMake(0, 166, self.bounds.size.width, 34);
    titleRect = CGRectInset(titleRect, 1, 0);
    
    UIColor *color = [UIColor colorWithHexString:@"C2CFE1"];
    [color set];

    CGContextFillRect(UIGraphicsGetCurrentContext(), titleRect);
    
    if (self.contentItem.Title)
    {
        [[UIColor darkTextColor] set];
        titleRect = CGRectInset(titleRect, 2, 2);
        
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12], NSParagraphStyleAttributeName:paragraphStyle};
        [self.contentItem.Title drawInRect:titleRect withAttributes:attributes];
    }
}

- (void) documentTapped {
    DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controller];
    vc.sendDocumentTrackerNotifications = YES;
    vc.item = self.contentItem;
    vc.mediaDisplayViewControllerDelegate = (NSObject<DSA_MediaDisplayViewControllerDelegate>*) self;
    [viewController.navigationController pushViewController:vc animated:NO];

}

- (void) documentPressed:(UIGestureRecognizer*) sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        UIActionSheet		*sheet = [[[UIActionSheet alloc] initWithTitle: nil
                                                            delegate: self
                                                   cancelButtonTitle: @"Cancel"
                                              destructiveButtonTitle: @"Delete Item"
                                                   otherButtonTitles: nil] autorelease];
        
        CGRect r = self.bounds;
        r = CGRectInset(r, 50, 50);
        [sheet showFromRect: r inView: self animated: YES];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [DSA_FavoriteShelf removeContentItem:self.contentItem fromShelf:self.parent.shelfName];
    }
}

- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    [viewController dismissViewControllerAnimated:YES completion:nil];

}

@end
