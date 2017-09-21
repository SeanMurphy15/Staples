//
//  MobileConfigSelectionViewController.m
//  ios_dsa
//
//  Created by Guy Umbright on 10/25/11.
//  Copyright (c) 2011 Kickstand Software. All rights reserved.
//

#import "MobileConfigSelectionViewController.h"
#import "MMSF_MobileAppConfig__c.h"
#import "MM_ContextManager.h"
#import "ContentItemHistory.h"
#import "DSA_AppDelegate.h"
#import "MMSF_User.h"

@implementation MobileConfigSelectionViewController

@synthesize table;
@synthesize navBar;
@synthesize cancelButton;
@synthesize mobileConfigSelectorDelegate;
@synthesize allowCancel;

- (id)init
{
    self = [super initWithNibName:@"MobileConfigSelection" bundle:nil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.allowCancel = YES;
		self.moc = [MM_ContextManager sharedManager].contentContextForWriting;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.table.accessibilityLabel = @"Configurations Table";
	self.table.accessibilityIdentifier = @"Configurations Table";
	if (!self.allowCancel)
	{
		self.navBar.topItem.leftBarButtonItem = nil;
	}
}


/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (void)viewDidUnload
{
    [super viewDidUnload];
	
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (NSArray *) configs {
	if (_configs == nil) {
		_configs = [MMSF_MobileAppConfig__c allActiveMobileConfigurationsInContext: self.moc];
	}
	return _configs;
}

/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (IBAction) cancelPressed:(id) sender
{
    [mobileConfigSelectorDelegate mobileConfigSelectionCanceled:self];
}

#pragma mark - Table view data source

/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.configs.count;
}

/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    MMSF_MobileAppConfig__c* config = [self.configs objectAtIndex:[indexPath row]];
    //    cell.textLabel.text = config.salesforceID;
    cell.textLabel.text = config.TitleText__c;
    cell.detailTextLabel.text = config.IntroText__c;
	
    NSString* savedId = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultKey_selectedMobileAppConfig];
    
	if([[config valueForKey:@"Id"] isEqualToString:savedId])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
	
	cell.accessibilityLabel = $S(@"%@ %@", NSLocalizedString(@"Configuration: ", nil), cell.textLabel.text);
    return cell;
}

#pragma mark - Table view delegate

/////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   MMSF_MobileAppConfig__c* config = [self.configs objectAtIndex:[indexPath row]];
    NSString* objId = [config valueForKey:@"Id"];
	[MMSF_User resetCachedtopLevelCatgories];
    
    [[NSUserDefaults standardUserDefaults] setObject:objId forKey:kUserDefaultKey_selectedMobileAppConfig];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [mobileConfigSelectorDelegate mobileConfigSelected:config 
                                            controller: self];


}

@end
