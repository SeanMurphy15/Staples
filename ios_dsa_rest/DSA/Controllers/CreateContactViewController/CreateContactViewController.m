//
//  CreateContactViewController.m
//  DSA
//
//  Created by Jason Barker on 4/24/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "CreateContactViewController.h"
#import "ContactController.h"
#import "MMSF_Account.h"
#import "MMSF_Contact.h"
#import "RequiredInfoCell.h"
#import "GenericMenuViewController.h"
#import "LeadCompanyDetailViewController.h"
#import "DSA_PicklistUtility.h"

const NSInteger      CONTACT_FIRST_NAME_ROW_INDEX       = 0;
const NSInteger      CONTACT_LAST_NAME_ROW_INDEX        = 1;
const NSInteger      CONTACT_EMAIL_ADDRESS_ROW_INDEX    = 2;
const NSInteger      CONTACT_PHONE_NUMBER_ROW_INDEX     = 3;



@interface CreateContactViewController () <GenericMenuViewControllerDelegate>

@property (nonatomic, strong) NSMutableDictionary   *tableCells;
@property (nonatomic, strong) UITextField           *currentTextField;

@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSArray *layoutFields;

@end



@implementation CreateContactViewController

+ (NSArray *) fieldOrder {
    return @[@"Salutation", @"FirstName", @"LastName", @"Email", @"Phone"];
}


/**
 *
 */

/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {

    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];

    if (self) {
		MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Contact" inContext: nil];
		NSArray							*required = [def requiredFieldsInLayout: nil];
		NSMutableArray					*shown = [NSMutableArray array];
		NSArray							*suppressedFields = @[@"AccountId"];
        NSArray							*includeThese = @[@"Phone", @"Email"];

		for (NSDictionary *dict in required) {
            NSString		*fieldName = dict[@"name"];

			if ([suppressedFields containsObject: fieldName]) continue;
			[shown addObject: dict];
		}

        for (NSDictionary *field in def.metaDescription_mm[@"fields"]) {
            if ([includeThese containsObject: field[@"name"]]) {
                if([shown containsObject: field[@"name"]]) {
                    continue;
                } else {
                    [shown addObject: field];
                }
            }
        }

		self.layoutFields = required;
		self.fields = [LeadCompanyDetailViewController sortFields: shown withOrder: [CreateContactViewController fieldOrder]];

        [self setTitle: @"Create Contact"];

        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave target: self action: @selector(saveContact:)];
        [self.navigationItem setRightBarButtonItem: saveButton];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.contentSizeForViewInPopover = CGSizeMake(600, 600);
#pragma clang diagnostic pop
    }

    return self;
}


/**
 *
 */
- (void) viewDidLoad {

    [super viewDidLoad];

    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.detailsTableView.frame), 0);
    UIView *footerView = [[UIView alloc] initWithFrame: frame];
    [self.detailsTableView setTableFooterView: footerView];
}


/**
 *
 */
- (void) viewWillAppear: (BOOL) animated {

    [super viewWillAppear: animated];

    //  Populate labels and text fields
    MMSF_Account    *account        = self.contactController.account;
    NSString        *accountName    = account.Name;
    NSString        *accountNumber  = nil;

    if ([account respondsToSelector: @selector(AccountNumber)])
        accountNumber = account.AccountNumber;

    [self.accountNameLabel setText: (accountName ? accountName : @"")];
    [self.accountNumberLabel setText: (accountNumber ? accountNumber : @"")];

    [self.detailsTableView reloadData];
}


#pragma mark - Getters and setters


/**
 *
 */
- (void) setContactController: (ContactController *) contactController {

    _contactController = contactController;

    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveContact]];
}


#pragma mark - Actions


/**
 *
 */
- (IBAction) saveContact: (id) sender {

    [self.contactController saveContact];
}


#pragma mark - UITableViewDataSource messages


/**
 *
 */
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {

    return self.fields.count;
}


/**
 Salutation,
 FirstName,
 LastName,
 Email,
 Phone,
 Lead_Contact_Title_Grouping__c,
 Department_Standardized__c,
 Areas_of_Influence__c


 *
 */
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {

    NSNumber *index = @(indexPath.row);
    RequiredInfoCell *cell  = [self.tableCells objectForKey: index];

    if (!cell) {

        NSArray *views = [[NSBundle mainBundle] loadNibNamed: @"RequiredInfoCell" owner: self options: nil];
        cell = views[0];
        [self.tableCells setObject: cell forKey: index];
    }

    NSString *displayValue = [self displayValueForRowAtIndexPath: indexPath];
	NSDictionary	*fieldInfo = self.fields[indexPath.row];
	NSDictionary	*fieldName = fieldInfo[@"name"];

    [cell.nameLabel setText: fieldInfo[@"label"]];
    [cell.valueTextField setText: displayValue];
    [cell.valueTextField setDelegate: self];
    [cell.valueTextField setTag: indexPath.row];

	if ([fieldName isEqual: @"Phone"]) {
		cell.valueTextField.keyboardType = UIKeyboardTypePhonePad;
	}

    [cell setAccessoryType: UITableViewCellAccessoryNone];
    [cell setSelectionStyle: UITableViewCellSelectionStyleNone];

//    NSNumber        *fieldNumber    = CONTACT_FIELDS_MAP[index];
//    int              field          = fieldNumber.intValue;

	RequiredState    state          = [fieldInfo[@"nillable"] isEqual: @1] ? RequiredStateNotRequired : RequiredStateRequiredAndValidated;

    for (NSDictionary *field in self.layoutFields) {
        // Special handling for Salutation and FirstName.  They appear required in the page
        // layout because they are part of the Name field.  Mark not required to match browser.
        if ([field[@"name"] isEqual: @"Salutation"] )
            continue;
        if ([field[@"name"] isEqual: @"FirstName"] )
            continue;

        if ([field[@"name"] isEqual: fieldName] ) {
            state = RequiredStateRequiredAndValidated;
        }
    }


    if (state == RequiredStateRequiredAndValidated) {

        state = RequiredStateRequiredButNotValidated;

        if ([self.contactController validateValue: displayValue forFieldName: fieldInfo[@"name"]])
            state = RequiredStateRequiredAndValidated;

    }

	BOOL		isPickList = [fieldInfo[@"type"] hasSuffix: @"picklist"];

	if (isPickList) {

		[cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
		[cell.valueTextField setEnabled: NO];
	} else {
		[cell setAccessoryType: UITableViewCellAccessoryNone];
		[cell setSelectionStyle: UITableViewCellSelectionStyleNone];
	}

	[cell setRequiredState: state];

    return cell;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {

	NSDictionary	*fieldInfo = self.fields[indexPath.row];
	BOOL			isPickList = [fieldInfo[@"type"] hasSuffix: @"picklist"];

	if (isPickList) {
		NSMutableArray		*itemStrings = [NSMutableArray array];
		NSMutableArray		*valueStrings = [NSMutableArray array];
		BOOL				isMultiSelect = [fieldInfo[@"type"] isEqual: @"multipicklist"];
		NSString			*fieldName = fieldInfo[@"name"];
		NSString			*current = self.contactController.fields[fieldName];
		NSInteger			selectedIndex = NSNotFound;
		NSArray				*multiValues = [current componentsSeparatedByString: @"; "];
		NSMutableIndexSet	*indices = [NSMutableIndexSet new];


        NSArray *picklistOptions = [DSA_PicklistUtility activePicklistOptionsForField:fieldName onObjectNamed:@"Contact"];

		for (NSDictionary *item in picklistOptions) {
			if (isMultiSelect && [multiValues containsObject: item[@"label"]]) [indices addIndex: itemStrings.count];
            if ([current isEqual: item[@"label"]]) {
                selectedIndex = itemStrings.count;
            }
			[itemStrings addObject: item[@"label"]];
			[valueStrings addObject: item[@"value"]];
		}

		GenericMenuViewController *viewController = [[GenericMenuViewController alloc] init];
		[viewController setDelegate: self];
		[viewController setTitle: fieldInfo[@"label"]];
		[viewController setMenuItems: itemStrings];
		[viewController setMenuValues: valueStrings];
		[viewController setAllowsMultipleSelection: isMultiSelect];
		[viewController setSelectedIndices: indices];
		[viewController setSelectedIndex: selectedIndex];
		viewController.field = fieldName;
        viewController.fieldIndex = indexPath.row;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		[viewController setContentSizeForViewInPopover: CGSizeMake(600, 600)];
#pragma clang diagnostic pop

		[self.navigationController pushViewController: viewController animated: YES];
	}
}

- (void) menuViewController: (GenericMenuViewController *) controller didDeselectItem: (NSString *) item atIndex: (NSInteger) index {
	NSDictionary	*field = self.fields[controller.fieldIndex];
	NSString		*name = field[@"name"];

	if ([field[@"type"] isEqual: @"multipicklist"]) {
		NSString			*current = self.contactController.fields[name] ?: @"";
		NSMutableArray		*items = [[current componentsSeparatedByString: @"; "] mutableCopy];
		[items removeObject: item];
		[items removeObject: @""];

		self.contactController.fields[name] = [items componentsJoinedByString: @"; "];
	}


	[self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveContact]];
}

- (void) menuViewController: (GenericMenuViewController *) controller didSelectItem: (NSString *) item atIndex: (NSInteger) index {
	NSDictionary	*field = self.fields[controller.fieldIndex];
	NSString		*name = field[@"name"];

	if ([field[@"type"] isEqual: @"multipicklist"]) {
		NSString			*current = self.contactController.fields[name] ?: @"";
		NSMutableArray		*items = [[current componentsSeparatedByString: @"; "] mutableCopy];
		[items addObject: item];
		[items removeObject: @""];

		self.contactController.fields[name] = [items componentsJoinedByString: @"; "];
	} else {
		self.contactController.fields[name] = item;
	}


	[self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveContact]];
}

#pragma mark - UITextFieldDelegate messages


/**
 *
 */
- (void) textFieldDidBeginEditing: (UITextField *) textField {

    [self setCurrentTextField: textField];
}


/**
 *
 */
- (void) textFieldDidEndEditing: (UITextField *) textField {

    int					index = textField.tag;
	NSDictionary		*info = self.fields[index];
	NSString			*fieldName = info[@"name"];

	self.contactController.fields[fieldName] = textField.text;
    [self setCurrentTextField: nil];

    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveContact]];
}


/**
 *
 */
- (BOOL) textField: (UITextField *) textField shouldChangeCharactersInRange: (NSRange) range replacementString: (NSString *) string {

    NSString			*result = [textField.text stringByReplacingCharactersInRange: range withString: string];
    int					index  = textField.tag;
	NSDictionary		*info = self.fields[index];
	NSString			*fieldName = info[@"name"];

	self.contactController.fields[fieldName] = result;

    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveContact]];

    RequiredInfoCell *cell = (RequiredInfoCell *) [self getTableViewCellForView: textField];
    if (cell) {

        NSIndexPath     *indexPath      = [self.detailsTableView indexPathForCell: cell];
		NSDictionary	*fieldInfo = self.fields[indexPath.row];
		RequiredState    state          = [fieldInfo[@"nillable"] isEqual: @1] ? RequiredStateNotRequired : RequiredStateRequiredAndValidated;

		if (state == RequiredStateRequiredAndValidated) {

			state = RequiredStateRequiredButNotValidated;

			if ([self.contactController validateValue: result forFieldName: fieldInfo[@"name"]])
				state = RequiredStateRequiredAndValidated;
		}

        [cell setRequiredState: state];
    }

    return YES;
}


/**
 *
 */
- (BOOL) textFieldShouldReturn: (UITextField *) textField {

    [textField resignFirstResponder];
    return NO;
}


#pragma mark -


/**
 *
 */
- (NSString *) displayValueForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSDictionary		*info = self.fields[indexPath.row];
	NSString			*fieldName = info[@"name"];

	return self.contactController.fields[fieldName];
}


/**
 *
 */
- (BOOL) canUserSaveContact {
	for (NSDictionary *field in self.layoutFields) {
        // Special handling for Salutation and FirstName.  They appear required in the page
        // layout because they are part of the Name field.  Mark not required to match browser.
        if ([field[@"name"] isEqual: @"Salutation"] )
            continue;
        if ([field[@"name"] isEqual: @"FirstName"] )
            continue;
        if ([field[@"name"] isEqual: @"AccountId"] )
            continue;

        if (![field[@"nillable"] isEqual: @1] && ![self.contactController validateFieldNamed: field[@"name"]]) {
            return false;
        }
        if (![self.contactController validateFieldNamed: field[@"name"]]) {
            return false;
        }

	}

    return true;
}


/**
 *
 */
- (UITableViewCell *) getTableViewCellForView: (UIView *) view {

    UIView *parentView = view;

    while (parentView) {

        if ([parentView isKindOfClass: [UITableViewCell class]])
            return (UITableViewCell *) parentView;

        parentView = parentView.superview;
    }

    return nil;
}


@end
