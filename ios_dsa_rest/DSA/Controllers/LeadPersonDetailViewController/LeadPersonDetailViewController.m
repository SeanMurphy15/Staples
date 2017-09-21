//
//  LeadPersonDetailViewController.m
//  DSA
//
//  Created by Jason Barker on 4/29/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "LeadPersonDetailViewController.h"
#import "GenericMenuViewController.h"
#import "RequiredInfoCell.h"
#import "LeadController.h"
#import "LeadCompanyDetailViewController.h"



const NSInteger      LEAD_SALUTATION_ROW_INDEX      = 0;
const NSInteger      LEAD_FIRST_NAME_ROW_INDEX      = 1;
const NSInteger      LEAD_LAST_NAME_ROW_INDEX       = 2;
const NSInteger      LEAD_EMAIL_ADDRESS_ROW_INDEX   = 3;
const NSInteger      LEAD_PHONE_NUMBER_ROW_INDEX    = 4;
const NSInteger      LEAD_TITLE_GROUPING_ROW_INDEX  = 5;
//static NSArray      *LEAD_NAMES_OF_LABELS;
//static NSDictionary *LEAD_MENUS;
//static NSDictionary *LEAD_FIELDS_MAP;



@interface LeadPersonDetailViewController () <GenericMenuViewControllerDelegate>

@property (nonatomic, strong) NSMutableDictionary   *tableCells;
@property (nonatomic, strong) UITextField           *currentTextField;
@property (nonatomic, strong) NSArray *fields;
@property (nonatomic, strong) NSArray *layoutFields;

@end



@implementation LeadPersonDetailViewController


/**
 *
 */
+ (void) initialize {
    
//    LEAD_NAMES_OF_LABELS    = @[@"Salutation",
//                                @"First Name",
//                                @"Last Name",
//                                @"Email Address",
//                                @"Phone",
//                                @"Title Grouping"];
//    
//    LEAD_MENUS               = @{@(LEAD_SALUTATION_ROW_INDEX):      @"SalutationMenu",
//                                 @(LEAD_TITLE_GROUPING_ROW_INDEX):  @"TitleGroupingMenu"};
//    
//    LEAD_FIELDS_MAP          = @{@(LEAD_SALUTATION_ROW_INDEX):      @(LeadFieldSalutation),
//                                 @(LEAD_FIRST_NAME_ROW_INDEX):      @(LeadFieldFirstName),
//                                 @(LEAD_LAST_NAME_ROW_INDEX):       @(LeadFieldLastName),
//                                 @(LEAD_EMAIL_ADDRESS_ROW_INDEX):   @(LeadFieldEmailAddress),
//                                 @(LEAD_PHONE_NUMBER_ROW_INDEX):    @(LeadFieldPhoneNumber),
//                                 @(LEAD_TITLE_GROUPING_ROW_INDEX):  @(LeadFieldTitleGrouping)};
}


+ (NSArray *) fieldOrder {
	return @[@"Salutation", @"FirstName", @"LastName", @"Email", @"Phone"];
}


/**
 *
 */
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    
    if (self) {
		MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
		NSArray							*required = [def requiredFieldsInLayout: nil];
		NSMutableArray					*shown = [NSMutableArray array];
		NSArray							*suppressedFields = @[@"Company", @"Status", @"LeadSource", @"Why_Dead__c", @"CustomerGrading__c"];
        NSArray							*includeThese = @[@"Phone", @"Email"];
		NSMutableArray					*addedFieldNames = [NSMutableArray new];
		
		for (NSDictionary *dict in required) {
			NSString		*fieldName = dict[@"name"];

			if ([suppressedFields containsObject: fieldName]) continue;
			[addedFieldNames addObject: dict[@"name"]];
			[shown addObject: dict];
		}
        
        for (NSDictionary *field in def.metaDescription_mm[@"fields"]) {
            if ([includeThese containsObject: field[@"name"]]) {
                if([addedFieldNames containsObject: field[@"name"]]) {
                    continue;
                } else {
					[addedFieldNames addObject: field[@"name"]];
                    [shown addObject: field];
                }
            }
        }
		
		self.layoutFields = required;
		self.fields = [LeadCompanyDetailViewController sortFields: shown withOrder: [LeadPersonDetailViewController fieldOrder]];

		
        [self setTitle: @"Person Information"];
        [self setTableCells: [NSMutableDictionary dictionary]];
        
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave target: self action: @selector(saveLeadInfo:)];
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
    
    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveLead]];
}


#pragma mark - Actions


/**
 *
 */
- (IBAction) saveLeadInfo: (id) sender {
    
    [self.leadController saveLead];
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
		
		self.leadController.fields[name] = [items componentsJoinedByString: @"; "];
	}
	
	
	[self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveLead]];
}

- (void) menuViewController: (GenericMenuViewController *) controller didSelectItem: (NSString *) item atIndex: (NSInteger) index {
	NSDictionary	*field = self.fields[controller.fieldIndex];
	NSString		*name = field[@"name"];
	
	if ([field[@"type"] isEqual: @"multipicklist"]) {
		NSString			*current = self.leadController.fields[name] ?: @"";
		NSMutableArray		*items = [[current componentsSeparatedByString: @"; "] mutableCopy];
		[items addObject: item];
		
		self.leadController.fields[name] = [items componentsJoinedByString: @"; "];
	} else {
		self.leadController.fields[name] = item;
	}
	
	
    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveLead]];
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
	
	if ([fieldName isEqual: @"Total_of_WCW__c"]) {
		cell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
	} else if ([fieldName isEqual: @"Phone"]) {
		cell.valueTextField.keyboardType = UIKeyboardTypePhonePad;
	}

	
	BOOL		isPickList = [fieldInfo[@"type"] isEqual: @"picklist"];
	
    if (isPickList) {
        
        [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
        [cell.valueTextField setEnabled: NO];
    }
    else {
        
        [cell setAccessoryType: UITableViewCellAccessoryNone];
        [cell setSelectionStyle: UITableViewCellSelectionStyleNone];
    }
    
	RequiredState    state          = [fieldInfo[@"nillable"] isEqual: @1] ? RequiredStateNotRequired : RequiredStateRequiredAndValidated;
    
//    for (NSDictionary *field in self.layoutFields) {
//        // Special handling for Salutation and FirstName.  They appear required in the page
//        // layout because they are part of the Name field.  Mark not required to match browser.
//        if ([field[@"name"] isEqual: @"Salutation"] )
//            continue;
//        if ([field[@"name"] isEqual: @"FirstName"] )
//            continue;
//
//        if ([field[@"name"] isEqual: fieldName] ) {
//            state = RequiredStateRequiredAndValidated;
//        }
//    }
//	
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
	BOOL			isPickList = [fieldInfo[@"type"] isEqual: @"picklist"];
	
	if (isPickList) {
		NSMutableArray		*itemStrings = [NSMutableArray array];
		NSMutableArray		*valueStrings = [NSMutableArray array];
		NSString			*fieldName = fieldInfo[@"name"];
		NSString			*current = self.leadController.fields[fieldName];
		NSInteger			selectedIndex = NSNotFound;
        
        MM_SFObjectDefinition			*def = [MM_SFObjectDefinition objectNamed: @"Lead" inContext: nil];
        NSString                        *recordTypeId = [def defaultRecordType];
        
        NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
        NSPredicate* fetchPredicate = [NSPredicate predicateWithFormat: @"Id = %@", recordTypeId];
        MMSF_Object *recordType = [moc firstObjectOfType:@"RecordType" matchingPredicate:fetchPredicate sortedBy:nil];
        
        NSArray *picklistOptions = [def picklistOptionsForField:fieldName basedOffRecordType:recordType];
		
		for (NSDictionary *item in picklistOptions) {
			[itemStrings addObject: item[@"label"]];
			[valueStrings addObject: item[@"value"]];
			if ([current isEqual: item[@"label"]]) selectedIndex = itemStrings.count;
		}
		
		GenericMenuViewController *viewController = [[GenericMenuViewController alloc] init];
		[viewController setDelegate: self];
		[viewController setTitle: fieldInfo[@"label"]];
		[viewController setMenuItems: itemStrings];
		[viewController setMenuValues: valueStrings];
		[viewController setSelectedIndex: selectedIndex];
		viewController.fieldIndex = indexPath.row;
		viewController.field = fieldName;
		
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
    
    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveLead]];
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
    
    [self.navigationItem.rightBarButtonItem setEnabled: [self canUserSaveLead]];
    
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
 *
 */
- (BOOL) canUserSaveLead {
	for (NSDictionary *field in self.fields) {
		if (![field[@"nillable"] isEqual: @1] && ![self.leadController validateFieldNamed: field[@"name"]]) {
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
