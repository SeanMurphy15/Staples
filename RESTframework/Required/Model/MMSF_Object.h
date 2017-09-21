


/**************************************************
 *
 *	This class serves as a generic base class for all 
 *	objects pulled out of the context
 *
 *	If you want to create a custom subclass for an object, 
 *	say, Contact, create a class named "MMSF_Contact", and 
 *	the framework will link it appropriately.
 *
 *	To generate a custom query when syncing, override the 
 *	class method
 *
 *		+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs;
 *
 *	To make multiple, or unusual, calls when syncing, implement:
 *	
 *		+ (void) syncWithQuery: (MM_SOQLQueryString *) query;
 *		
 *		A sample implementation might look like:
 *	{
 * 		MM_RestOperation	*op = [MM_RestOperation operationWithQuery: query 
 *															  groupTag: self.objectIDString 
 *													   completionBlock: ^(NSError *error, id json, MM_RestOperation *completedOp) {
 *															[self.definition parseJSONResponse: json withError: error];
 *															return NO;
 *														}];
 * 
 *		[[MM_SyncManager sharedManager] queueOperation: op];
 *	}
 *
 *
 **************************************************/



@class MM_SFObjectDefinition;


@interface MMSF_Object : NSManagedObject

@property (nonatomic, retain) NSDictionary *lastSnapshot;
@property (nonatomic, retain) NSString *Id, *mmID;
@property (nonatomic, readonly) NSDate *LastModifiedDate, *CreatedDate, *SystemModStamp;
@property (nonatomic, readonly) MMSF_Object *owner;
@property (nonatomic, strong) MMSF_Object *RecordTypeId;
@property (nonatomic, retain) NSString *recordTypeName, *Name;
@property (nonatomic, readonly) MM_SFObjectDefinition *definition;
@property (nonatomic) BOOL shouldRollbackFailedSaves;
@property (nonatomic, readonly) BOOL isEmptyObject, existsOnSalesforce, isEditing;
@property (nonatomic, strong) MMSF_Object *parent;				//for an object with a ParentId polymorphic relationship
@property (nonatomic, strong) NSSet *fieldsToForceToServer;
@property (nonatomic) NSUInteger editCount;

+ (NSString *) entityName;
+ (NSDictionary *) shadowFieldNamesFromRelationships: (NSDictionary *) relationships andAttributes: (NSDictionary *) attributes;
+ (void) clearSFIDCache;
+ (void) logSFIDCache;
+ (NSString *) privateDocumentsPath;

- (id) importRecord: (NSDictionary *) record includingDataBlobs: (BOOL) includingDataBlobs;
- (id) importRecord: (NSDictionary *) record withFieldPrefix: (NSString *) prefix includingDataBlobs: (BOOL) includingDataBlobs;
- (void) deleteFromSalesforce;						//call this to delete the object from the server
- (void) deleteFromSalesforcePushingChanges: (BOOL) pushChanges;
- (void) deleteFromSalesforceAndLocal;
- (void) deleteFromSalesforceAndLocalPushingChanges: (BOOL) pushChanges;
- (void) wasDeletedFromSalesforce;					//[NOT CURRENTLY IMPLEMENTED. Use -prepareForDeletion instead] this is called during a sync if the object was deleted from the server since the last sync

- (NSDictionary *) snapshot;

//there's a per-object editCount value. Calls to -beginEditing can be layered, so long as they're matched with calls to -finishEditingSavingChanges:
//calling this with NO will reset the edit count and blow away all changes since the first -beginEditing
//callign -finalizeEditingAndPushingToServer: will also reset the count, but will save the object

- (void) beginEditing;
- (BOOL) finishEditingSavingChanges: (BOOL) saveChanges;			//returns YES if there are changes to save
- (BOOL) finishEditingSavingChanges: (BOOL) saveChanges andPushingToServer: (BOOL) pushNow;
- (void) finalizeEditingAndPushingToServer: (BOOL) pushNow;
- (BOOL) shouldQueueChangeForOriginal: (NSDictionary *) original toNewValues: (NSDictionary *) newValues atDate: (NSDate *) date;	//last chance to cancel a change before it's committed to the DB

- (void) rollbackToSnapshot: (NSDictionary *) snapshot;
- (BOOL) fieldIsReadOnly: (NSString *) field;

- (void) refreshDataBlobs: (BOOL) onlyIfNeeded;
- (void) refreshDataBlobsIfNeeded;

- (NSSet *) attachments;
- (NSString *) stringForKeyPath: (NSString *) keyPath;		//can pass either a string keyPath, or an array. If an array is passed, it's assumed to be a format string followed by keyPaths
- (NSString *) titleForDataField: (NSString *) dataFieldName;
- (NSString *) pathForDataField: (NSString *) dataFieldName;
- (NSString *) mimeTypeForDataField: (NSString *) fieldName;
- (void) setStringValue: (NSString *) value forKey: (NSString *) key;
- (BOOL) hasValueForKeyPath: (NSString *) keyPath;

- (BOOL) connectMissingLinksUsingRelationships: (NSDictionary *) relationships attributes: (NSDictionary *) attributes shadowFieldNames: (NSDictionary *) shadowFieldNames andDataFields: (NSMutableSet *) dataFields withLinkTag: (NSUInteger) tag;

- (void) reloadFromServer;
- (void) didFailToSaveToServerWithError: (NSError *) error;
- (void) didSaveToServer: (BOOL) isNew;

+ (void) setDynamicRecordLinkingEnabled: (BOOL) enabled;
+ (BOOL) isDynamicRecordLinkingEnabled;

- (void) forceServerPushForField: (NSString *) field;
- (NSArray *) picklistOptionsForField: (NSString *) fieldName;
- (NSString *) labelForField: (NSString *) field;

- (MMSF_Object *) parentOfType: (NSString *) type;			//for an object with a ParentId polymorphic relationship

+ (void) connectReturnedSalesforceID: (NSString *) sfid toObjectID: (NSString *) objectID forField: (NSString *) field onEntity: (NSString *) entityName inContext: (NSManagedObjectContext *) moc;	//used when fetching the parent of a ParentId link

- (void) setWhatID: (MMSF_Object *) what;
- (id) whatIDOfEntityType: (NSString *) type;
- (BOOL) objectIDIsValidForStore: (NSManagedObjectID *) objectID;

- (UIImage *) imageWithIDInField: (NSString *) fieldName;
- (UIImage *) attachmentImage;
- (MMSF_Object *) setAttachmentImage: (UIImage *) image withAttributes: (NSDictionary *) attr;
- (MMSF_Object *) attachmentNamed: (NSString *) name;
- (UIImage *) attachmentImageNamed: (NSString *) name;
@end


@interface NSString (MMSF_Object)
- (id) valueForField: (NSString *) field inRecord: (NSManagedObject *) record;
@end


typedef NSString * (^recordFieldCalculationBlock)(MMSF_Object *record);

#define			MM_FIELD(entityName, fieldName)				(fieldName)
