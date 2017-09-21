//
//  PrefixCommon.h
//  ios_dsa
//
//  Created by Guy Umbright on 10/14/11.
//  Copyright (c) 2011 Kickstand Software. All rights reserved.
//

#ifndef ios_dsa_PrefixCommon_h
#define ios_dsa_PrefixCommon_h

/*contact found*/
#define kNotification_ContactRecordFound			@"kNotification_ContactRecordFound"

#define			BRAND_MODEL_METRICS						0 //obs?
#define			CONTACTS_ARE_UNOWNED					0 //
#define			ACCOUNTS_ARE_UNOWNED					1 //
#define			OPPORTUNITIES_ARE_UNOWNED				1 //
#define			CONTACTS_AVAILABLE						1 //
#define			USE_MODAL_LOGIN							0 //
#define			USE_POPOVER_LOGIN						1 //
#define			ALLOW_ORPHAN_CONTENT_ITEMS				0 // 
#define			AUTO_LOGIN_NO_SYNC						0 //
#define			DISABLE_SFDC_AUTHENTICATION				0 //
#define			PERFORM_FAKE_SYNC						0 //
#define			PRELOAD_CREDS							1 //
#define			TRACK_RECORD_TYPES						0 //			
#define         DISABLE_FULL_METADATA_FIELDS            1
#define			SUPPORT_ZIP_FILES						1

///////////////////////////////////////////////////////////////////////
#define         CATEGORIES_ORDERED_ON                   1                 //Make this 1, to switch on the ordered categories.
///////////////////////////////////////////////////////////////////////

#ifndef         POST_CONTENT_TO_CHATTER    
#define         POST_CONTENT_TO_CHATTER        0				//chatter off by default
#endif

#ifndef         PURGE_UNREFERENCED_CONTENT_ITEMS    //
#define         PURGE_UNREFERENCED_CONTENT_ITEMS        1 //
#endif

#ifndef         MM_LS_DSA_BUILD //
	#define			MM_LS_DSA_BUILD							1 //obs? or at least unneeded?
#endif

#ifndef         INCLUDE_ABOUT_TAB //
	#define         INCLUDE_ABOUT_TAB                       0 //
#endif

#ifndef         DISPLAY_MM_LOGO //
	#define         DISPLAY_MM_LOGO                         1 //
#endif

#ifndef         TIME_LIMITED_DEMO   //
	#define         TIME_LIMITED_DEMO                         0 //
#endif

#ifndef         MAILTOSALESFORCE_ENABLED   //
	#define         MAILTOSALESFORCE_ENABLED                0 
#endif

//#ifndef         HTMLBUNDLECONTENTSUPPORTED   //
//	#define         HTMLBUNDLECONTENTSUPPORTED                0 
//#endif

#ifndef         OPENWITHSUPPORTED   //
	#define         OPENWITHSUPPORTED                       0 
#endif

#ifndef         APP_STORE_BUILD   //
	#define         APP_STORE_BUILD                       0 
#endif

#define         LOGIN_SHOW_TESTSERVER                   1 //

/* BUILD_WITH_CORDOVA default is OFF

 To be able sucessfully use PhoneGap/Cordova in DSA you need to walk through next steps:
 
 1. Download latest version of PhoneGap library here: http://phonegap.com/download
 
 2. Unpack it anywhere you want and drag CordovaLib.xcodeproj file just right into left pane of this project. After this you will see that CordovaLib.xcodeproj is
 
 now should be added as sub-project. If it's not opens, close all other Xcode project where CordovaLib.xcodeproj is used and reopen current project.
 
 3. Add CordovaLib as ios_dsa target dependency in project settings -> Build Phases
 
 4. Add libCordova.a into "Link Binary With Libraries" list
 
 5. Update the reference:
 
     5.1. Launch Terminal.app
     5.2. Go to the location where you installed Cordova (see Step 1), in the bin sub-folder
     
     5.3. Run the script below where the first parameter is the path to your project's .xcodeproj file:
     
     update_cordova_subproject path/to/your/project/xcodeproj

 6. Set BUILD_WITH_CORDOVA to 1 and try to build
 
 7. If you did everything right but you see Cordova related errors, write email to abilous@modelmetris.com with a list of errors
 
*/

#ifndef         BUILD_WITH_CORDOVA   //
    #define         BUILD_WITH_CORDOVA                    1
#endif

#define			CONTENT_ITEM_DOCUMENT_TYPE_FIELD		@"Document_Type__c" //

#define			kTintColor								[UIColor colorWithRed: 0.68 green: 0.82 blue: 0.21 alpha: 1.0]
#define			kLoginScreenTextColor					[UIColor blackColor]
#define			kTrainingTabLabel                       @"Training"

#define			kDefaultProblemReportEmail				@"support@modelmetrics.com"

#define			kDefaultCalendarWebLink					@"http://www.modelmetrics.com"


#define			kDefaultSyncEntities					[NSMutableArray arrayWithObjects:   [SF_User entityName],\
                                                                                            [SF_MobileAppConfig entityName],\
                                                                                            [SF_CategoryMobileConfig entityName],\
                                                                                            [SF_Category entityName], \
                                                                                            [SF_ContentItem entityName],\
                                                                                            [SF_Account entityName],\
                                                                                            [SF_Contact entityName],\
                                                                                            [SF_Attachment entityName],nil];

#define			kOAuth_AuthorizeURL						@"https://%@.salesforce.com/services/oauth2/authorize"


#define			kDefaultToken							@"1fJq0A09FS6wBGw2P3RcFYJ1i"

#define         kDefaultsKey_DemoMode                    @"com.modelmetrics.dsa.InDemoMode"

#define kDSAInternalModeDefaultsKey    @"internalMode"
#define kDSAInternalModeNotificationKey @"com.modelmetrics.dsa.internalmodechanged"
#define kDSANewContentAvailableNotificationKey @"com.modelmetrics.dsa.contentupdate"

#if APP_STORE_BUILD
	#define         DEMO_LOGIN_URL                                @"https://login.salesforce.com/services/oauth2/token"
	#define         kDefaultsKey_DemoMode                    @"com.modelmetrics.dsa.InDemoMode"
#endif

#define         DEMO_MODE_CHANGED_NOTIFICATION @"com.modelmetrics.dsa.demomodechanged"
#define         kNotification_ReloadConfiguration @"com.modelmetrics.dsa.reloadconfiguration"

#endif


#define			kOAuthRedirectURI					@"https://login.salesforce.com/services/oauth2/success"
#define			kOAuthLoginDomain					@"login.salesforce.com"

#define	BUILD_FOR_ORG_62			0

#if BUILD_FOR_ORG_62
#define kRemoteAccessConsumerKey @"3MVG9A2kN3Bn17htx2jhQxAmUH16strArnWzds2JGaptVLt4RSaTPstAeWU3C00kijn0Q8Wou6lWgGjGZf_Ht"               // HOAKULA KEY
#else
#define	kRemoteAccessConsumerKey		@"3MVG9yZ.WNe6byQArrGXHfKC8Odebkz46h5_viRgVA6IUviZ4jOZZRWNQds0n_OH0m2y7.hUloTQ836aY9iHA"				// current DSA
#endif

