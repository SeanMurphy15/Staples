//
//  DSA_ContentShelvesHeaderReusableView.m
//  DSA
//
//  Created by Mike Close on 7/2/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelvesSupplementaryReusableView.h"

@interface DSA_ContentShelvesSupplementaryReusableView()
@property (strong, nonatomic) NSArray           *backgroundColors;
@property (strong, nonatomic) NSArray           *backgroundColorLocations;
@property (strong, nonatomic) UIView            *backgroundGradientView;
@property (strong, nonatomic) UIView            *borderView;
@property (strong, nonatomic) NSArray           *borderThickness;
@property (strong, nonatomic) UIColor           *borderColor;
@end


@implementation DSA_ContentShelvesSupplementaryReusableView

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setBackgroundGradientView:[[UIView alloc] initWithFrame:frame]];
        [[self backgroundGradientView] setBackgroundColor:[UIColor clearColor]];
        [self insertSubview:[self backgroundGradientView] atIndex:0];
    }
    return self;
}

- (void)setShelfModel:(DSA_ContentShelfModel *)shelfModel
{
    _shelfModel = shelfModel;
    [self setShelfConfig:[[self shelfModel] shelfConfig]];
    NSArray *backgroundColors = [[self shelfConfig] sectionBackgroundColors];
    NSArray *backgroundColorLocations = [[self shelfConfig] sectionBackgroundColorLocations];
    [self setBackgroundColors:backgroundColors andLocations:backgroundColorLocations];
    
    // clear layout constraints on "self"
    if ([self layoutConstraints] != nil)
    {
        if ([[self layoutConstraints] count] > 0) [self removeConstraints:[self layoutConstraints]];
        [[self layoutConstraints] removeAllObjects];
    }
    else
    {
        [self setLayoutConstraints:[NSMutableArray array]];
    }
    
    [self setNeedsUpdateConstraints];
    [self setNeedsDisplay];
}

- (void)setBackgroundColors:(NSArray *)colors andLocations:(NSArray *)locations;
{
    if (colors == _backgroundColors) return;
    if (colors.count < 2) return;
    if (colors.count > 1 && colors.count != locations.count) return;
    
    if (colors.count == 1)
    {
        [self setBackgroundColor:[_backgroundColors objectAtIndex:0]];
        _backgroundColors = colors;
    }
    else
    {
        NSMutableArray *cgColors = [NSMutableArray array];
        [colors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIColor *uicolor = (UIColor*)obj;
            [cgColors addObject:(id)[uicolor CGColor]];
        }];
        _backgroundColors = cgColors;
        _backgroundColorLocations = locations;
    }
}

- (void)setBorderThickness:(NSArray *)borderThickness color:(UIColor *)borderColor
{
    if ([self borderView] == nil)
    {
        [self setBorderView:[[UIView alloc] init]];
        [self insertSubview:[self borderView] belowSubview:[self backgroundGradientView]];
        [[self borderView] setBackgroundColor:borderColor];
    }
    _borderThickness = borderThickness;
    _borderColor = borderColor;
    [self setNeedsDisplay];
}

- (void)updateConstraints
{
    NSInteger topBorder = 0;
    NSInteger rightBorder = 0;
    NSInteger bottomBorder = 0;
    NSInteger leftBorder = 0;
    
    if ([self borderView] != nil)
    {
        // border constraints
        [[self borderView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSArray *borderHorizConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[bg]|"
                                                                                  options:(NSLayoutFormatAlignmentMask & NSLayoutFormatDirectionMask)
                                                                                  metrics:nil
                                                                                    views:@{@"bg": [self borderView]}];
        
        NSArray *borderVertConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bg]|"
                                                                                 options:(NSLayoutFormatAlignmentMask & NSLayoutFormatDirectionMask)
                                                                                 metrics:nil
                                                                                   views:@{@"bg": [self borderView]}];
        [self addConstraints:borderHorizConstraints];
        [self addConstraints:borderVertConstraints];
        [[self layoutConstraints] addObjectsFromArray:borderHorizConstraints];
        [[self layoutConstraints] addObjectsFromArray:borderVertConstraints];
        
        topBorder = [[[self borderThickness] objectAtIndex:0] integerValue];
        rightBorder = [[[self borderThickness] objectAtIndex:1] integerValue];
        bottomBorder = [[[self borderThickness] objectAtIndex:2] integerValue];
        leftBorder = [[[self borderThickness] objectAtIndex:3] integerValue];
    }
    
    // background constraints
    [[self backgroundGradientView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    id backgroundGradientXConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:leftBorder/2];
    id backgroundGradientYConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:topBorder/2];
    id backgroundGradientWidthConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-(leftBorder + rightBorder)];
    id backgroundGradientHeightConstraint = [NSLayoutConstraint constraintWithItem:[self backgroundGradientView] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-(topBorder + bottomBorder)];
    [self addConstraints:@[backgroundGradientXConstraint, backgroundGradientYConstraint, backgroundGradientWidthConstraint, backgroundGradientHeightConstraint]];
    [[self layoutConstraints] addObjectsFromArray:@[backgroundGradientXConstraint, backgroundGradientYConstraint, backgroundGradientWidthConstraint, backgroundGradientHeightConstraint]];
    
    [super updateConstraints];
}

- (void)drawRect:(CGRect)rect
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 0);
    gradient.frame = self.backgroundGradientView.frame;
    gradient.colors = [self backgroundColors];
    gradient.locations = [self backgroundColorLocations];
    [[[self backgroundGradientView] layer] setSublayers:@[gradient]];
}

@end
