//
//  LXReorderableCollectionViewFlowLayout.m
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//
//  Code is released under MIT license, see header.
//  Modified for Salesforce.com by Mike Close - July, 2014


#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "DSA_ContentShelvesContentItemCollectionViewCell.h"
#import "DSA_ContentShelfBackgroundView.h"
#import "DSA_CollectionViewSectionBackgroundLayoutAttributes.h"
#import "DSA_ContentShelvesModel.h"

// set to true for verbose logging
#define VerboseLogging_ViewFlowLayout 1

#define LX_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

static NSString * const kLXScrollingDirectionKey = @"LXScrollingDirection";
static NSString * const kLXCollectionViewKeyPath = @"collectionView";
NSString *const DSACollectionElementKindSectionBackground = @"DSACollectionElementKindSectionBackground";

@interface CADisplayLink (LX_userInfo)
@property (nonatomic, copy) NSDictionary *LX_userInfo;
@end

@implementation CADisplayLink (LX_userInfo)
- (void) setLX_userInfo:(NSDictionary *) LX_userInfo {
    objc_setAssociatedObject(self, "LX_userInfo", LX_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) LX_userInfo {
    return objc_getAssociatedObject(self, "LX_userInfo");
}
@end

@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)LX_rasterizedImage;

@end

@implementation UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIImage *)LX_rasterizedImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@interface LXReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) NSIndexPath *originalIndexPath;


@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDataSource> dataSource;
@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDelegateFlowLayout> delegate;

@end

@implementation LXReorderableCollectionViewFlowLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView {
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPressGesture:)];
    [_longPressGestureRecognizer setMinimumPressDuration:0.2];
    [_longPressGestureRecognizer setDelegate:self];
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    
    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
}

- (void)enableGestureRecognizers
{
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
}

- (void)disableGestureRecognizers
{
    [self.collectionView removeGestureRecognizer:_longPressGestureRecognizer];
    [self.collectionView removeGestureRecognizer:_panGestureRecognizer];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)applyCellLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    layoutAttributes.zIndex = 1;
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.alpha = 0.5;
    }else{
        layoutAttributes.alpha = 1.0;
    }
}

- (void)applySupplementaryViewLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.representedElementKind isEqualToString:DSACollectionElementKindSectionBackground]) {
        layoutAttributes.zIndex = 0;
    }
}

- (int)shelfIntersectingWithPoint:(CGPoint)point
{
    for (DSA_CollectionViewSectionBackgroundLayoutAttributes *attrs in self.itemAttributes)
    {
        if(CGRectContainsPoint(attrs.frame, point))
        {
            return attrs.indexPath.section;
        }
    }
    return NSNotFound;
}

- (id<LXReorderableCollectionViewDataSource>)dataSource {
    return (id<LXReorderableCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<LXReorderableCollectionViewDelegateFlowLayout>)delegate {
    return (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

- (void)invalidateLayoutIfNecessary {
    // newIndexPath is the indexPath that the item is currently being dragged to
    __block NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:self.currentView.center];
    
    // previousIndexPath is the indexPath that the item was most recently (temporarily) inserted during the drag
    __block NSIndexPath *previousIndexPath = [self selectedItemIndexPath];
    
    // originalIndexPath is the indexPath that the item started at when this drag sequence began
    NSIndexPath *originalIndexPath = [self originalIndexPath];
    BOOL protectedShelf = NO;
    
    // bomb out if we already know we didn't go anywhere
    if ([newIndexPath isEqual:previousIndexPath]) return;
    
    // if we don't have a newIndexPath, it's because we're not hovering over a cell.
    // we create the newIndexPath based on the section we're hovering in.
    if (newIndexPath == nil)
    {
        // we aren't hovering over a cell, so make the drop target the original location of the cell.
        int shelfUnderCursor = [self shelfIntersectingWithPoint:self.currentView.center];
        
        if (shelfUnderCursor != NSNotFound)
        {
            protectedShelf = ![self.delegate collectionView:self.collectionView layout:self sectionAtIndexCanBeChanged:shelfUnderCursor];
        }
        if (shelfUnderCursor != NSNotFound && !protectedShelf)
        {
            // we want to drop the item at the end of the section if it isn't being dropped on an item.
            int itemRow = [self.collectionView numberOfItemsInSection:shelfUnderCursor];
            
            // the number of items in the section isn't expanding if we're moving within the section, so subtract 1 for that.
            itemRow = (shelfUnderCursor == previousIndexPath.section) ? itemRow - 1 : itemRow;
            
            // behold the new indexPath
            newIndexPath = [NSIndexPath indexPathForItem:itemRow inSection:shelfUnderCursor];
#if VerboseLogging_ViewFlowLayout
            MMLog(@"\n\n*******  Reset newIndexPath.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                  originalIndexPath.section,
                  originalIndexPath.row,
                  previousIndexPath.section,
                  previousIndexPath.row,
                  newIndexPath.section,
                  newIndexPath.row,protectedShelf);
#endif
        }
        else
        {
            return;
        }
    }
    protectedShelf = ![self.delegate collectionView:self.collectionView layout:self sectionAtIndexCanBeChanged:newIndexPath.section];
    
    // now, if we aren't going anywhere, let's bomb out of this.
    if ([newIndexPath isEqual:previousIndexPath] || protectedShelf)
    {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf)
        {
            if (newIndexPath.section != originalIndexPath.section)
            {
                // we know the drag has left the original location, but did it just leave?
                if (previousIndexPath.section == originalIndexPath.section)
                {
                    // move the original item back to its original index path, regardless of whether we can copy here or not
                    if (previousIndexPath.row != originalIndexPath.row)
                    {
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"\n\n*******  We just left the original section, %d, and went to %d, but it wasn't the original indexPath.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              newIndexPath.section,
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row,
                              protectedShelf);
#endif
                        [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:originalIndexPath];
                        [[strongSelf collectionView] moveItemAtIndexPath:previousIndexPath toIndexPath:originalIndexPath];
                        strongSelf.selectedItemIndexPath = originalIndexPath;
                        return;
                    }
                    
                    // we just left the original section, so let's add another ghost item and undo any moves that were done within the original section
                    if ([strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath canCopyToIndexPath:newIndexPath])
                    {
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"\n\n*******  We just left the original section, %d, and went to %d.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              newIndexPath.section,
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row,
                              protectedShelf);
#endif
                        
                        // add the ghost
                        [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath willCopyToIndexPath:newIndexPath];
                        [[strongSelf collectionView] insertItemsAtIndexPaths:@[newIndexPath]];
                        strongSelf.selectedItemIndexPath = newIndexPath;
                    }else{
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"\n\n*******  We just left the original section, %d, and went to %d, but we can't copy here.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              newIndexPath.section,
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row,
                              protectedShelf);
#endif
                    }
                }else{
                    
                    // we didn't just leave the original section, we're moving from a section that isn't the original section, so move the ghost
                    if ([strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath])
                    {
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"\n\n*******  We're moving around outside the original index path.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row,
                              protectedShelf);
#endif
                        [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
                        [[strongSelf collectionView] moveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
                        strongSelf.selectedItemIndexPath = newIndexPath;
                    }else{
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"\n\n*******  We're moving around outside the original index path but we can't copy here.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row,protectedShelf);
#endif
                        if (![previousIndexPath isEqual:originalIndexPath]) [self removeItemFromIndexPath:previousIndexPath];
                        self.selectedItemIndexPath = originalIndexPath;
                    }
                }
            }else{
                // if we're moving from outside the original section to the original section, we remove the previous ghost.
                if (previousIndexPath.section != originalIndexPath.section)
                {
                    if ([strongSelf.dataSource collectionView:strongSelf.collectionView canRemoveItemAtIndexPath:previousIndexPath])
                    {
                        newIndexPath = originalIndexPath; //force us back to where we started
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"*******  We're moving back into the original section.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row,protectedShelf);
#endif
                        // remove the ghost
                        [strongSelf.dataSource collectionView:strongSelf.collectionView willRemoveItemAtIndexPath:previousIndexPath];
                        [[strongSelf collectionView] deleteItemsAtIndexPaths:@[previousIndexPath]];
                        
                        // now we're moving from the original index path to the new one
                        [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:originalIndexPath willMoveToIndexPath:newIndexPath];
                        [[strongSelf collectionView] moveItemAtIndexPath:originalIndexPath toIndexPath:newIndexPath];
                        strongSelf.selectedItemIndexPath = newIndexPath;
                    }
                }else{
                    if ([strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath])
                    {
#if VerboseLogging_ViewFlowLayout
                        MMLog(@"*******  We're moving around in the original section.\n   originalIndexPath: %d, %d\n   previousIndexPath: %d, %d\n   newIndexPath: %d, %d (%d)\n\n",
                              originalIndexPath.section,
                              originalIndexPath.row,
                              previousIndexPath.section,
                              previousIndexPath.row,
                              newIndexPath.section,
                              newIndexPath.row, protectedShelf);
#endif
                        [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
                        [[strongSelf collectionView] moveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
                        strongSelf.selectedItemIndexPath = newIndexPath;
                    }
                }
            }
        }
    } completion:^(BOOL finished) {}];
}

- (BOOL)removeItemFromIndexPath:(NSIndexPath*)indexPath
{
    if ([self.dataSource collectionView:self.collectionView canRemoveItemAtIndexPath:indexPath])
    {
        [self.dataSource collectionView:self.collectionView willRemoveItemAtIndexPath:indexPath];
        [[self collectionView] deleteItemsAtIndexPaths:@[indexPath]];
        self.selectedItemIndexPath = indexPath;
        return YES;
    }
    return NO;
}

- (void)invalidatesScrollTimer {
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
    if (!self.displayLink.paused) {
        LXScrollingDirection oldDirection = [self.displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
        
        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    self.displayLink.LX_userInfo = @{ kLXScrollingDirectionKey : @(direction) };
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(CADisplayLink *)displayLink {
    LXScrollingDirection direction = (LXScrollingDirection)[displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
    if (direction == LXScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.scrollingSpeed / LX_FRAMES_PER_SECOND);
    CGPoint translation = CGPointZero;
    
    switch(direction) {
        case LXScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f - contentInset.top;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y - contentInset.top;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f - contentInset.left;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x - contentInset.left;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        case LXScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    self.collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            if (currentIndexPath != nil)
            {
                [self setOriginalIndexPath:currentIndexPath];
                self.selectedItemIndexPath = currentIndexPath;
            }
            
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            DSA_ContentShelvesContentItemCollectionViewCell *collectionViewCell = (DSA_ContentShelvesContentItemCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];

            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            UIImageView *highlightedImageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            collectionViewCell.highlighted = NO;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[collectionViewCell LX_rasterizedImage]];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                     highlightedImageView.alpha = 0.0f;
                     imageView.alpha = 1.0f;
                 }
             }
             completion:^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     [highlightedImageView removeFromSuperview];
                     
                     if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                         [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                     }
                 }
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemFromIndexPath:toIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemFromIndexPath:[self originalIndexPath] toIndexPath:currentIndexPath];
                }
            }
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            CGPoint viewCenter = self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            
            [self invalidateLayoutIfNecessary];
            
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionUp];
                    } else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionDown];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
                case UICollectionViewScrollDirectionHorizontal: {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
                    } else {
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionRight];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
            }
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewLayout overridden methods

- (void)prepareLayout
{
    [super prepareLayout];
    
    self.itemAttributes = [NSMutableArray new];
    
    
    //    FIXME: We need to implement a custom background view *only* for section indexes that are associated with a customShelfConfig in contentShelfConfig.json
    //           This is currently hard-coded to only provide a custom background for section 0.
    
//    int section = 0;
    
    int sectionCount = [self.collectionView numberOfSections];
    [self registerClass:[DSA_ContentShelfBackgroundView class] forDecorationViewOfKind:DSACollectionElementKindSectionBackground];
    
    for(int section = 0; section < sectionCount; section++)
    {
        NSInteger lastIndex = [self.collectionView numberOfItemsInSection:section] - 1;
        CGRect frame = CGRectZero;
        
        // we can't just read self.sectionInset for some reason, now that we're using the delegate method to provide the layout with the section inset value.
        UIEdgeInsets sectionInsets = [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        
        if (lastIndex < 0)
        {
            // This is an empty shelf, so we need to set the frame based on the position of the header and the section insets.
            // Section insets are the only thing that gives height to an empty section in UICollectionViewFlowLayout
            UICollectionViewLayoutAttributes *headerAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            frame = CGRectMake(headerAttrs.frame.origin.x,
                               headerAttrs.frame.origin.y + headerAttrs.frame.size.height,
                               headerAttrs.frame.size.width,
                               sectionInsets.top + sectionInsets.bottom);
        }
        else
        {
            UICollectionViewLayoutAttributes *firstItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
            UICollectionViewLayoutAttributes *lastItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:lastIndex inSection:section]];
            frame = CGRectUnion(firstItem.frame, lastItem.frame);
            
            frame.origin.x -= sectionInsets.left;
            frame.origin.y -= sectionInsets.top;
            
            if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal)
            {
                frame.size.width += sectionInsets.left + sectionInsets.right;
                frame.size.height = self.collectionView.frame.size.height;
            }
            else
            {
                frame.size.width = self.collectionView.frame.size.width;
                frame.size.height += sectionInsets.top + sectionInsets.bottom;
            }
        }
        
        DSA_CollectionViewSectionBackgroundLayoutAttributes *attributes = [DSA_CollectionViewSectionBackgroundLayoutAttributes layoutAttributesForDecorationViewOfKind:DSACollectionElementKindSectionBackground withIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        attributes.model = [[DSA_ContentShelvesModel sharedModel] shelfAtIndex:section];
        attributes.zIndex = -1;
        attributes.frame = frame;
        [self.itemAttributes addObject:attributes];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    DSA_CollectionViewSectionBackgroundLayoutAttributes *attrs = nil;
    if ([elementKind isEqualToString:DSACollectionElementKindSectionBackground])
    {
        attrs = [self.itemAttributes objectAtIndex:indexPath.section];
    }
    return attrs;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributes = [NSMutableArray arrayWithArray:[super layoutAttributesForElementsInRect:rect]];
    
    for (UICollectionViewLayoutAttributes *allAttributes in attributes) {
        [self enhanceLayoutAttributes:allAttributes];
    }
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in self.itemAttributes)
    {
        if (!CGRectIntersectsRect(rect, layoutAttributes.frame))
            continue;
        
        [attributes addObject:layoutAttributes];
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    [self enhanceLayoutAttributes:layoutAttributes];
    
    return layoutAttributes;
}

- (void)enhanceLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyCellLayoutAttributes:layoutAttributes];
        } break;
        case UICollectionElementCategorySupplementaryView: {
            [self applySupplementaryViewLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

- (void)cancelMoveToIndex:(NSIndexPath *)indexPath
{
    [self.collectionView deleteItemsAtIndexPaths:@[self.selectedItemIndexPath]];
    [self animateDraggedCellToIndexPath:indexPath];
}

- (void)finalizeMoveToIndex:(NSIndexPath *)indexPath
{
    if (indexPath.section != self.originalIndexPath.section)
    {
        [self.collectionView deleteItemsAtIndexPaths:@[self.originalIndexPath]];
    }
    [self animateDraggedCellToIndexPath:indexPath];
}

- (void)finalizeCopyToIndex:(NSIndexPath *)indexPath
{
    [self animateDraggedCellToIndexPath:indexPath];
}

- (void)animateDraggedCellToIndexPath:(NSIndexPath*)indexPath
{
    self.selectedItemIndexPath = nil;
    self.currentViewCenter = CGPointZero;
    
    UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    [UIView
     animateWithDuration:0.3
     delay:0.0
     options:UIViewAnimationOptionBeginFromCurrentState
     animations:^{
         __strong typeof(self) strongSelf = weakSelf;
         if (strongSelf) {
             strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
             strongSelf.currentView.center = layoutAttributes.center;
         }
     }
     completion:^(BOOL finished) {
         __strong typeof(self) strongSelf = weakSelf;
         if (strongSelf) {
             [strongSelf.currentView removeFromSuperview];
             strongSelf.currentView = nil;
             [strongSelf invalidateLayout];
             
             if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                 [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:indexPath];
             }
         }
     }];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //!!! seems like this might want to get pushed up the chain via the delegate or something
    BOOL result = YES;
    if (gestureRecognizer == self.longPressGestureRecognizer)
    {
        result = ![touch.view isKindOfClass:[UITextField class]];
    }
    return result;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kLXCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
        }
    }
}

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

#pragma mark - Depreciated methods

#pragma mark Starting from 0.1.0
- (void)setUpGestureRecognizersOnCollectionView {
    // Do nothing...
}

@end
