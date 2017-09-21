//
//  DSA_ContentShelvesCollectionViewCell.m
//  DSA
//
//  Created by Mike Close on 7/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelvesContentItemCollectionViewCell.h"

@interface PaddedButton: UIButton

+ (id)paddedButton;

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;

@end

@implementation PaddedButton

+ (id)paddedButton {
    return (PaddedButton *) [PaddedButton buttonWithType:UIButtonTypeCustom];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect relativeFrame = self.bounds;
    UIEdgeInsets hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

@end

@interface DSA_ContentShelvesContentItemCollectionViewCell()
@property (nonatomic, strong) UILabel                   *cellTitleLabel;
@property (nonatomic, strong) MMSF_ContentVersion       *contentItem;
@property (nonatomic, strong) UIImageView               *thumbnailImageView;
@property (nonatomic, strong) PaddedButton              *deleteButton;
@property (nonatomic, strong) NSString                  *state;
@property (nonatomic)         CGRect                     thumbnailFrame;
@property (nonatomic, strong) NSMutableArray            *layoutConstraints;
@property (nonatomic, strong) NSMutableArray            *contentViewLayoutConstraints;
@property (nonatomic, strong) NSMutableArray            *backgroundBorderLayoutConstraints;
@property (nonatomic, strong) NSMutableArray            *backgroundLayoutConstraints;
@end

@implementation DSA_ContentShelvesContentItemCollectionViewCell

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
        [[self contentView] setBackgroundColor:[UIColor clearColor]];
        
        [self createViews];
        
        [self setState:[DSA_ContentShelvesModel state]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged:) name:kNotification_ContentShelvesStateChanged object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setShelfModel:(DSA_ContentShelfModel *)shelfModel
{
    // setting the model represents the creation or reuse of an existing cell.
    if (_shelfModel == shelfModel) return;
    _shelfModel = shelfModel;
    [self setShelfConfig:[[self shelfModel] shelfConfig]];
    [self setNeedsUpdateConstraints];
    [self setNeedsDisplay];
}

- (void)createViews
{
    [self setThumbnailImageView:[[UIImageView alloc] init]];
    self.thumbnailImageView.opaque = NO;
    [[self contentView] addSubview:[self thumbnailImageView]];
    
    [self setDeleteButton:[PaddedButton paddedButton]];
    [self.deleteButton setImage:[UIImage imageNamed:@"shelfHeaderDeleteButton"] forState:UIControlStateNormal];
    [[self deleteButton] addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
    [[self contentView] addSubview:[self deleteButton]];
    [[self deleteButton] setHidden:YES];
    
    [self setCellTitleLabel:[[UILabel alloc] init]];
    [[self contentView] addSubview:[self cellTitleLabel]];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [[self cellTitleLabel] setTextAlignment:NSTextAlignmentCenter];
    [[self cellTitleLabel] setTextColor:[[self shelfConfig] thumbnailLabelColor]];
    UIFont *cellTitleFont = [UIFont fontWithName:[[self shelfConfig] thumbnailLabelFontName] size:[[self shelfConfig] thumbnailLabelFontSize]];
    [[self cellTitleLabel] setFont:cellTitleFont];
    [self generateThumbnail];
}

- (void)updateConstraints
{
    if (self.layoutConstraints != nil)
    {
        [super updateConstraints];
        return;
    }
    
    [self setLayoutConstraints:[NSMutableArray array]];
    [self setContentViewLayoutConstraints:[NSMutableArray array]];
    [self setBackgroundBorderLayoutConstraints:[NSMutableArray array]];
    [self setBackgroundLayoutConstraints:[NSMutableArray array]];
    
    // Thumbnail ImageView Constraints
    [[self thumbnailImageView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    id thumbnailYConstraint = [NSLayoutConstraint constraintWithItem:[self thumbnailImageView]
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:[self contentView]
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0
                                                            constant:self.shelfConfig.minimumLineSpacing];
    
    id thumbnailXConstraint = [NSLayoutConstraint constraintWithItem:[self thumbnailImageView]
                                                           attribute:NSLayoutAttributeCenterX
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:[self contentView]
                                                           attribute:NSLayoutAttributeCenterX
                                                          multiplier:1.0
                                                            constant:0.0];
    
    [[self contentView] addConstraints:@[thumbnailYConstraint, thumbnailXConstraint]];
    [[self backgroundLayoutConstraints] addObjectsFromArray:@[thumbnailYConstraint, thumbnailXConstraint]];
    
    // Delete Button Constraints
    [[self deleteButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSArray *deleteRightConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"[delete(15)]|"
                                                                             options:(NSLayoutFormatAlignAllTrailing & NSLayoutFormatDirectionRightToLeft)
                                                                             metrics:nil
                                                                               views:@{@"delete": [self deleteButton]}];
    
    NSArray *deleteTopConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[delete(15)]"
                                                                           options:(NSLayoutFormatAlignAllTrailing & NSLayoutFormatDirectionRightToLeft)
                                                                           metrics:nil
                                                                             views:@{@"delete": [self deleteButton]}];
    
    [self addConstraints:deleteRightConstraint];
    [self addConstraints:deleteTopConstraint];
    [[self layoutConstraints] addObjectsFromArray:deleteRightConstraint];
    [[self layoutConstraints] addObjectsFromArray:deleteTopConstraint];
    
    // Cell Label Constraints
    [[self cellTitleLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
    id labelXConstraint = [NSLayoutConstraint constraintWithItem:[self cellTitleLabel]
                                                       attribute:NSLayoutAttributeCenterX
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:self
                                                       attribute:NSLayoutAttributeCenterX
                                                      multiplier:1.0
                                                        constant:0.0];
    
    id labelYConstraint = [NSLayoutConstraint constraintWithItem:[self cellTitleLabel]
                                                       attribute:NSLayoutAttributeBottom
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:self
                                                       attribute:NSLayoutAttributeBottom
                                                      multiplier:1.0
                                                        constant:-8.0];
    
    id labelWidthConstraint = [NSLayoutConstraint constraintWithItem:[self cellTitleLabel]
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeWidth
                                                          multiplier:1.0
                                                            constant:0.0];
    
    [self addConstraints:@[labelYConstraint,labelXConstraint,labelWidthConstraint]];
    [[self layoutConstraints] addObjectsFromArray:@[labelYConstraint,labelXConstraint,labelWidthConstraint]];
    [super updateConstraints];
}

- (void)setItemId:(NSString *)itemId
{
    _itemId = itemId;
    
    // When UICollectionView reuses cells, this method is the only "initialization" notice we get.
    // Sometimes animation is killed during drag and drop, so we're forcing the cell to configure itself for
    // the global edit state again.
//    [self setState:kContentShelvesStateNormal];
    [self setState:[DSA_ContentShelvesModel state]];
    
    self.contentItem = [[DSA_ContentShelvesModel sharedModel] contentItemById:[self itemId]];
    NSString * customDeleteButtonAccessibilityLabel = [NSString stringWithFormat:@"%@_Delete", self.contentItem.Title];
    [_deleteButton setAccessibilityLabel:customDeleteButtonAccessibilityLabel];
    [self.contentView setAccessibilityLabel:self.contentItem.Title];
    
    [self setNeedsDisplay];
}

- (void)generateThumbnail
{
    [[self cellTitleLabel] setText:[self.contentItem Title]];
    
    __weak typeof(self) weakSelf = self;
    [self.contentItem generateThumbnailSize:[[self shelfConfig] thumbnailCGSize]
                       backgroundColor:self.shelfConfig.thumbnailBackgroundColor
                           borderColor:self.shelfConfig.thumbnailBorderColor
                               outsets:self.shelfConfig.thumbnailBorderOutsets
                       completionBlock:^(UIImage *image) {
                           weakSelf.thumbnailImageView.image = image;
                       }];
    
    self.thumbnailImageView.hidden = NO;
}

- (void)prepareForReuse
{
    self.thumbnailImageView.hidden = YES;
    self.deleteButton.hidden = YES;
}



#pragma mark - User Interaction Handlers
- (void)longPressed:(UILongPressGestureRecognizer *)recognizer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ContentShelvesStateChanged object:self userInfo:@{@"state": kContentShelvesStateEdit}];
}

- (void)stopReorder:(UIGestureRecognizer *)recognizer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_ContentShelvesStateChanged object:self userInfo:@{@"state": kContentShelvesStateNormal}];
}

- (void)delete:(id)sender
{
    if (self.shelfConfig.confirmItemDelete)
    {
        [self showConfirmDeleteAlert];
    } else {
        [self.shelfModel removeContentItemId:self.itemId updateLayout:YES animated:YES];
    }
}

- (void)showConfirmDeleteAlert {
    NSString *message = [NSString stringWithFormat:@"Would you like to delete %@?", self.contentItem.Title];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please Confirm" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [alertView setTag:kContentShelvesConfirmDeleteAlertTag];
    [alertView show];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIAlertViewDelegate And Related Methods
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag != kContentShelvesConfirmDeleteAlertTag) return;
    switch (buttonIndex) {
        case 1:
            // go ahead and delete the item
            [self.shelfModel removeContentItemId:self.itemId updateLayout:YES animated:YES];
            break;
        default:
            break;
    }
}


#pragma mark - State Management
- (void)stateChanged:(NSNotification *)note
{
    [self setState:[[note userInfo] objectForKey:@"state"]];
}

- (void)setState:(NSString *)state
{
    _state = state;
    
    if ([state isEqualToString:kContentShelvesStateEdit])
    {
        [self configureForReorderState];
    }
    
    if ([state isEqualToString:kContentShelvesStateNormal])
    {
        [self configureForNormalState];
    }
}

- (void)configureForNormalState
{
    [[self deleteButton] setHidden:YES];
//    [self stopWiggling];
}

- (void)configureForReorderState
{
    if ([[self shelfConfig] canRemoveContent] && [[self shelfModel] canModifyShelf])
    {
        [[self deleteButton] setHidden:NO];
    }
//    [self startWiggling];
}



#pragma mark - Animation
-(void)startWiggling {
    [UIView animateWithDuration:0
                     animations:^{
                         [self.thumbnailImageView.layer addAnimation:[self shakeAnimation] forKey:@"rotation"];
                         self.thumbnailImageView.transform = CGAffineTransformIdentity;
                     }];
}

-(void)stopWiggling {
    [self.thumbnailImageView.layer removeAllAnimations];
}

- (CAAnimation*)shakeAnimation
{
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CGFloat wobbleAngle = 0.03f;
    
    NSValue* valLeft = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(wobbleAngle, 0.0f, 0.0f, 1.0f)];
    NSValue* valRight = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-wobbleAngle, 0.0f, 0.0f, 1.0f)];
    animation.values = [NSArray arrayWithObjects:valLeft, valRight, nil];
    
    animation.autoreverses = YES;
    animation.duration = 0.09;
    animation.repeatCount = HUGE_VALF;
    
    return animation;
}

NSUInteger const kContentShelvesConfirmDeleteAlertTag = 2;
@end
