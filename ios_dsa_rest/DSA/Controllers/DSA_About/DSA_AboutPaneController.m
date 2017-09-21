//
//  DSA_AboutPaneController.m
//  Hydra
//
//  Created by Patrick McCarron on 7/19/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import "DSA_AboutPaneController.h"
#import "MMSF_User.h"
#import "DSA_SettingsMenuViewController.h"

@implementation DSA_AboutPaneController

@synthesize popoverContentSize;
@synthesize version;
@synthesize user;

+ (id) controller {
	return [[[self alloc] init] autorelease];
}

- (id)init
{
    self = [super initWithNibName:@"DSA_AboutPaneController" bundle:nil];
    if (self) {
        // Custom initialization
        self.title = @"About This App";
    }
    return self;
}


- (void) viewDidLoad 
{
	[super viewDidLoad];
    // accessibility labels for testing
    [self.version setAccessibilityLabel:@"Version"];
    [self.version setIsAccessibilityElement:YES];
    
	self.popoverContentSize = self.view.bounds.size;
    self.version.text = [NSString stringWithFormat:@"Version %@ (%s %s)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], __DATE__, __TIME__];
    
	#if APPSTORE
		self.version.text = $S(@"%@ s", self.version.text);
	#endif
	
    if ([MMSF_User currentUser].isLoggedIn)
    {
        self.user.hidden = NO;
        self.user.text = [NSString stringWithFormat:@"User: %@",[MMSF_User currentUser].name];
    }
    else
    {
        self.user.hidden = YES;
    }
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear: animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SETTINGS_POPOVER_DISMISSED
                                                        object:self];
}

- (CGSize)contentSizeForViewInPopover {
	return self.popoverContentSize;
}

- (CGSize)preferredContentSize {
    return self.popoverContentSize;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (YES);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
