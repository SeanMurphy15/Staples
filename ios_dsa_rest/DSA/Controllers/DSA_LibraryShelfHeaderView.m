//
//  ZM_LibraryShelfHeaderView.m
//  Zimmer
//
//  Created by Ben Gottlieb on 5/12/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "DSA_LibraryShelfHeaderView.h"
#import "DSA_FavoriteShelf.h"
#import "DSA_CreateFavoriteShelfController.h"
#import "DSA_FavoritesViewController.h"

@interface DSA_LibraryShelfHeaderView ()
@property (nonatomic, strong) UILabel* titleLabel;
@end

@implementation DSA_LibraryShelfHeaderView

- (id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.colors = [NSArray arrayWithObjects:
                       [UIColor colorWithHexString:@"5176a9"],
                       [UIColor colorWithHexString:@"003781"],
                                 nil];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.titleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [DSA_LibraryShelfHeaderView titleFont];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.titleLabel];
        
        UIGestureRecognizer		*recog = [[[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(headerLongPressed:)] autorelease];
        [self addGestureRecognizer: recog];
    }
    
    return self;
}

//=============================================================================================================================
#pragma mark actions

- (void) deleteFavoriteShelf: (id) sender {
	UIActionSheet		*sheet = [[[UIActionSheet alloc] initWithTitle: nil delegate: self cancelButtonTitle: @"Cancel" destructiveButtonTitle: @"Delete Shelf" otherButtonTitles: nil] autorelease];
				
	[sheet showFromRect: [sender bounds] inView: sender animated: YES];
}

- (void)actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		[DSA_FavoriteShelf deleteShelf: self.title];
	}
}

- (void) addNewFavoriteShelf: (id) sender {
	[NSObject performBlock: ^{
		[DSA_CreateFavoriteShelfController showFromButton: sender withItemToAdd: nil];
	} afterDelay: [DSA_CreateFavoriteShelfController delayForScrollAdjustmentWithView: self] ? 0.35 : 0.0];
}

+ (UIFont *) titleFont {
	return [UIFont boldSystemFontOfSize: 16];
}

- (void) setIsFavoriteShelfHeader: (BOOL) newIsFavoriteShelfHeader {
	_isFavoriteShelfHeader = newIsFavoriteShelfHeader;
	
	if (newIsFavoriteShelfHeader) {
		if (self.deleteButton == nil) {
			self.deleteButton = [UIButton buttonWithType: UIButtonTypeCustom];
			[self.deleteButton setImage: [UIImage imageNamed: @"close_grey.png"] forState: UIControlStateNormal];
			self.deleteButton.frame = CGRectMake(self.bounds.size.width - (self.bounds.size.height+5), 0, self.bounds.size.height, self.bounds.size.height);
			self.deleteButton.imageView.contentMode = UIViewContentModeCenter;
            self.deleteButton.alpha = 0.75;
			self.deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;// | UIViewAutoresizingFlexibleHeight;
			[self.deleteButton addTarget: self action: @selector(deleteFavoriteShelf:) forControlEvents: UIControlEventTouchUpInside];
			self.deleteButton.showsTouchWhenHighlighted = YES;
			[self addSubview: self.deleteButton];
		}
	} else {
		[self.deleteButton removeFromSuperview];
		self.deleteButton = nil;
	}
}

- (void) setIsCreateNewShelfHeader: (BOOL) newIsCreateNewShelfHeader {
	_isCreateNewShelfHeader = newIsCreateNewShelfHeader;

	if (newIsCreateNewShelfHeader) {
		UIFont					*font = [DSA_LibraryShelfHeaderView titleFont];
		NSString				*label = @"Create New Playlist...";
        CGSize size = [label sizeWithAttributes:@{NSFontAttributeName:font}];

		self.title = nil;
		if (self.addButton == nil) {
			float					width = 400;
			
			self.addButton = [UIButton buttonWithType: UIButtonTypeCustom];
			self.addButton.frame = CGRectMake((self.bounds.size.width - width) / 2, 0, width, self.bounds.size.height);
			self.addButton.titleLabel.font = font;
			[self.addButton setTitleColor: [UIColor grayColor] forState: UIControlStateNormal];
			self.addButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
			self.addButton.backgroundColor = [UIColor clearColor];
			self.addButton.showsTouchWhenHighlighted = YES;
			[self.addButton addTarget: self action: @selector(addNewFavoriteShelf:) forControlEvents: UIControlEventTouchUpInside];
			[self.addButton setTitle: label forState: UIControlStateNormal];
            [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			[self addSubview: self.addButton];

			UIImageView			*addImageView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"icon-add.png"]] autorelease];
			addImageView.center = CGPointMake((self.addButton.bounds.size.width - (size.width + 30)) / 2, self.addButton.bounds.size.height / 2);
			[self.addButton addSubview: addImageView];
		}
	} else {
		[self.addButton removeFromSuperview];
		self.addButton = nil;
	}
}

- (void) setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = _title;
}

- (void) headerLongPressed:(UIGestureRecognizer*) recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        if (!_isCreateNewShelfHeader)
        {
            [NSObject performBlock: ^{
                [DSA_CreateFavoriteShelfController showFromRect:self.titleLabel.frame
                                                         inView:self forRename:self.titleLabel.text];
            } afterDelay: [DSA_CreateFavoriteShelfController delayForScrollAdjustmentWithView: self] ? 0.35 : 0.0];
        }
    }
}
@end
