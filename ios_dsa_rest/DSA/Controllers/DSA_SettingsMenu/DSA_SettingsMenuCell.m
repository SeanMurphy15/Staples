//
//  DSA_SettingsMenuCell.m
//  ios_dsa
//
//  Created by Guy Umbright on 11/3/11.
//  Copyright (c) 2011 Kickstand Software. All rights reserved.
//

#import "DSA_SettingsMenuCell.h"

@implementation DSA_SettingsMenuCell

@synthesize button;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
