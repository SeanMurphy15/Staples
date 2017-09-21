//
//  MM_RecordFieldsTable.h
//
//  Created by Ben Gottlieb on 6/1/13.
//
//

#import <UIKit/UIKit.h>

@class MM_RecordFieldsTable, MMSF_Object, MM_SFObjectDefinition;

@protocol MM_RecordFieldsTableHeader <NSObject>
+ (id) headerWithTitle: (NSString *) headerTitle inTable: (MM_RecordFieldsTable *) table;
@end


#define MMFIELDS_TABLE_REQUIRED_FIELD_KEY					@"required"
#define MMFIELDS_TABLE_IS_PHONE_FIELD_KEY					@"isPhone"
#define MMFIELDS_TABLE_IS_US_PHONE_FIELD_KEY				@"isUSPhone"
#define MMFIELDS_TABLE_IS_EMAIL_FIELD_KEY					@"isEmail"
#define MMFIELDS_TABLE_IS_ZIPCODE_FIELD_KEY					@"isZIPCode"
#define MMFIELDS_TABLE_CUSTOM_HEIGHT_FIELD_KEY				@"height"
#define MMFIELDS_TABLE_BUTTON_TITLE_KEY						@"buttonTitle"
#define MMFIELDS_TABLE_KEYPATH_KEY							@"keypath"
#define MMFIELDS_TABLE_EDITABLE_KEY							@"editable"
#define	MMFIELDS_TABLE_LABEL								@"label"
#define MMFIELDS_TABLE_FIELD_ON_RELATIONSHIP_KEY			@"relationShip_field"

#define		kNotification_RecordFieldTableBeganEditing		@"kNotification_RecordFieldTableBeganEditing"
#define		kNotification_RecordFieldTableFinishedEditing		@"kNotification_RecordFieldTableFinishedEditing"

@protocol MM_RecordFieldsTableDelegate <NSObject>
@optional
- (BOOL) recordFieldsTable: (MM_RecordFieldsTable *) table showPicklistFromButton: (UIButton *) button forField: (NSString *) fieldName;
- (BOOL) recordFieldsTable: (MM_RecordFieldsTable *) table showDatePickerFromButton: (UIButton *) button forField: (NSString *) fieldName;
- (BOOL) recordFieldsTable: (MM_RecordFieldsTable *) table showFinishEditingTextField: (UITextField *) field forField: (NSString *) fieldName;
- (BOOL) recordFieldsTable: (MM_RecordFieldsTable *) table shouldAllowText: (NSString *) text forField:(NSString *) fieldName;
- (void) recordFieldsTable: (MM_RecordFieldsTable *) table didChangeValueForField: (NSString *) fieldName;
- (UIButton *) createRecordFieldsTableButton;

@end

typedef NS_ENUM(UInt8, MM_RecordLabelValueAlignment) {
	MM_RecordLabelValueAlignment_centered,					// .....label content.....		calculated for the whole table, or set the labelValueCenterline propery
	MM_RecordLabelValueAlignment_centeredBySection,			// .....label content.....		recalculated for each section
	MM_RecordLabelValueAlignment_justified,					// label...........content
	MM_RecordLabelValueAlignment_left,						// label......content.....
};

@interface MM_RecordFieldsTable : UITableView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MMSF_Object *object;
@property (nonatomic) MM_RecordLabelValueAlignment labelValueAlignment;
@property (nonatomic) UIEdgeInsets edgeInsets;				//only left and right are used
@property (nonatomic) CGFloat labelValueMargin;				//for centered alignment, how much space should be between the label and the value
@property (nonatomic) CGFloat labelValueCenterline;			//fixed centerline
@property (nonatomic, strong) UIFont *labelFont, *valueFont;
@property (nonatomic, weak) id <MM_RecordFieldsTableDelegate> recordFieldsTableDelegate;
@property (nonatomic, strong) Class tableCellClass, headerViewClass;
@property (nonatomic, retain) UITableViewCell *lastEditedCell;
@property (nonatomic) BOOL showRequiredFieldIndicators;
@property (nonatomic, readonly) MM_SFObjectDefinition *objectDefinition;
@property (nonatomic) BOOL inputViewEnabled;								//set to NO to turn off the custom previous/next keyboard accessory
@property (nonatomic) BOOL convertYesNoPicklistsToSwitches;					//set to YES to convert "Yes"/"No" and "On"/"Off" option lists to switches
@property (nonatomic) CGFloat defaultRowButtonWidth;

- (BOOL) validateRequiredFieldsWithIndicators: (BOOL) showRequiredIndicators;

- (void) clearAllSectionsAndRows;
- (NSMutableDictionary *) startNewSectionWithView: (UIView *) headerView;
- (NSMutableDictionary *) startNewSectionWithString: (NSString *) headerTitle;

- (NSMutableDictionary *) addRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editButtonTitle: (NSString *) editButtonTitle;		//edit button title is used if the current value is nil
- (NSMutableDictionary *) addRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable;
- (NSMutableDictionary *) addPhoneRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath USOnly: (BOOL) USOnly editable: (BOOL) editable;
- (NSMutableDictionary *) addZIPCodeRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable;
- (NSMutableDictionary *) addEmailRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable;
- (NSMutableDictionary *) addRowWithLabel: (NSString *) label forKeyPath: (NSString *) keyPath editable: (BOOL) editable textHeight: (CGFloat) height;
- (NSMutableDictionary *) addRelationshipWithLabel: (NSString *) label forField: (NSString *) field onKeyPath: (NSString *) keyPath editButtonTitle: (NSString *) editButtonTitle;

- (void) addTableCell: (UITableViewCell *) cell;

- (BOOL) isFieldValid: (NSDictionary *) fieldInfo;
- (NSIndexPath *) indexPathOfKey: (NSString *) key;
- (void) reloadRowForKey: (NSString *) key;
- (NSArray *) picklistOptionsForField: (NSString *) field;
- (void) clearCachedPicklistOptionsForField: (NSString *) field;
- (void) invalidateCachedPicklistsBasedOnField: (NSString *) field;

- (void) changeValue: (id) value forKeyPath: (NSString *) path onObject: (MMSF_Object *) object;
- (id) valueForKeyPath: (NSString *) path onObject: (MMSF_Object *) object;

- (void) beginEditing;
- (void) endEditingSavingChanged: (BOOL) saving;
@end
