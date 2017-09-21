//
//  DSA_SettingsMenuDemoCell.h
//  ios_dsa
//
//  Created by Guy Umbright on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSA_SettingsMenuDemoCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UISwitch* demoSwitch;

- (IBAction) demoSwitchChanged: (id) sender;

@end
