//
//  DSA_SettingsMenuInternalDocsCell.h
//  ios_dsa
//
//  Created by Cory Wiles on 7/30/13.
//
//

#import <UIKit/UIKit.h>

@interface DSA_SettingsMenuInternalModeCell : UITableViewCell

@property (retain, nonatomic) IBOutlet UISwitch *internalModeSwitch;

- (IBAction)toggleInternalMode:(id)sender;
- (void)prepareForDismissal;
@end
