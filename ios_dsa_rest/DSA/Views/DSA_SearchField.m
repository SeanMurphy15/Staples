//
//  DSA_SearchField.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 9/25/13.
//
//

#import "DSA_SearchField.h"

@implementation DSA_SearchField

- (void) addActivityIndicator {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.frame = CGRectMake(0, 0, 30, 30);
    self.searchField.rightView = self.activityIndicator;
    self.searchField.rightViewMode = UITextFieldViewModeAlways;
}

- (void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    self.searchField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.searchField.borderStyle = UITextBorderStyleRoundedRect;
    self.searchField.background = [UIImage imageNamed: @"fieldBackground"];
    self.searchField.delegate = self;
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.leftView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"search_icon"]];
    self.searchField.leftViewMode = UITextFieldViewModeUnlessEditing;
	self.searchField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self addActivityIndicator];
	self.searchField.accessibilityLabel = @"search DSA";
    self.searchField.enablesReturnKeyAutomatically = NO;
    [self addSubview:self.searchField];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
}

- (void)layoutSubviews {
    self.searchField.frame = CGRectMake(0, 0,
                                        CGRectGetWidth(self.bounds),
                                        CGRectGetHeight(self.bounds));
}

#pragma mark - Text Field Delegate

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    textField.enablesReturnKeyAutomatically = YES;
    return YES;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
	if ([self.searchDelegate respondsToSelector: @selector(searchFieldDidBeginEditing:)]) {
        [self.searchDelegate searchFieldDidBeginEditing: self];
    }
}

- (void) textFieldDidEndEditing: (UITextField *) textField {
    [self.activityIndicator stopAnimating];

	if ([self.searchDelegate respondsToSelector: @selector(searchFieldDidFinishEditing:)]) {
        [self.searchDelegate searchFieldDidFinishEditing: self];
    }
}

- (BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void) search {
    [self.searchDelegate searchBarDidHitSearchWithText: self.searchField.text];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    BOOL shouldReturn = NO;
	if (self.searchField.text.length >= 3) {
        [self.activityIndicator startAnimating];

		if ([self.searchDelegate respondsToSelector: @selector(searchBarDidHitSearchWithText:)]) {
            //[self performSelector:@selector(search) withObject:nil afterDelay:0.1];
            [self.searchDelegate performSelector:@selector(searchBarDidHitSearchWithText:) withObject:self.searchField.text afterDelay:0.1];
            
            //[self.searchDelegate searchBarDidHitSearchWithText: self.searchField.text];
            shouldReturn = YES;
        }
	}
	return shouldReturn;
}

- (void)keyboardHidden:(NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [self.searchField resignFirstResponder];
}

- (void)keyboardShown:(NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHidden:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

@end
