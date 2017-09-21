#import "_MM_SFChange.h"

@class MMSF_Object;

typedef NS_ENUM(uint8_t, MMSF_Change_Error_Behavior) {
	MMSF_Change_Error_Behavior_Discard,				//any errors received are simply ignored and discarded.
	MMSF_Change_Error_Behavior_Retain,				//errors are saved until handled. They are retried each time pushPendingChanges… is called. Current behavior, and the default
	MMSF_Change_Error_Behavior_Alert				//an alert is shown describing the error, with options to Discard or Retry (Retain). Useful for debugging 
};

#define SNAPSHOT_OBJECT_SUFFIX				@"__MM_ObjectID_/"
#define SNAPSHOT_SFID_SUFFIX				@"__MM_SFID_/"

#define	FIELD_BY_ADDING_OBJET_SUFFIX(f)		([f stringByAppendingString: SNAPSHOT_OBJECT_SUFFIX])
#define	FIELD_BY_REMOVING_OBJECT_SUFFIX(f)	([f substringToIndex: f.length - SNAPSHOT_OBJECT_SUFFIX.length])
#define	IS_FIELD_SNAPSHOT_OF_OBJECT(f)		([f hasSuffix: SNAPSHOT_OBJECT_SUFFIX])

@interface MM_SFChange : _MM_SFChange

@property (nonatomic, readonly) NSDictionary *modifiedValuesForServer;				//this returns the modified values with all records replaced with Salesforce IDs

+ (void) setPendingObjectInterval: (NSTimeInterval) interval;

+ (void) queueChangeForObject: (MMSF_Object *) object withOriginalValues: (NSDictionary *) original changedValues: (NSDictionary *) changedValues atTime: (NSDate *) date;
+ (void) queueDeleteForObject: (MMSF_Object *) object atTime: (NSDate *) date;
+ (void) pushPendingChangesWithCompletionBlock: (booleanArgumentBlock) completion;
+ (BOOL) doesChangeExistForObject: (MMSF_Object *) object;
+ (BOOL) doesChangeExistForRobustIDString:(NSString*)robustID;
+ (void) removePendingChangesForObject: (MMSF_Object *) object;
+ (NSUInteger) numberOfPendingChanges;
+ (BOOL) isChangeSyncingInProgress;

+ (void) stopPushingChanges;													//call to stop pushing changes to the server
+ (void) startPushingChanges;
+ (BOOL) isPushingChangesStopped;
+ (void) forcePushRestart;

- (void) rollback;

- (NSDictionary *) originalValuesInContext: (NSManagedObjectContext *) moc;
- (void) setOriginalValues: (NSDictionary *) originalValues;

- (NSDictionary *) modifiedValuesInContext: (NSManagedObjectContext *) moc;
- (void) setModifiedValues: (NSDictionary *) modifiedValues;
+ (void) clearAllPendingChangesForUserID: (NSString *) sfID;
+ (void) resetErrors;

+ (MMSF_Change_Error_Behavior) changeErrorBehavior;
+ (void) setChangeErrorBehavior: (MMSF_Change_Error_Behavior) behavior;
@end


@interface NSDictionary (MMSF_Snapshots)
@property (nonatomic, readonly) NSDictionary *dictionaryByConvertingObjectsToIDs;

- (NSDictionary *) dictionaryByConvertingIDsToObjectsInContext: (NSManagedObjectContext *) moc;
@end