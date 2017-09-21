//
//  DSA_ContentShelfHeaderView.m
//  DSA
//
//  Created by Mike Close on 7/6/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelfHeaderView.h"
#import "UIResponder+UIResponder_FirstResponderTracking.h"

@interface DSA_ContentShelfHeaderView()
@property (nonatomic, strong) UILabel        *sectionTitleLabel;
@property (nonatomic, strong) UILabel        *sectionTitleSubtextLabel;
@property (nonatomic, strong) UITextField    *sectionTitleField;
@property (nonatomic, strong) UIButton       *deleteButton;
@property (nonatomic, strong) NSString       *state;
@property (nonatomic, strong) UIImageView    *headerIconImageView;
@property (nonatomic)         BOOL            textFieldsWereStyled;
@end

@implementation DSA_ContentShelfHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addShelfNameLabel];
        [self addShelfIcon];
        [self addSubtextLabel];
        [self addShelfNameTextField];
        [self addDeleteShelfButton];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged:) name:kNotification_ContentShelvesStateChanged object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setShelfModel:(DSA_ContentShelfModel *)shelfModel
{
    if ([super shelfModel] == shelfModel) return;
    
    [super setShelfModel:shelfModel];
    [super setShelfConfig:[shelfModel shelfConfig]];
    
    // these methods remove elements if necessary (ex, cell is being reused and new shelf config has different rules)
    [self updateShelfIcon];
    [self updateSubtextLabel];
    [self updateShelfNameLabel];
    [self updateShelfNameTextField];
    
    NSArray *backgroundColors = [[self shelfConfig] headerColors];
    NSArray *backgroundColorLocations = [[self shelfConfig] headerColorLocations];
    [self setBackgroundColors:backgroundColors andLocations:backgroundColorLocations];
    [self setBorderThickness:[[self shelfConfig] headerBorderThickness] color:[[self shelfConfig] headerBorderColor]];
    [[self headerIconImageView] setImage:[[self shelfConfig] headerLabelIconImage]];
    
    [self updateTextFields];
    [self setState:[DSA_ContentShelvesModel state]];
    [self setNeedsDisplay];
}

- (void)addShelfIcon
{
    [self setHeaderIconImageView:[[UIImageView alloc] init]];
    [self addSubview:[self headerIconImageView]];
    [[self headerIconImageView] setHidden:YES];
}

- (void)updateShelfIcon
{
    // add or remove the shelf icon image
    if ([[self shelfConfig] headerLabelIconImage] != nil)
    {
        [[self headerIconImageView] setImage:[[self shelfConfig] headerLabelIconImage]];
        [[self headerIconImageView] setHidden:NO];
    }
    else
    {
        [[self headerIconImageView] setHidden:YES];
    }
}

- (void)addSubtextLabel
{
    [self setSectionTitleSubtextLabel:[[UILabel alloc] init]];
    [self addSubview:[self sectionTitleSubtextLabel]];
    [[self sectionTitleSubtextLabel] setHidden:YES];
}

- (void)updateSubtextLabel
{
    // add or remove the shelf name subtext label
    if ([[self shelfConfig] shelfNameSubtext] != nil)
    {
        [[self sectionTitleSubtextLabel] setText:[[self shelfConfig] shelfNameSubtext]];
        [[self sectionTitleSubtextLabel] setHidden:NO];
    }
    else
    {
        [[self sectionTitleSubtextLabel] setHidden:YES];
    }
}

- (void)addShelfNameTextField
{
    [self setSectionTitleField:[[UITextField alloc] init]];
    [[self sectionTitleField]setDelegate:self];
    [self addSubview:[self sectionTitleField]];
    [[self sectionTitleField] setHidden:YES];
}

- (void)updateShelfNameTextField
{
    [[self sectionTitleField] setText:[[self shelfModel] shelfName]];
}

- (void)addShelfNameLabel
{
    [self setSectionTitleLabel:[[UILabel alloc] init]];
    [self addSubview:[self sectionTitleLabel]];
    [[self sectionTitleLabel] setHidden:YES];
}

- (void)updateShelfNameLabel
{
    [[self sectionTitleLabel] setText:[[self shelfModel] shelfName]];
}

- (void)addDeleteShelfButton
{
    [self setDeleteButton:[UIButton buttonWithImageNamed:@"shelfHeaderDeleteButton"]];
    [self addSubview:[self deleteButton]];
    [[self deleteButton] setHidden:YES];
}

- (void)updateTextFields
{
    if (self.textFieldsWereStyled) return;
    NSDictionary *fontAttributes = @{UIFontDescriptorNameAttribute: [[self shelfConfig] headerLabelFontName]};
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:fontAttributes];
    if ([[[self shelfConfig] headerLabelFontWeight] isEqualToString:@"bold"]) fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *titleLabelFont = [UIFont fontWithDescriptor:fontDescriptor size:[[self shelfConfig] headerLabelFontSize]];
    
    [[self sectionTitleLabel] setFont:titleLabelFont];
    [[self sectionTitleLabel] setTextColor:[[self shelfConfig] headerLabelColor]];
    [[self sectionTitleLabel] setTextAlignment:NSTextAlignmentCenter];
    
    [[self sectionTitleField] setTextAlignment:NSTextAlignmentCenter];
    [[self sectionTitleField] setTextColor:[UIColor grayColor]];
    [[self sectionTitleField] setBackgroundColor:[UIColor whiteColor]];
    [[self sectionTitleField] setFont:titleLabelFont];
    
    NSDictionary *subtextFontAttributes = @{UIFontDescriptorNameAttribute: [[self shelfConfig] headerLabelFontName]};
    UIFontDescriptor *subtextDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:subtextFontAttributes];
    if ([[[self shelfConfig] headerLabelFontWeight] isEqualToString:@"bold"]) subtextDescriptor = [subtextDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFont *subtextLabelFont = [UIFont fontWithDescriptor:subtextDescriptor size:[[self shelfConfig] headerLabelFontSize]];
    [[self sectionTitleSubtextLabel] setFont:subtextLabelFont];
    [[self sectionTitleSubtextLabel] setTextColor:[[self shelfConfig] headerLabelColor]];
    [[self sectionTitleSubtextLabel] setTextAlignment:NSTextAlignmentCenter];
    
    self.textFieldsWereStyled = YES;
}

- (void)updateConstraints
{
    // Delete Button Constraints
    if (![[self deleteButton] isHidden])
    {
        [[self deleteButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSArray *deleteRightConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[delete(15)]-|" options:(NSLayoutFormatAlignmentMask & NSLayoutFormatDirectionMask) metrics:nil views:@{@"delete": [self deleteButton]}];
        [self addConstraints:deleteRightConstraints];
        id deleteCenterY = [NSLayoutConstraint constraintWithItem:[self deleteButton] attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0];
        
        [self addConstraint:deleteCenterY];
        [[self layoutConstraints] addObjectsFromArray:deleteRightConstraints];
        [[self layoutConstraints] addObject:deleteCenterY];
    }
    
    // Header Icon Constraints
    NSInteger headerLabelXPos = 15;
    if (![[self headerIconImageView] isHidden])
    {
        [[self headerIconImageView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        id iconXConstraint = [NSLayoutConstraint constraintWithItem:[self headerIconImageView] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:headerLabelXPos];
        id iconCenterYConstraint = [NSLayoutConstraint constraintWithItem:[self headerIconImageView] attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
        [self addConstraint:iconXConstraint];
        [self addConstraint:iconCenterYConstraint];
        [[self layoutConstraints] addObjectsFromArray:@[iconXConstraint, iconCenterYConstraint]];
        
        headerLabelXPos = 38;
    }
    
    // Header Label Constraints
    [[self sectionTitleLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
    id titleXConstraint = [NSLayoutConstraint constraintWithItem:[self sectionTitleLabel] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:headerLabelXPos];
    id titleCenterYConstraint = [NSLayoutConstraint constraintWithItem:[self sectionTitleLabel] attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [self addConstraint:titleXConstraint];
    [self addConstraint:titleCenterYConstraint];
    [[self layoutConstraints] addObjectsFromArray:@[titleXConstraint, titleCenterYConstraint]];
    
    // Header Labe Subtext Constraints
    if (![[self sectionTitleSubtextLabel] isHidden])
    {
        [[self sectionTitleSubtextLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        id subtextXConstraint = [NSLayoutConstraint constraintWithItem:[self sectionTitleSubtextLabel] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:[self sectionTitleLabel] attribute:NSLayoutAttributeRight multiplier:1.0 constant:5];
        id subtextCenterYConstraint = [NSLayoutConstraint constraintWithItem:[self sectionTitleSubtextLabel] attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:[self sectionTitleLabel] attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
        [self addConstraint:subtextXConstraint];
        [self addConstraint:subtextCenterYConstraint];
        [[self layoutConstraints] addObjectsFromArray:@[subtextXConstraint, subtextCenterYConstraint]];
    }
    
    // Header Text Field Constraints
    if (![[self sectionTitleField] isHidden])
    {
        [[self sectionTitleField] setTranslatesAutoresizingMaskIntoConstraints:NO];
        id textFieldXConstraint = [NSLayoutConstraint constraintWithItem:[self sectionTitleField] attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:headerLabelXPos];
        id textFieldCenterYConstraint = [NSLayoutConstraint constraintWithItem:[self sectionTitleField] attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
        [self addConstraint:textFieldXConstraint];
        [self addConstraint:textFieldCenterYConstraint];
        [[self layoutConstraints] addObjectsFromArray:@[textFieldXConstraint, textFieldCenterYConstraint]];
    }
    
    [super updateConstraints];
}

#pragma mark - States
- (void)stateChanged:(NSNotification *)note
{
    if ([_state isEqualToString:[[note userInfo] objectForKey:@"state"]]) return;
    [self setState:[[note userInfo] objectForKey:@"state"]];
    [self setNeedsUpdateConstraints];
}

- (void)setState:(NSString *)state
{
    _state = state;
    
    if ([state isEqualToString:kContentShelvesStateEdit])
    {
        [self configureForEditState];
    }
    
    if ([state isEqualToString:kContentShelvesStateNormal])
    {
        [self configureForNormalState];
    }
}

- (void)configureForEditState
{
    if ([[self shelfConfig] canRenameShelf] && [[self shelfModel] canModifyShelf])
    {
        [[self sectionTitleField] setText:[[self sectionTitleLabel] text]];
        [[self sectionTitleField] setHidden:NO];
        [[self sectionTitleLabel] setHidden:YES];
    }
    else
    {
        [[self sectionTitleField] setHidden:YES];
        [[self sectionTitleLabel] setHidden:NO];
    }
    
    if ([[self shelfConfig] canDeleteShelf] && [[self shelfModel] canModifyShelf])
    {
        [[self deleteButton] setHidden:NO];
        [[self deleteButton] addTarget:self action:@selector(deleteShelf:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [[self deleteButton] setHidden:YES];
        [[self deleteButton] removeTarget:self action:@selector(deleteShelf:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)configureForNormalState
{
    [self setProperShelfName:self.sectionTitleField];
    [[self sectionTitleField] setHidden:YES];
    [[self sectionTitleLabel] setHidden:NO];
    [[self deleteButton] setHidden:YES];
    if ([[self shelfConfig] canDeleteShelf])
    {
        [[self deleteButton] removeTarget:self action:@selector(deleteShelf:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - UI Event Handlers
- (void)deleteShelf:(id)sender {
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Shelf" otherButtonTitles:nil] autorelease];
    
	[sheet showFromRect: [sender bounds] inView: sender animated: YES];
}

- (void)actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		[[DSA_ContentShelvesModel sharedModel] deleteShelf:[self shelfModel]];
	}
}



#pragma mark - UITextFieldDelegate methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // tell the controller to scroll to this index path.
    [UIResponder setFirstResponder:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self setProperShelfName:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self setProperShelfName:textField];
    return YES;
}

// handle done click with out keyboard being dismissed
- (void)setProperShelfName:(UITextField*)textField
{
    NSString *oldName = self.sectionTitleLabel.text;
    NSString *newName = textField.text;
    
    if (newName && ![oldName isEqualToString:newName]) {
        [[DSA_ContentShelvesModel sharedModel]renameShelf:oldName to:newName];
        self.sectionTitleLabel.text = newName;
        [self shelfModel].shelfName = newName;
        [textField resignFirstResponder];
    }
}

@end
