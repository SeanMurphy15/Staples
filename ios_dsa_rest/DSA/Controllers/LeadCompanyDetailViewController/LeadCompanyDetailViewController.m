//
//  LeadCompanyDetailViewController.m
//  DSA
//
//  Created by Jason Barker on 4/28/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "LeadCompanyDetailViewController.h"
#import "GenericMenuViewController.h"
#import "RequiredInfoCell.h"
#import "LeadController.h"
#import "LeadPersonDetailViewController.h"



const NSInteger      STATUS_ROW_INDEX               = 0;
const NSInteger      PROSPECTING_WEEK_ROW_INDEX     = 1;
const NSInteger      COMPANY_NAME_ROW_INDEX         = 2;
const NSInteger      EMPLOYEE_COUNT_ROW_INDEX       = 3;
const NSInteger      STREET_ADDRESS_ROW_INDEX       = 4;
const NSInteger      CITY_ROW_INDEX                 = 5;
const NSInteger      STATE_ROW_INDEX                = 6;
const NSInteger      ZIP_CODE_ROW_INDEX             = 7;
const NSInteger      OFFICE_SUPPLIER_ROW_INDEX      = 8;
//static NSArray      *NAMES_OF_LABELS;
//static NSDictionary *MENUS;
//static NSDictionary *FIELDS_MAP;



@interface LeadCompanyDetailViewController () <GenericMenuViewControllerDelegate>

@property (nonatomic, strong) NSMutableDictionary   *tableCells;
@property (nonatomic, strong) UITextField           *currentTextField;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSArray *layoutFields;

@end



@implementation LeadCompanyDetailViewController


+ (NSArray *) companyInfoFieldNames {
	return @[@"Status", @"Company", @"Street_1__c", @"City_staples__c", @"State_Province_staples__c", @"Zip_Postal_Code__c", @"CustomerGrading__c"];
}
/**
 *
 
 Field order
 
 Company Name						Company
 Street								Street
 City								City
 State/Province						State_Province_staples__c
 Zip/Postal Code					PostalCode
 Lead Status/Program Phase			Status
 Prospecting Week/Month				Prospecting_Week__c
 Total # of Office Workers			Total_of_WCW__c
 Lead Currency						CurrencyIsoCode
 Lead Source						LeadSource
 Market Segment

 Salutation
 First
 Last
 Email
 Phone
 
 */

+ (NSArray *) fieldOrder {
	return @[@"Company", @"Street_1__c", @"City_staples__c", @"State_Province_staples__c", @"Zip_Postal_Code__c", @"Status", @"Total_of_WCW__c", @"CurrencyIsoCode", @"LeadSource"];
}

+ (NSArray *) sortFields: (NSArray *) fields withOrder: (NSArray *) order {
	NSMutableArray			*sorted = [NSMutableArray array];
	NSMutableArray			*available = [fields mutableCopy];
	
	for (NSString *name in order) {
		NSDictionary	*found = nil;
		
		for (NSDictionary *field in fields) {
			if ([field[@"name"] isEqual: name]) {
				found = field;
				break;
			}
		}
		
		if (found != nil) {
			[available removeObject: found];
			[sorted addObject: found];
		}
	}
	
	[sorted addObjectsFromArray: available];
	
	return sorted;
}

+ (void) initialize {
}


/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if (self) {
		MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
		self.layoutFields = [def requiredFieldsInLayout: nil];

		NSMutableArray					*fields = [NSMutableArray array];
		NSArray							*includeThese = [LeadCompanyDetailViewController companyInfoFieldNames];
		
		for (NSDictionary *field in def.metaDescription_mm[@"fields"]) {
			if ([includeThese containsObject: field[@"name"]]) {
				[fields addObject: field];
			}
		}
		
		self.fields = [LeadCompanyDetailViewController sortFields: fields withOrder: [LeadCompanyDetailViewController fieldOrder]];
		
        [self setTitle: @"Company Information"];
        [self setTableCells: [NSMutableDictionary dictionary]];
        
        UIBarButtonItem *continueButton = [[UIBarButtonItem alloc] initWithTitle: @"Continue" style: UIBarButtonItemStylePlain target: self action: @selector(showPersonDetails:)];
        [self.navigationItem setRightBarButtonItem: continueButton];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.contentSizeForViewInPopover = CGSizeMake(600, 600);
#pragma clang diagnostic pop
    }
    
    return self;
}


#pragma mark - View lifecycle


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
    
    [self.detailsTableView reloadData];
    if (self.detailsTableView.indexPathForSelectedRow)
        [self.detailsTableView selectRowAtIndexPath: self.detailsTableView.indexPathForSelectedRow animated: NO scrollPosition: UITableViewScrollPositionNone];
    
}


/**
 *
 */
- (void) viewDidAppear: (BOOL) animated {
    
    [super viewDidAppear: animated];
    
    if (self.detailsTableView.indexPathForSelectedRow)
        [self.detailsTableView deselectRowAtIndexPath: self.detailsTableView.indexPathForSelectedRow animated: YES];
    
}


#pragma mark - Getters and setters


/**
 *
 */
- (void) setLeadController: (LeadController *) leadController {
    
    _leadController = leadController;
    
    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserProceedToNextStep]];
}


#pragma mark - Actions


/**
 *
 */
- (IBAction) showPersonDetails: (id) sender {
    
    LeadPersonDetailViewController *viewController = [[LeadPersonDetailViewController alloc] init];
    [viewController setLeadController: self.leadController];
    [self.navigationController pushViewController: viewController animated: YES];
}


#pragma mark - GenericMenuViewControllerDelegate messages


/**
 *
 */
- (void) menuViewController: (GenericMenuViewController *) controller didDeselectItem: (NSString *) item atIndex: (NSInteger) index {
	NSDictionary	*field = self.fields[controller.fieldIndex];
	NSString		*name = field[@"name"];
	
	if ([field[@"type"] isEqual: @"multipicklist"]) {
		NSString			*current = self.leadController.fields[name] ?: @"";
		NSMutableArray		*items = [[current componentsSeparatedByString: @"; "] mutableCopy];
		[items removeObject: item];
		[items removeObject: @""];
		
		self.leadController.fields[name] = [items componentsJoinedByString: @"; "];
	}
	
	
	[self.navigationItem.rightBarButtonItem setEnabled: [self canUserProceedToNextStep]];
}

- (void) menuViewController: (GenericMenuViewController *) controller didSelectItem: (NSString *) item atIndex: (NSInteger) index {
	NSDictionary	*field = self.fields[controller.fieldIndex];
	NSString		*name = field[@"name"];
	
	if ([field[@"type"] isEqual: @"multipicklist"]) {
		NSString			*current = self.leadController.fields[name] ?: @"";
		NSMutableArray		*items = [[current componentsSeparatedByString: @"; "] mutableCopy];
		[items addObject: item];
		[items removeObject: @""];
		
		self.leadController.fields[name] = [items componentsJoinedByString: @"; "];
	} else {
		self.leadController.fields[name] = item;
	}
	
	
	[self.navigationItem.rightBarButtonItem setEnabled: [self canUserProceedToNextStep]];
}


#pragma mark - UITableViewDataSource messages


/**
 *
 */
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {
    
    return self.fields.count;
}


/**
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
    
	NSDictionary	*fieldInfo = self.fields[indexPath.row];
	NSString		*fieldName = fieldInfo[@"name"];
	NSString		*displayValue = self.leadController.fields[fieldName] ?: @"";
	
	[cell.nameLabel setText: fieldInfo[@"label"]];
	[cell.valueTextField setText: displayValue];
    [cell.valueTextField setDelegate: self];
    [cell.valueTextField setTag: indexPath.row];
	
	if ([fieldName isEqual: @"Zip_Postal_Code__c"]) {
		cell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
	}
    
	BOOL		isPickList = [fieldInfo[@"type"] hasSuffix: @"picklist"];
	
	if (isPickList) {
		
        [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
        [cell.valueTextField setEnabled: NO];
    }
    else {
        
        [cell setAccessoryType: UITableViewCellAccessoryNone];
        [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
    }
    
	RequiredState    state          = [fieldInfo[@"nillable"] isEqual: @1] ? RequiredStateNotRequired : RequiredStateRequiredAndValidated;
    
    for (NSDictionary *field in self.layoutFields) {
        if ([field[@"name"] isEqual: fieldName] ) {
            state = RequiredStateRequiredAndValidated;
        }
    }
	
	if (state == RequiredStateRequiredAndValidated) {
		
		state = RequiredStateRequiredButNotValidated;
		
		if ([self.leadController validateValue: displayValue forFieldName: fieldInfo[@"name"]])
			state = RequiredStateRequiredAndValidated;
		
	}
	
	[cell setRequiredState: state];
	
    return cell;
}


#pragma mark - UITableViewDelegate messages


/**
 *
 */
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
    
	NSDictionary	*fieldInfo = self.fields[indexPath.row];
	BOOL			isPickList = [fieldInfo[@"type"] hasSuffix: @"picklist"];
	
	if (isPickList) {
		NSMutableArray		*itemStrings = [NSMutableArray array];
		BOOL				isMultiSelect = [fieldInfo[@"type"] isEqual: @"multipicklist"];
		NSMutableArray		*valueStrings = [NSMutableArray array];
		NSString			*fieldName = fieldInfo[@"name"];
		NSString			*current = self.leadController.fields[fieldName];
		NSInteger			selectedIndex = NSNotFound;
		NSArray				*multiValues = [current componentsSeparatedByString: @"; "];
		NSMutableIndexSet	*indices = [NSMutableIndexSet new];
        
        MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
        NSString                        *recordTypeId = [def defaultRecordType];
        
        NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
        NSPredicate* fetchPredicate = [NSPredicate predicateWithFormat: @"Id = %@", recordTypeId];
        MMSF_Object *recordType = [moc firstObjectOfType:@"RecordType" matchingPredicate:fetchPredicate sortedBy:nil];
        

        NSArray *picklistOptions = [def picklistOptionsForField:fieldName basedOffRecordType:recordType];
		
		for (NSDictionary *item in picklistOptions) {
			if (isMultiSelect && [multiValues containsObject: item[@"label"]]) [indices addIndex: itemStrings.count];
			[itemStrings addObject: item[@"label"]];
			[valueStrings addObject: item[@"value"]];
			if ([current isEqual: item[@"label"]]) selectedIndex = itemStrings.count;
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
    
	int				index = textField.tag;
	NSDictionary	*fieldInfo = self.fields[index];
	NSString		*fieldName = fieldInfo[@"name"];
	self.leadController.fields[fieldName] = textField.text;
	
	[self setCurrentTextField: nil];
	
    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserProceedToNextStep]];
}


/**
 *
 */
- (BOOL) textField: (UITextField *) textField shouldChangeCharactersInRange: (NSRange) range replacementString: (NSString *) string {
    
	NSString		*result = [textField.text stringByReplacingCharactersInRange: range withString: string];
	int				index  = textField.tag;
	NSDictionary	*fieldInfo = self.fields[index];
	NSString		*fieldName = fieldInfo[@"name"];
	
	self.leadController.fields[fieldName] = result;
	
	[self.navigationItem.rightBarButtonItem setEnabled: [self canUserProceedToNextStep]];
	
	RequiredInfoCell *cell = (RequiredInfoCell *) [self getTableViewCellForView: textField];
	if (cell) {
		
		RequiredState    state          = [fieldInfo[@"nillable"] isEqual: @1] ? RequiredStateNotRequired : RequiredStateRequiredAndValidated;
		
		if (state == RequiredStateRequiredAndValidated) {
			
			state = RequiredStateRequiredButNotValidated;
			
			if ([self.leadController validateValue: result forFieldName: fieldInfo[@"name"]])
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
    
	NSDictionary	*fieldInfo = self.fields[indexPath.row];
	NSString		*fieldName = fieldInfo[@"name"];
	return self.leadController.fields[fieldName];
}

/**
 *
 */
- (void) setDefaultsForLeadController: (LeadController *) leadController {
    
    [self setLeadController: leadController];
    //self.leadController.fields[@"Status"] = @"Not Yet Contacted";
}


/**
 *
 */
- (BOOL) canUserProceedToNextStep {
    
	for (NSDictionary *field in self.fields) {
		if (![field[@"nillable"] boolValue] && ![self.leadController validateFieldNamed: field[@"name"]]) {
			return false;
		}
        if ([self.layoutFields containsObject: field[@"name"]]) {
            if (![self.leadController validateFieldNamed: field[@"name"]]) {
                return false;
            }
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
