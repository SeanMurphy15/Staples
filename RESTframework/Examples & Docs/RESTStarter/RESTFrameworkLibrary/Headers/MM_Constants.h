
#define		LIBRARY_VERSION							1.1

#define		MISSING_LINK_ATTRIBUTE_NAME				@"missingLink_mm"
#define		REMOVE_LINK_NAME						@"REMOVE_LINK_mm"

#define		MMID_FIELD								@"MM_ID"
#define		MMID_PREFIX								@"mm_id://"

#define		RELATIONSHIP_SFID_SHADOW(n)				($S(@"%@_sfid_shadow_mm", n))
#define		RELATIONSHIP_OBJECTID_SHADOW(n)			($S(@"%@_objectid_shadow_mm", n))
#define		DATA_URL_SHADOW(n)						($S(@"%@_url_shadow_mm", n))
#define		DATA_PATH_SHADOW(n)						($S(@"%@_path_shadow_mm", n))
#define		GENERATED_BACKLINK_NAME(n, d)			($S(@"%@_%@_backlink_mm", d, n))
#define		IS_GENERATED_BACKLINK(n)				([n hasSuffix: @"_backlink_mm"])

#define		DEFAULTS_LAST_LOG_PATH					@"MM_DEFAULTS_LAST_LOG_PATH"
#define		DEFAULTS_LAST_IDENTITY_URL				@"DEFAULTS_LAST_IDENTITY_URL"
#define		DEFAULTS_CURRENT_CLIENT_ID              @"DEFAULTS_CURRENT_CLIENT_ID"
#define		DEFAULTS_REFRESH_TOKEN                  @"DEFAULTS_REFRESH_TOKEN"
#define		DEFAULTS_CURRENT_IDENTITY_URL			@"DEFAULTS_CURRENT_IDENTITY_URL"
#define		DEFAULTS_CURRENT_ACCESS_TOKEN			@"DEFAULTS_CURRENT_ACCESS_TOKEN"
#define		DEFAULTS_CURRENT_INSTANCE_URL			@"DEFAULTS_CURRENT_INSTANCE_URL"
#define		DEFAULTS_HAS_LOGGED_IN_AT_LEAST_ONCE	@"DEFAULTS_HAS_LOGGED_IN_AT_LEAST_ONCE"
#define		DEFAULTS_LOGIN_DOMAIN					@"DEFAULTS_LOGIN_DOMAIN"
#define		DEFAULTS_SOAP_URL						@"DEFAULTS_SOAP_URL"
#define		DEFAULTS_CURRENTLY_LOGGED_IN			@"MM_LI"
#define		DEFAULTS_FULL_USER_ID					@"MM_FUID"
#define		DEFAULTS_LAST_USER_ID					@"MM_LUID"
#define		DEFAULTS_USE_SANDBOX					@"MM_DEFAULTS_USE_SANDBOX"
#define		LAST_METADATA_SYNCDATE					@"MM_LAST_METADATA_SYNCDATE"

#define		LOGIN_UI_WAS_PRESENTED_KEY				@"LOGIN_UI_WAS_PRESENTED_KEY"
#define		LOGIN_NEW_USER_LOGGED_IN_KEY			@"LOGIN_NEW_USER_LOGGED_IN_KEY"

#define		CURRENT_FILE_TAG						[NSString stringWithFormat: @"%@ (%s:%d)", NSStringFromSelector(_cmd), __FILE__, __LINE__]

//=============================================================================================================================
#pragma mark Errors

#define		kMMFrameworkErrorDomain					@"com.modelmetrics.sfframework.error"

#define		kMMFrameworkErrorNoData					100





//=============================================================================================================================
#pragma mark User Defaults
#define kMMDefaults_SyncCompletedOnce				@"MMSyncCompletedOnce"





//=============================================================================================================================
#pragma mark Macros
#if TESTING
	#define		IF_TESTING(...)							{__VA_ARGS__;}
#else
	#define		IF_TESTING(...)							{}
#endif