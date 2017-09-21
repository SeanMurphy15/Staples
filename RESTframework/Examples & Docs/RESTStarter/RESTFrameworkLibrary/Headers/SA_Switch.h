//
//  SA_Switch.h
//  SABase
//
//  Created by Ben Gottlieb on 7/28/13.
//
//

#import <UIKit/UIKit.h>

typedef void (^switchedBlock)(BOOL newSwitchValue);

@interface SA_Switch : UISwitch

+ (id) switchWithSwitchedBlock: (switchedBlock) block;

@property (nonatomic, copy) switchedBlock switchedBlock;

- (id) initWithSwitchedBlock: (switchedBlock) block;

@end
