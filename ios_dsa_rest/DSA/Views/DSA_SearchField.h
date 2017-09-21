//
//  DSA_SearchField.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 9/25/13.
//
//

#import <UIKit/UIKit.h>

@class DSA_SearchField;

@protocol DSA_SearchFieldDelegate <NSObject>
@optional
- (void) searchFieldDidBeginEditing: (DSA_SearchField *) field;
- (void) searchFieldDidFinishEditing: (DSA_SearchField *) field;
- (void) searchBarDidHitSearchWithText: (NSString *) text;
@end

@interface DSA_SearchField : UIView <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet id searchDelegate;
@property (nonatomic, strong) UITextField * searchField;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end
