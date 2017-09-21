// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MM_SFChange.h instead.

#import <CoreData/CoreData.h>


extern const struct MM_SFChangeAttributes {
	__unsafe_unretained NSString *error;
	__unsafe_unretained NSString *inProgress;
	__unsafe_unretained NSString *isNewObject;
	__unsafe_unretained NSString *modifiedAt;
	__unsafe_unretained NSString *queuedAt;
	__unsafe_unretained NSString *modifiedValuesData;
	__unsafe_unretained NSString *originalValuesData;
	__unsafe_unretained NSString *ownerSFID;
	__unsafe_unretained NSString *targetEntity;
	__unsafe_unretained NSString *targetObjectID;
	__unsafe_unretained NSString *targetSalesforceID;
} MM_SFChangeAttributes;

extern const struct MM_SFChangeRelationships {
} MM_SFChangeRelationships;

extern const struct MM_SFChangeFetchedProperties {
} MM_SFChangeFetchedProperties;


@class NSObject;










@interface MM_SFChangeID : NSManagedObjectID {}
@end

@interface _MM_SFChange : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MM_SFChangeID*)objectID;


@property (nonatomic, strong) id error;


//- (BOOL)validateError:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* inProgress;


@property BOOL inProgressValue;
- (BOOL)inProgressValue;
- (void)setInProgressValue:(BOOL)value_;

//- (BOOL)validateInProgress:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* isNewObject;


@property BOOL isNewObjectValue;
- (BOOL)isNewObjectValue;
- (void)setIsNewObjectValue:(BOOL)value_;

//- (BOOL)validateIsNewObject:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* modifiedAt, *queuedAt;


//- (BOOL)validateModifiedAt:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSData* modifiedValuesData;


//- (BOOL)validateModifiedValuesData:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSData* originalValuesData;


//- (BOOL)validateOriginalValuesData:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* ownerSFID;


//- (BOOL)validateOwnerSFID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* targetEntity;


//- (BOOL)validateTargetEntity:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* targetObjectID;


//- (BOOL)validateTargetObjectID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* targetSalesforceID;


//- (BOOL)validateTargetSalesforceID:(id*)value_ error:(NSError**)error_;






@end

@interface _MM_SFChange (CoreDataGeneratedAccessors)

@end

@interface _MM_SFChange (CoreDataGeneratedPrimitiveAccessors)


- (id)primitiveError;
- (void)setPrimitiveError:(id)value;




- (NSNumber*)primitiveInProgress;
- (void)setPrimitiveInProgress:(NSNumber*)value;

- (BOOL)primitiveInProgressValue;
- (void)setPrimitiveInProgressValue:(BOOL)value_;




- (NSNumber*)primitiveIsNewObject;
- (void)setPrimitiveIsNewObject:(NSNumber*)value;

- (BOOL)primitiveIsNewObjectValue;
- (void)setPrimitiveIsNewObjectValue:(BOOL)value_;




- (NSDate*)primitiveModifiedAt;
- (void)setPrimitiveModifiedAt:(NSDate*)value;




- (NSData*)primitiveModifiedValuesData;
- (void)setPrimitiveModifiedValuesData:(NSData*)value;




- (NSData*)primitiveOriginalValuesData;
- (void)setPrimitiveOriginalValuesData:(NSData*)value;




- (NSString*)primitiveOwnerSFID;
- (void)setPrimitiveOwnerSFID:(NSString*)value;




- (NSString*)primitiveTargetEntity;
- (void)setPrimitiveTargetEntity:(NSString*)value;




- (NSString*)primitiveTargetObjectID;
- (void)setPrimitiveTargetObjectID:(NSString*)value;




- (NSString*)primitiveTargetSalesforceID;
- (void)setPrimitiveTargetSalesforceID:(NSString*)value;




@end
