//
//  MM_RecordFieldsTableCell.h
//
//  Created by Ben Gottlieb on 6/1/13.
//

#import <UIKit/UIKit.h>

@class MM_RecordFieldsTable, MMSF_Object;

@interface MM_RecordFieldsTableCell : UITableViewCell <UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, weak) MMSF_Object *object;
@property (nonatomic, strong) NSDictionary *fieldInfo;
@property (nonatomic) CGFloat labelRight;
@property (nonatomic) BOOL displayInvalidFieldIndicator;
@property (nonatomic, readonly) NSString *keyPath, *displayTextValue;

@property (nonatomic, readonly) UILabel *labelLabel, *valueLabel;
@property (nonatomic, readonly) UITextField *valueField;
@property (nonatomic, readonly) UITextView *valueTextView;
@property (nonatomic, readonly) UISwitch *valueSwitch;
@property (nonatomic, readonly) UIButton *valueButton;

@property (nonatomic, readonly) NSUInteger numberOfDecimalPlaces;

@property (nonatomic, weak) MM_RecordFieldsTable *table;

+ (MM_RecordFieldsTableCell *) cellWithObject: (MMSF_Object *) object inFieldsTable: (MM_RecordFieldsTable *) table;
+ (MM_RecordFieldsTableCell *) cell;
+ (NSString *) identifier;
+ (CGFloat) height;

- (void) updateDisplayedContents;
- (void) setupComponentFramesWithValue: (NSString *) value;
@end

@interface MM_RecordFieldsTableCellTextField : UITextField

@end

@interface MM_RecordFieldsTableCellLabel : UILabel

@end


