//
//  DSA_SettingsMenuDemoCell.m
//  ios_dsa
//
//  Created by Guy Umbright on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DSA_SettingsMenuDemoCell.h"

@implementation DSA_SettingsMenuDemoCell

@synthesize demoSwitch;

- (void) awakeFromNib
{
    BOOL b = [[NSUserDefaults standardUserDefaults] boolForKey: kDefaultsKey_DemoMode];
    demoSwitch.on = b;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction) demoSwitchChanged: (id) sender
{
    [[NSUserDefaults standardUserDefaults] setBool:demoSwitch.on 
                                            forKey:kDefaultsKey_DemoMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DEMO_MODE_CHANGED_NOTIFICATION object:self];
}

@end
