

#define		kNotification_LogInViewDidAppear					@"kNotification_LogInViewDidAppear"
#define		kNotification_DidLogIn								@"kNotification_DidLogIn"
#define		kNotification_DidAuthenticate						@"kNotification_DidAuthenticate"
#define		kNotification_LoginComplete							kNotification_DidLogIn								//deprecated
#define		kNotification_LoginViewControllerDidDismiss			@"kNotification_LoginViewControllerDidDismiss"
#define		kNotification_LoginViewControllerWillDismiss		@"kNotification_LoginViewControllerWillDismiss"
#define		kNotification_WillLogOut							@"kNotification_WillLogOut"							//may get sent more than once
#define		kNotification_DidLogOut								@"kNotification_DidLogOut"
#define		kNotification_BlobDownloaded						@"kNotification_BlobDownloaded"						//objectID of the entity, dictionary has field
#define		kNotification_OAuthCredsExpired						@"kNotification_OAuthCredsExpired"					//treat this as a login attempt; try to show the login controller
#define		kNotification_OAuthLoginFailed						@"kNotification_OAuthLoginFailed"
#define		kNotification_FullResyncWillBegin					@"kNotification_FullResyncWillBegin"

#define		kNotification_OrgSyncObjectsChanged					@"kNotification_OrgSyncObjectsChanged"				//entity names added or set to
#define		kNotification_ObjectDefinitionsImported				@"kNotification_ObjectDefinitionsImported"
#define		kNotification_MetaDataFetchStarted                  @"kNotification_MetaDataFetchStarted"
#define		kNotification_MetaDataDownloadsComplete				@"kNotification_MetaDataDownloadsComplete"
#define		kNotification_ModelUpdateBegan						@"kNotification_ModelUpdateBegan"
#define		kNotification_ModelUpdateComplete					@"kNotification_ModelUpdateComplete"
#define		kNotification_QueueingComplete                      @"kNotification_QueueingComplete"
#define		kNotification_ObjectsImported						@"kNotification_ObjectsImported"					//salesforce IDs that were added
#define		kNotification_ObjectsDeleted						@"kNotification_ObjectsDeleted"						//objectIDs that were removed
#define		kNotification_ObjectChangesRolledBack				@"kNotification_ObjectChangesRolledBack"			//objectID of the rolled back object
#define		kNotification_ObjectChangesSaved					@"kNotification_ObjectChangesSaved"					//objectID of the saved object
#define		kNotification_ObjectCreated							@"kNotification_ObjectCreated"						//objectID of the new object
#define		kNotification_AllObjectChangesSaved					@"kNotification_AllObjectChangesSaved"
#define		kNotification_ObjectReloaded						@"kNotification_ObjectReloaded"						//objectID of the reloaded object
#define		kNotification_ObjectLayoutDescriptionAvailable		@"kNotification_ObjectLayoutDescriptionAvailable"	//"name" of the described object

#define		kNotification_ObjectSaveError						@"kNotification_ObjectSaveError"					//objectID of the unsaved object, error in the user info
#define		kNotification_QueueSaveError						@"kNotification_QueueSaveError"						//objectID of the unsaved object, exception in the user info

#define		kNotification_SyncWillBegin							@"kNotification_SyncWillBegin"
#define		kNotification_SyncBegan								@"kNotification_SyncBegan"
#define		kNotification_SyncWillResume						@"kNotification_SyncWillResume"
#define		kNotification_SyncResumed							@"kNotification_SyncResumed"
#define		kNotification_SyncBatchReceived						@"kNotification_SyncBatchReceived"					//the name of the object
#define		kNotification_ObjectSyncBegan						@"kNotification_ObjectSyncBegan"					//the name of the object, {total: num objects}
#define		kNotification_ObjectSyncContinued					@"kNotification_ObjectSyncContinued"				//the name of the object, {total: num objects, count: num we're working on} 
#define		kNotification_ObjectSyncCompleted					@"kNotification_ObjectSyncCompleted"				//the name of the object
#define		kNotification_ParseCompleted						@"kNotification_ParseCompleted"
#define		kNotification_ObjectDataBeginning					@"kNotification_ObjectDataBeginning"				//the SFID of the object
#define		kNotification_SyncComplete							@"kNotification_SyncComplete"
#define		kNotification_SyncCancelled							@"kNotification_SyncCancelled"
#define		kNotification_SyncPaused							@"kNotification_SyncPaused"
#define		kNotification_SyncCountsReceived					@"kNotification_SyncCountsReceived"
#define		kNotification_WillRemoveAllData						@"kNotification_WillRemoveAllData"
#define		kNotification_DidRemoveAllData						@"kNotification_DidRemoveAllData"
#define		kNotification_PushingChangesBegan					@"kNotification_PushingChangesBegan"
#define		kNotification_PushingChangesCompleted				@"kNotification_PushingChangesCompleted"
#define		kNotification_PendingChangeQueued					@"kNotification_PendingChangeQueued"

#define		kNotification_ObjectWasEdited						@"kNotification_ObjectWasEdited"					//the objectID of the object
#define		kNotification_ObjectWasCreated						@"kNotification_ObjectWasCreated"					//the objectID of the object

#define		kNotification_SandboxSwitchToggled					@"kNotification_SandboxSwitchToggled"				//the actual UISwitch

#define		kNotification_AllDataDeletedDueToModelUpdate		@"kNotification_AllDataDeletedDueToModelUpdate"


#define		kNotification_DisplayWebpage						@"kNotification_DisplayWebpage"						//URL to load

#define		kNotification_MissingLinksConnectionStarting		@"kNotification_MissingLinksConnectionStarting"		
#define		kNotification_MissingLinksConnectingObject          @"kNotification_MissingLinksConnectingObject"		//name of the object being linked
#define		kNotification_MissingLinksConnectedObject           @"kNotification_MissingLinksConnectedObject"		//name of the object being linked

#define		kNotification_WillResetMainContext					@"kNotification_WillResetMainContext"				//sent before reseting the main context

#define     kNotification_UnresolvedSyncDependencies            @"kNotification_UnresolvedSyncDependencies"

#define		kNotification_ConnectionStatusChanged				kConnectionNotification_ConnectionStateChanged

#define		kNotification_WillMoveDataAsideForAtomicSync		@"kNotification_WillMoveDataAsideForAtomicSync"
#define		kNotification_DidMoveDataAsideForAtomicSync			@"kNotification_DidMoveDataAsideForAtomicSync"

#define		kNotification_WillBeginAtomicRestore				@"kNotification_WillBeginAtomicRestore"
#define		kNotification_DidCompleteAtomicRestore				@"kNotification_DidCompleteAtomicRestore"

#define		kNotification_WillClearAllData						@"kNotification_WillClearAllData"
#define		kNotification_DidClearAllData						@"kNotification_DidClearAllData"
