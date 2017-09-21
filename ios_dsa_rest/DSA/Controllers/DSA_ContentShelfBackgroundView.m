//
//  DSA_ContentShelfBackgroundView.m
//  DSA
//
//  Created by Mike Close on 7/31/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelfBackgroundView.h"
#import "DSA_CollectionViewSectionBackgroundLayoutAttributes.h"

@interface DSA_ContentShelfBackgroundView ()

@property (nonatomic, strong) UILabel *shelfBackgroundMessageHeaderLabel;
@property (nonatomic, strong) UILabel *shelfBackgroundMessageLabel;

@end

@implementation DSA_ContentShelfBackgroundView

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    DSA_CollectionViewSectionBackgroundLayoutAttributes *attrs = (DSA_CollectionViewSectionBackgroundLayoutAttributes*)layoutAttributes;
    self.shelfModel = attrs.model;
}


- (void)setShelfModel:(DSA_ContentShelfModel *)shelfModel
{
    [super setShelfModel:shelfModel];
    
    if ((shelfModel.itemCount < 1) && [shelfModel.shelfConfig.configurationId isEqualToString:kContentShelfConfiguration_PersonalLibrary])
    {
        NSDictionary *fontAttributes = @{UIFontDescriptorNameAttribute: [[self shelfConfig] headerLabelFontName]};
        UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:fontAttributes];
        if ([[[self shelfConfig] headerLabelFontWeight] isEqualToString:@"bold"]) fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        
        UIFont *headerLabelFont = [UIFont fontWithDescriptor:fontDescriptor size:([[self shelfConfig] headerLabelFontSize] + 4)];
        [self setShelfBackgroundMessageHeaderLabel:[[UILabel alloc] init]];
        [[self shelfBackgroundMessageHeaderLabel] setFont:headerLabelFont];
        [[self shelfBackgroundMessageHeaderLabel] setTextColor:[[self shelfConfig] headerLabelColor]];
        [[self shelfBackgroundMessageHeaderLabel] setTextAlignment:NSTextAlignmentCenter];
        
        UIFont *messageLabelFont = [UIFont fontWithDescriptor:fontDescriptor size:[[self shelfConfig] thumbnailLabelFontSize]];
        [self setShelfBackgroundMessageLabel:[[UILabel alloc] init]];
        [[self shelfBackgroundMessageLabel] sizeToFit];
        [[self shelfBackgroundMessageLabel] setNumberOfLines:4];
        [[self shelfBackgroundMessageLabel] setFont:messageLabelFont];
        [[self shelfBackgroundMessageLabel] setTextColor:[[self shelfConfig] headerLabelColor]];
        [[self shelfBackgroundMessageLabel] setTextAlignment:NSTextAlignmentCenter];
        
        [self addSubview:[self shelfBackgroundMessageHeaderLabel]];
        [self addSubview:[self shelfBackgroundMessageLabel]];
        
        [[self shelfBackgroundMessageHeaderLabel] setText:[[self shelfConfig] emptyShelfBackgroundHeader]];
        [[self shelfBackgroundMessageLabel] setText:[[self shelfConfig] emptyShelfBackgroundMessage]];
        CGFloat colorVal = 179.0/255.0;
        self.shelfBackgroundMessageHeaderLabel.textColor = [UIColor colorWithRed:colorVal green:colorVal blue:colorVal alpha:1.0];
        self.shelfBackgroundMessageLabel.textColor = [UIColor colorWithRed:colorVal green:colorVal blue:colorVal alpha:1.0];
    }
    else
    {
        [[self shelfBackgroundMessageHeaderLabel] removeFromSuperview];
        [[self shelfBackgroundMessageLabel] removeFromSuperview];
        [self setShelfBackgroundMessageHeaderLabel:nil];
        [self setShelfBackgroundMessageLabel:nil];
    }
}

- (void)updateConstraints
{
    if ([self shelfBackgroundMessageHeaderLabel] != nil)
    {
        // Background Message Header Constraints
        [[self shelfBackgroundMessageHeaderLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        id headerXConstraint = [NSLayoutConstraint constraintWithItem:[self shelfBackgroundMessageHeaderLabel] attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
        id headerYConstraint = [NSLayoutConstraint constraintWithItem:[self shelfBackgroundMessageHeaderLabel] attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:90.0];
        id headerWidthConstraint = [NSLayoutConstraint constraintWithItem:[self shelfBackgroundMessageHeaderLabel] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
        [self addConstraints:@[headerYConstraint,headerXConstraint,headerWidthConstraint]];
        [[self layoutConstraints] addObjectsFromArray:@[headerYConstraint,headerXConstraint,headerWidthConstraint]];
    }
    
    if ([self shelfBackgroundMessageLabel] != nil)
    {
        // Background Message Constraints
        [[self shelfBackgroundMessageLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        id messageXConstraint = [NSLayoutConstraint constraintWithItem:[self shelfBackgroundMessageLabel] attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:[self shelfBackgroundMessageHeaderLabel] attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
        id messageYConstraint = [NSLayoutConstraint constraintWithItem:[self shelfBackgroundMessageLabel] attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self shelfBackgroundMessageHeaderLabel] attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        id messageWidthConstraint = [NSLayoutConstraint constraintWithItem:[self shelfBackgroundMessageLabel] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[self shelfBackgroundMessageHeaderLabel] attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
        [self addConstraints:@[messageYConstraint,messageXConstraint,messageWidthConstraint]];
        [[self layoutConstraints] addObjectsFromArray:@[messageYConstraint,messageXConstraint,messageWidthConstraint]];
    }
    
    [super updateConstraints];
}

@end
