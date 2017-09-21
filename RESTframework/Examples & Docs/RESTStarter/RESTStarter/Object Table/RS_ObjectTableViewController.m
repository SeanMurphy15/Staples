//
//  RS_ObjectTableViewController.m
//  RESTStarter
//
//  Created by Ben Gottlieb on 5/27/14.
//  Copyright (c) 2014 Model Metrics. All rights reserved.
//

#import "RS_ObjectTableViewController.h"
#import "RS_ObjectDetailsEditorViewController.h"

@interface RS_ObjectTableViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) NSIndexPath *selectedRow;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation RS_ObjectTableViewController

- (void) dealloc {
	[self removeAsObserver];
}

+ (instancetype) controllerWithObject: (NSString *) objectName displayField: (NSString *) field {
	RS_ObjectTableViewController		*controller = [[self alloc] initWithStyle: UITableViewStylePlain];
	
	controller.objectName = objectName;
	controller.displayField = field;
	controller.title = objectName;
	controller.navigationItem.rightBarButtonItem = [UIBarButtonItem SA_itemWithSystemItem: UIBarButtonSystemItemAdd target:controller action: @selector(addObject:)];
	
	[controller addAsObserverForName: kNotification_AccountEdited selector: @selector(reloadData)];
	[controller addAsObserverForName: kNotification_SyncComplete selector: @selector(reloadObjects)];
	return controller;
}

- (void) reloadObjects {
	[self.refreshControl endRefreshing];
	self.moc = [MM_ContextManager sharedManager].threadContentContext;
	[self reloadData];
}

- (void) reloadData {
	self.objects = [self.moc allObjectsOfType: self.objectName matchingPredicate: nil sortedBy: [NSSortDescriptor arrayWithDescriptorWithKey: self.displayField ascending: YES]];
	[self.tableView reloadData];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget: self action: @selector(synchronize:) forControlEvents: UIControlEventValueChanged];
	[self.tableView addSubview: self.refreshControl];
	
	[self.tableView registerClass: [UITableViewCell class] forCellReuseIdentifier: @"cell"];
	[self reloadObjects];
}

- (void) synchronize: (id) sender {
	if (![MM_SyncManager sharedManager].isSyncInProgress) {
		[[MM_SyncManager sharedManager] deltaSyncWithCompletionBlock:^(BOOL value) {
			[self.refreshControl endRefreshing];
		}];
	}
}

- (void) addObject: (id) sender {
	MMSF_Object			*object = [self.moc insertNewEntityWithName: self.objectName];
	
	[self presentViewController: [RS_ObjectDetailsEditorViewController controllerWithObject: object toEditFields: @[ @"Name", @"AccountNumber", @"Phone", @"Type", @"Dependent_List__c" ] ] animated: YES completion: nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.objects.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"cell" forIndexPath:indexPath];
    MMSF_Object		*object = self.objects[indexPath.row];
	
	cell.textLabel.text = [object valueForKey: self.displayField];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MMSF_Object			*object = self.objects[indexPath.row];
	
	[self presentViewController: [RS_ObjectDetailsEditorViewController controllerWithObject: object toEditFields: @[ @"Name", @"AccountNumber", @"Phone", @"Type", @"Dependent_List__c" ] ] animated: YES completion: nil];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
