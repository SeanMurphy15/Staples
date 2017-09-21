// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MM_SFObjectDefinition.h instead.

#import <CoreData/CoreData.h>


extern const struct MM_SFObjectDefinitionAttributes {
	__unsafe_unretained NSString *activateable;
	__unsafe_unretained NSString *canFilterOnLastModified;
	__unsafe_unretained NSString *checkingForDeletedObjects_mm;
	__unsafe_unretained NSString *createable;
	__unsafe_unretained NSString *custom;
	__unsafe_unretained NSString *customSetting;
	__unsafe_unretained NSString *deletable;
	__unsafe_unretained NSString *deprecatedAndHidden;
	__unsafe_unretained NSString *feedEnabled;
	__unsafe_unretained NSString *fullSyncCompleted_mm;
	__unsafe_unretained NSString *fullSyncInProgress_mm;
	__unsafe_unretained NSString *keyPrefix;
	__unsafe_unretained NSString *label;
	__unsafe_unretained NSString *labelPlural;
	__unsafe_unretained NSString *lastSyncError_mm;
	__unsafe_unretained NSString *lastSyncedAt_mm;
	__unsafe_unretained NSString *layout_mm;
	__unsafe_unretained NSString *layoutable;
	__unsafe_unretained NSString *mergeable;
	__unsafe_unretained NSString *metaDescription_mm;
	__unsafe_unretained NSString *metaLayout_mm;
	__unsafe_unretained NSString *moreResultsURL_mm;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *objectName_mm;
	__unsafe_unretained NSString *queryable;
	__unsafe_unretained NSString *replicateable;
	__unsafe_unretained NSString *retrieveable;
	__unsafe_unretained NSString *searchable;
	__unsafe_unretained NSString *serverObjectCount;
	__unsafe_unretained NSString *serverObjectName_mm;
	__unsafe_unretained NSString *syncInfo_mm;
	__unsafe_unretained NSString *triggerable;
	__unsafe_unretained NSString *undeletable;
	__unsafe_unretained NSString *updateable;
	__unsafe_unretained NSString *urls;
} MM_SFObjectDefinitionAttributes;

extern const struct MM_SFObjectDefinitionRelationships {
} MM_SFObjectDefinitionRelationships;

extern const struct MM_SFObjectDefinitionFetchedProperties {
} MM_SFObjectDefinitionFetchedProperties;
















@class NSObject;

@class NSObject;


@class NSObject;
@class NSObject;









@class NSObject;



@class NSObject;

@interface MM_SFObjectDefinitionID : NSManagedObjectID {}
@end

@interface _MM_SFObjectDefinition : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MM_SFObjectDefinitionID*)objectID;




@property (nonatomic, strong) NSNumber* activateable;


@property BOOL activateableValue;
- (BOOL)activateableValue;
- (void)setActivateableValue:(BOOL)value_;

//- (BOOL)validateActivateable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* canFilterOnLastModified;


@property BOOL canFilterOnLastModifiedValue;
- (BOOL)canFilterOnLastModifiedValue;
- (void)setCanFilterOnLastModifiedValue:(BOOL)value_;

//- (BOOL)validateCanFilterOnLastModified:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* checkingForDeletedObjects_mm;


@property BOOL checkingForDeletedObjects_mmValue;
- (BOOL)checkingForDeletedObjects_mmValue;
- (void)setCheckingForDeletedObjects_mmValue:(BOOL)value_;

//- (BOOL)validateCheckingForDeletedObjects_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* createable;


@property BOOL createableValue;
- (BOOL)createableValue;
- (void)setCreateableValue:(BOOL)value_;

//- (BOOL)validateCreateable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* custom;


@property BOOL customValue;
- (BOOL)customValue;
- (void)setCustomValue:(BOOL)value_;

//- (BOOL)validateCustom:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* customSetting;


@property BOOL customSettingValue;
- (BOOL)customSettingValue;
- (void)setCustomSettingValue:(BOOL)value_;

//- (BOOL)validateCustomSetting:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* deletable;


@property BOOL deletableValue;
- (BOOL)deletableValue;
- (void)setDeletableValue:(BOOL)value_;

//- (BOOL)validateDeletable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* deprecatedAndHidden;


@property BOOL deprecatedAndHiddenValue;
- (BOOL)deprecatedAndHiddenValue;
- (void)setDeprecatedAndHiddenValue:(BOOL)value_;

//- (BOOL)validateDeprecatedAndHidden:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* feedEnabled;


@property BOOL feedEnabledValue;
- (BOOL)feedEnabledValue;
- (void)setFeedEnabledValue:(BOOL)value_;

//- (BOOL)validateFeedEnabled:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* fullSyncCompleted_mm;


@property BOOL fullSyncCompleted_mmValue;
- (BOOL)fullSyncCompleted_mmValue;
- (void)setFullSyncCompleted_mmValue:(BOOL)value_;

//- (BOOL)validateFullSyncCompleted_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* fullSyncInProgress_mm;


@property BOOL fullSyncInProgress_mmValue;
- (BOOL)fullSyncInProgress_mmValue;
- (void)setFullSyncInProgress_mmValue:(BOOL)value_;

//- (BOOL)validateFullSyncInProgress_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* keyPrefix;


//- (BOOL)validateKeyPrefix:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* label;


//- (BOOL)validateLabel:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* labelPlural;


//- (BOOL)validateLabelPlural:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) id lastSyncError_mm;


//- (BOOL)validateLastSyncError_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* lastSyncedAt_mm;


//- (BOOL)validateLastSyncedAt_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) id layout_mm;


//- (BOOL)validateLayout_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* layoutable;


@property BOOL layoutableValue;
- (BOOL)layoutableValue;
- (void)setLayoutableValue:(BOOL)value_;

//- (BOOL)validateLayoutable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* mergeable;


@property BOOL mergeableValue;
- (BOOL)mergeableValue;
- (void)setMergeableValue:(BOOL)value_;

//- (BOOL)validateMergeable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) id metaDescription_mm;


//- (BOOL)validateMetaDescription_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) id metaLayout_mm;


//- (BOOL)validateMetaLayout_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* moreResultsURL_mm;


//- (BOOL)validateMoreResultsURL_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* objectName_mm;


//- (BOOL)validateObjectName_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* queryable;


@property BOOL queryableValue;
- (BOOL)queryableValue;
- (void)setQueryableValue:(BOOL)value_;

//- (BOOL)validateQueryable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* replicateable;


@property BOOL replicateableValue;
- (BOOL)replicateableValue;
- (void)setReplicateableValue:(BOOL)value_;

//- (BOOL)validateReplicateable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* retrieveable;


@property BOOL retrieveableValue;
- (BOOL)retrieveableValue;
- (void)setRetrieveableValue:(BOOL)value_;

//- (BOOL)validateRetrieveable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* searchable;


@property BOOL searchableValue;
- (BOOL)searchableValue;
- (void)setSearchableValue:(BOOL)value_;

//- (BOOL)validateSearchable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* serverObjectCount;


@property int32_t serverObjectCountValue;
- (int32_t)serverObjectCountValue;
- (void)setServerObjectCountValue:(int32_t)value_;

//- (BOOL)validateServerObjectCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* serverObjectName_mm;


//- (BOOL)validateServerObjectName_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) id syncInfo_mm;


//- (BOOL)validateSyncInfo_mm:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* triggerable;


@property BOOL triggerableValue;
- (BOOL)triggerableValue;
- (void)setTriggerableValue:(BOOL)value_;

//- (BOOL)validateTriggerable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* undeletable;


@property BOOL undeletableValue;
- (BOOL)undeletableValue;
- (void)setUndeletableValue:(BOOL)value_;

//- (BOOL)validateUndeletable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* updateable;


@property BOOL updateableValue;
- (BOOL)updateableValue;
- (void)setUpdateableValue:(BOOL)value_;

//- (BOOL)validateUpdateable:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) id urls;


//- (BOOL)validateUrls:(id*)value_ error:(NSError**)error_;






@end

@interface _MM_SFObjectDefinition (CoreDataGeneratedAccessors)

@end

@interface _MM_SFObjectDefinition (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveActivateable;
- (void)setPrimitiveActivateable:(NSNumber*)value;

- (BOOL)primitiveActivateableValue;
- (void)setPrimitiveActivateableValue:(BOOL)value_;




- (NSNumber*)primitiveCanFilterOnLastModified;
- (void)setPrimitiveCanFilterOnLastModified:(NSNumber*)value;

- (BOOL)primitiveCanFilterOnLastModifiedValue;
- (void)setPrimitiveCanFilterOnLastModifiedValue:(BOOL)value_;




- (NSNumber*)primitiveCheckingForDeletedObjects_mm;
- (void)setPrimitiveCheckingForDeletedObjects_mm:(NSNumber*)value;

- (BOOL)primitiveCheckingForDeletedObjects_mmValue;
- (void)setPrimitiveCheckingForDeletedObjects_mmValue:(BOOL)value_;




- (NSNumber*)primitiveCreateable;
- (void)setPrimitiveCreateable:(NSNumber*)value;

- (BOOL)primitiveCreateableValue;
- (void)setPrimitiveCreateableValue:(BOOL)value_;




- (NSNumber*)primitiveCustom;
- (void)setPrimitiveCustom:(NSNumber*)value;

- (BOOL)primitiveCustomValue;
- (void)setPrimitiveCustomValue:(BOOL)value_;




- (NSNumber*)primitiveCustomSetting;
- (void)setPrimitiveCustomSetting:(NSNumber*)value;

- (BOOL)primitiveCustomSettingValue;
- (void)setPrimitiveCustomSettingValue:(BOOL)value_;




- (NSNumber*)primitiveDeletable;
- (void)setPrimitiveDeletable:(NSNumber*)value;

- (BOOL)primitiveDeletableValue;
- (void)setPrimitiveDeletableValue:(BOOL)value_;




- (NSNumber*)primitiveDeprecatedAndHidden;
- (void)setPrimitiveDeprecatedAndHidden:(NSNumber*)value;

- (BOOL)primitiveDeprecatedAndHiddenValue;
- (void)setPrimitiveDeprecatedAndHiddenValue:(BOOL)value_;




- (NSNumber*)primitiveFeedEnabled;
- (void)setPrimitiveFeedEnabled:(NSNumber*)value;

- (BOOL)primitiveFeedEnabledValue;
- (void)setPrimitiveFeedEnabledValue:(BOOL)value_;




- (NSNumber*)primitiveFullSyncCompleted_mm;
- (void)setPrimitiveFullSyncCompleted_mm:(NSNumber*)value;

- (BOOL)primitiveFullSyncCompleted_mmValue;
- (void)setPrimitiveFullSyncCompleted_mmValue:(BOOL)value_;




- (NSNumber*)primitiveFullSyncInProgress_mm;
- (void)setPrimitiveFullSyncInProgress_mm:(NSNumber*)value;

- (BOOL)primitiveFullSyncInProgress_mmValue;
- (void)setPrimitiveFullSyncInProgress_mmValue:(BOOL)value_;




- (NSString*)primitiveKeyPrefix;
- (void)setPrimitiveKeyPrefix:(NSString*)value;




- (NSString*)primitiveLabel;
- (void)setPrimitiveLabel:(NSString*)value;




- (NSString*)primitiveLabelPlural;
- (void)setPrimitiveLabelPlural:(NSString*)value;




- (id)primitiveLastSyncError_mm;
- (void)setPrimitiveLastSyncError_mm:(id)value;




- (NSDate*)primitiveLastSyncedAt_mm;
- (void)setPrimitiveLastSyncedAt_mm:(NSDate*)value;




- (id)primitiveLayout_mm;
- (void)setPrimitiveLayout_mm:(id)value;




- (NSNumber*)primitiveLayoutable;
- (void)setPrimitiveLayoutable:(NSNumber*)value;

- (BOOL)primitiveLayoutableValue;
- (void)setPrimitiveLayoutableValue:(BOOL)value_;




- (NSNumber*)primitiveMergeable;
- (void)setPrimitiveMergeable:(NSNumber*)value;

- (BOOL)primitiveMergeableValue;
- (void)setPrimitiveMergeableValue:(BOOL)value_;




- (id)primitiveMetaDescription_mm;
- (void)setPrimitiveMetaDescription_mm:(id)value;




- (id)primitiveMetaLayout_mm;
- (void)setPrimitiveMetaLayout_mm:(id)value;




- (NSString*)primitiveMoreResultsURL_mm;
- (void)setPrimitiveMoreResultsURL_mm:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveObjectName_mm;
- (void)setPrimitiveObjectName_mm:(NSString*)value;




- (NSNumber*)primitiveQueryable;
- (void)setPrimitiveQueryable:(NSNumber*)value;

- (BOOL)primitiveQueryableValue;
- (void)setPrimitiveQueryableValue:(BOOL)value_;




- (NSNumber*)primitiveReplicateable;
- (void)setPrimitiveReplicateable:(NSNumber*)value;

- (BOOL)primitiveReplicateableValue;
- (void)setPrimitiveReplicateableValue:(BOOL)value_;




- (NSNumber*)primitiveRetrieveable;
- (void)setPrimitiveRetrieveable:(NSNumber*)value;

- (BOOL)primitiveRetrieveableValue;
- (void)setPrimitiveRetrieveableValue:(BOOL)value_;




- (NSNumber*)primitiveSearchable;
- (void)setPrimitiveSearchable:(NSNumber*)value;

- (BOOL)primitiveSearchableValue;
- (void)setPrimitiveSearchableValue:(BOOL)value_;




- (NSNumber*)primitiveServerObjectCount;
- (void)setPrimitiveServerObjectCount:(NSNumber*)value;

- (int32_t)primitiveServerObjectCountValue;
- (void)setPrimitiveServerObjectCountValue:(int32_t)value_;




- (NSString*)primitiveServerObjectName_mm;
- (void)setPrimitiveServerObjectName_mm:(NSString*)value;




- (id)primitiveSyncInfo_mm;
- (void)setPrimitiveSyncInfo_mm:(id)value;




- (NSNumber*)primitiveTriggerable;
- (void)setPrimitiveTriggerable:(NSNumber*)value;

- (BOOL)primitiveTriggerableValue;
- (void)setPrimitiveTriggerableValue:(BOOL)value_;




- (NSNumber*)primitiveUndeletable;
- (void)setPrimitiveUndeletable:(NSNumber*)value;

- (BOOL)primitiveUndeletableValue;
- (void)setPrimitiveUndeletableValue:(BOOL)value_;




- (NSNumber*)primitiveUpdateable;
- (void)setPrimitiveUpdateable:(NSNumber*)value;

- (BOOL)primitiveUpdateableValue;
- (void)setPrimitiveUpdateableValue:(BOOL)value_;




- (id)primitiveUrls;
- (void)setPrimitiveUrls:(id)value;




@end
