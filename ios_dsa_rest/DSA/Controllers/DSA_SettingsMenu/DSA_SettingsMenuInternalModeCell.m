//
//  DSA_SettingsMenuInternalDocsCell.m
//  ios_dsa
//
//  Created by Cory Wiles on 7/30/13.
//
//

#import "DSA_SettingsMenuInternalModeCell.h"
#import "PrefixCommon.h"

@interface DSA_SettingsMenuInternalModeCell()<UIAlertViewDelegate>
{
    UIAlertView *_message;
}
@end

@implementation DSA_SettingsMenuInternalModeCell

- (void)awakeFromNib {

    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey:kDSAInternalModeDefaultsKey];
 
    self.internalModeSwitch.on = b;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (IBAction)toggleInternalMode:(id)sender {
    
    if (self.internalModeSwitch.on) {

        _message = [[UIAlertView alloc] initWithTitle:@"Caution"
                                                          message:@"The information in this area is for internal personnel and authorized agent use only and may not be shown, printed or distributed (including email) outside of the company or used for sales or promotional purposes"
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Enable", nil];
        [_message show];

    } else {

        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kDSAInternalModeDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDSAInternalModeNotificationKey
                                                            object:self];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    /**
     * The `toggleInternalMode` already sets the on/off flag for _internalMode_ 
     * but if the user chooses the cancel (buttonIndex 0) then turn it back off
     * and repost the notification to change the NSUserDefault and the toolbar
     * back to default.
     */

    if (buttonIndex == 1) {

        self.internalModeSwitch.on = YES;
     
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kDSAInternalModeDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDSAInternalModeNotificationKey
                                                            object:self];
    } else {
        
        self.internalModeSwitch.on = NO;
    }
}

- (void)prepareForDismissal {
    if(_message) {
        [_message dismissWithClickedButtonIndex:0 animated:NO];
    }
}

@end
