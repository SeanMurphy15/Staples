<!-- 
Copyright (c) 2014, salesforce.com, inc. All rights reserved.

This document is written in [markdown](https://guides.github.com/overviews/mastering-markdown/). It is recommended when reading or printing this document to use the following tool:
[Mou](http://mouapp.com/)

April 2, 2014

-->


![image](SalesforceLogo.jpg)

# Digital Sales Aid Application Programming Interface## Introduction
### Purpose
This document describes the Digital Sales Aid Application Programming Interface (DSA API). The DSA API is intended for use in enriching the HTML 5 Bundle applications by allowing them to access different information and services in the DSA.
### References[UIWebView API Reference](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIWebView_Class/Reference/Reference.html)  

[Apache Cordova](https://cordova.apache.org/)  


### Contents


[Overview](#overview)  

[API Description](#api)  
 * 	[DSAOAuthPlugin](#api-auth)  
 * 	[DSAContent](#api-content)  
 * 	[DSANavigation](#api-nav)  
 * 	[DSAContact](#api-contact)  
 * 	[DSASynchronizedData](#api-sync)  

 

<a id="overview"></a>### Overview
The DSA API is implemented as a set of Cordova/PhoneGap plugins. As such the DSA API provides a set of Javascript Objects that implement different functionality. Furthermore the standard Cordova plugins will be available to the HTML5 bundles with the exception of application startup events notification. <a id="api"></a>## API Description 
<a id="api-auth"></a>### DSAOAuthPlugin
The DSAOAuthPlugin provides access to authentication and session information such as the access token, the refresh token, and the instance URL. This information can be used by an embedded HTML5 application in order to connect directly to the Salesforce.com REST server-side APIs.

#### DSAOAuth.getOAuthSessionID (success,error)Returns the OAuth session ID if user is logged in. Can be used to send requests to SFDC without involving native code.Preconditions: User is logged in to the application.Postconditions: The Success function receives the Access token. Example:	DSAOAuth. getOAuthSessionID (function(result) {			console.log("Session Id " + result);		}, function(result) {			console.log("Error");		})#### DSAOAuth.getRefreshToken (success,error)
Returns the refresh token. This can be sued to refresh the sessions to avoid logging in every time the session expires.Preconditions: User is logged in to the application.  Postconditions: The Success function receives the Refresh token.  
Example:      DSAOAuth.getRefreshToken(function(result) {			console.log("Refresh Token " + result);		}, function(result) {			console.log("Error");		});   #### DSAOAuth.getOAuthClientID (success,error)Returns the Client Id.Preconditions: User is logged in to the application.  Postconditions: The Success function receives the Client Id.  
Example:    DSAOAuth.getOAuthClientID (function(result) {			console.log("Client Id " + result);		}, function(result) {			console.log("Error");		});#### DSAOAuth.getInstanceUrl (success,error)  
Returns the Instance Url.Preconditions: User is logged in to the application.Postconditions: The Success function receives the Instance Url. Example:    DSAOAuth.getInstanceUrl (function(result) {			console.log("Instance URL: " + result);		}, function(result) {			console.log("Error");		});#### DSAOAuth.getLoginUrl (success,error)  
Returns the Login Url.Preconditions: User is logged in to the application.  Postconditions: The Success function receives the Login Url.   Example:    DSAOAuth.getLoginUrl (function(result) {			console.log("Login URL: " + result);		}, function(result) {			console.log("Error");		});#### DSAOAuth.getUserAgent (success,error)
Returns the User Agent.Preconditions: User is logged in to the application.Postconditions: The Success function receives the User Agent String. Example:    DSAOAuth.getUserAgent(function(result) {			console.log("User Agent: " + result);		}, function(result) {			console.log("Error");		});<a id="api-content"></a>### DSAContent
The DSAContent plugin provides access to the DSA synchronized content. The synchronized content is available even when the application is offline.  
The HTML Bundle Creator will be able to explore the structure of the information in terms of its categories and subcategories. The Bundle creator will be able to obtain URI lo the local content using this plugin. The content can then be opened using standard HTML5/Javascript or using the DSA Content View windows, which provide content review tracking.

#### DSAContent.getCategory (CategoryPathName, Success, Fail)
The Category Path Name is an array of string. Each string represents a category name. For example:    var catPathName =   “Top Cat,Sub-Cat 1”;If CategoryPathName exists in the DSA repository, the Category Content Object expressed in JSON will be returned as an argument to the Success callback, otherwise the Fail callback will be executed with the CategoryName.    
  The Category Content Object will have the following structure:JSON Example:    	{		"name" : "Category 1",		"sub-categories" : [			{				"name" : "Sub-category 1"			} 		],		"content" : [			{				"SFDCID" : “068d00000000NgLAAU”,				"URI" : "file://DSA/content/Movie.m4v",				"Type" : "Movie",				"Name" : "Movie.m4v"			}		]	}Preconditions: CategoryPathName represents a category in the DSA repository.  Postconditions: The Success function is executed with the categoryContent parameter. If the file cannot be opened, the ContentName will be returned.  Example:  
	DSAContentPlugin.getCategoryContent("Category,Subcategory", function(result{			var returnedObject = JSON.parse(result);
			alert(JSON.stringify(returnedObject));
		},function(result) {                                         			console.log("Error");		});#### DSAContent.getCategoryContentArray(categoryPath,success,fail)
In most cases the above method should be used except when you have two categories with the same name at the same path. In that case you should use getCategoryArray(). This method works like getCategory (CategoryPathName, Success, Fail), but getCategoryArray will return array of all categories with matching name instead.  JSON Example:  	[	 {	  "name" : "Category 1",	  "sub-categories" : [	    {	      "name" : "Sub-category 1"	    }	  ],	  "content" : [	    {	      "SFDCID" : “068d00000000NgLAAU”,	      "URI" : "file://DSA/content/Movie.m4v",	      "Type" : "Movie",	      "Name" : "Movie.m4v"	    }	  ]	 },	 {	  "name" : "Category 1",	  "sub-categories" : [	    {	      "name" : "Sub-category 2"	    }	  ],	  "content" : [	    {	      "SFDCID" : “054d000055000NgLBBU”,	      "URI" : "file://DSA/content/MediaSurvey.pdf",	      "Type" : "PDF",	      "Name" : "MediaSurvey.pdf"	    }	  ]	 }	]Preconditions: categoryPath represents a category in the DSA repository.  Postconditions: The Success function is executed with the categoryContentArray parameter. If the file cannot be opened, the ContentName will be returned.  Example:	DSAContentPlugin.getCategoryContentArray("category,subcategory", function(result) {                                       			var returnedObject = JSON.parse(result);
			console.log(returnedObject); 		},function(result){    			console.log("Error"); 		});
#### DSAContent.getContentPathFromSFID (sfid, success, error)
Get the URI of a content file using its 18 character Salesforce.com Content ID. If content with the Salesforce ID is found in the DSA, then the Success callback will be executed.The Fail callback will be called when the Content cannot be found. Preconditions: SalesforceID represents a content file in the DSA repository.  Postconditions:  The ContentURI is passed as a parameter to the Success callback.  Example:	DSAContent.getContentURI(“00Pd0000000Hj3sEAC”, success,error);<a id="api-nav"></a> ### DSANavigationThe DSANavigation plugin provides navigation to internal DSA Categories and External-Browser URL. The Bundle creator can use these navigation methods to open a DSA Category from an HTML Bundle. This plugin also allows the navigation to an external web browser as well as a child browser window within the HTML5 Browser View. When navigating to URL in the Salesforce.com domain, the Browser creator can specify to attempt to use the current authentication/authorization context for a single-sign-on with the salesforce.com URL. #### DSANavigation.openURL(url, sso, externalBrowser, success,error);
Open the URL in a Child Browser View if ExternalBrowser is false or an External Browser Window if ExternalBrowser is true. If SSO is true and the URL is in the Salesforce.com domain attempt a single-sign-on using a refreshed OAuth2.0 Access Token. If the authentication is successful and the Browser is launched the SuccessFunc() will be called. Otherwise, the FailFunc will be called.Preconditions: Well formed URL.  Postconditions:  An External Browser window will be launched, if ExternalBrowser is true or a Child Browser View if it is false.  Example:	DSANavigationPlugin.openURL(“https://cs13.salesforce.com/a3dW00000008SJv”,true,true, success,error);                                            <a id="api-contact"></a> ### DSAContactThe DSAContact plugin provides read access to the set of Contact records downloaded from Salesforce.com. The plugin will provide the HTML5 bundle creator with an array of Contact Objects that contains the reduced set of Contact Objects fields that the DSA actually downloads from Salesforce.com. The Contact List JSON Object has the following structure:JSON Example:	{
	  "ContactList" : [
	    {
	      "id" : "00000euruhdfnf",
	      "OwnerId" : "000000jdeubenck",
	      "LastModifiedDate" : "15-12-2013",
	      "Name" : "Teodoro Alonso",
	      "FirstName" : "Teodoro",
	      "LastName" : "Alonso",
	      "Email" : "teodoro.alonso@salesforce.com",
	      "AccountId" : "000000hebddnbsa"
	    }
	  ]
	}



#### DSAContact.CheckedInContact(Success, Fail);
Returns the currently checked in contact in the first element of a ContactList in the SuccessFunc or calls the FailFunc if the Checkin function is not active.Preconditions: Checkin has been activated with a specific contact.  Postconditions:  SuccessFunc is called with a ContactList with only one element;  Example:	function SuccessFunc(contactList) {     	    Console.log (“Contact Name: “ + contactList[0].Name); 	} 	function FailFunc() {	     Console.log (“Checkin is not active“); 	}  	DSAContact.CheckedInContact(SuccessFunc, FailFunc);#### DSAContact.searchContact (searchString, success, error)
Returns a ContactList Array as an argument of the SuccessFunc of all the Contacts that contain at least a portion of the NameSearchString in the Name field. If none are found the FailFunc is called with the NameSearchString.Preconditions: There is at least one contact with a name that contains the NameSearchString.  Postconditions: The SuccessFunc will be called with the ContactList object that contains the result of the search.  Example:	function SuccessFunc(contactList) {		Console.log (“First Contact found: ” + contactList[0].name); 	}  	function FailFunc(nameSearchString) {		Console.log (“No contacts found using: ” + nameSearchString); 	} 	DSAContact.Search(“Alonso”, SuccessFunc, FailFunc);<a id="api-sync"></a> ### DSASynchronizedDataThe DSASynchronizedData plugin provides access to the synchronized data in the offline storage of the device. When using the Get and Search methods, care should be taken that no more than 9.75 Megabytes of data are returned in the Success function, this is an iOS limitation see [stringByEvaluatingJavaScriptFromString](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIWebView_Class/Reference/Reference.html) 9.75 Mb is arrived at by estimating the Cordova overhead.#### DSASynchronizedData.Get(SalesforceID, Success, Fail)Gets the objects specified in the SalesforceID array by their SFDC id.  The Success  function will be called with an array of the objects successfully retrieved from offline storage. The Fail function will be called if no objects are retrieved.Preconditions: The SalesforceID contains valid SFDC 18 character id for at least one object in the offline storage.  Postconditions: an array of the objects will be returned in the Success function.  Example:	var idlist = [“069W0000000JX3uIAG”]; 	function FailFunc() {	     Console.log (“No Objects found ”); 	};  	function SuccessFunc(ObjectArray) {	     Console.log (“Object Name found= ”,ObjectArray[0].name); 	}; 	DSASynchronizedData.Get( idlist, SuccessFunc, FailFunc); #### DSASynchronizedData.Search(ObjectType, SearchField, SearchString, Success, Fail)Search objects of type ObjectType with values in SearchField that contain SearchString and return them as the argument to the Success function. The Fail function will be called if no objects are retrieved.Preconditions: ObjectType is a synchronized data type; there is a least one object that contains contains SearchString in its name.  Postconditions: an array of the objects will be returned in the Success function.  Example:	function FailFunc() {	     Console.log (“No Objects found ”); 	};  	function SuccessFunc(ObjectArray) {	     Console.log (“Object Name found= ”,ObjectArray[0].name); 	}; 	DSASynchronizedData.Search( “Contact”, “LastName”, “Alonso”, SuccessFunc, FailFunc); // Get one object
	#### DSASynchronizedData.Upsert(ObjectType, ObjectArray, Success, Fail)“Upserts” a set of objects in ObjectArray of type ObjectArray into the offline storage. The objects must have the correct SFDC if they are being updated. If the objects are to be inserted the id will be “NEW”. The ObjectType must have read/write permissions in the DSA User Profile and the DSA will try to “Upsert” these objects to SFDC on the next synchronization. The Success function will be called with the number of objects upserted locally successfully. The Failure function will be called with an error string.Preconditions: The ObjectType contains valid object type; ObjectArray contains complete objects of ObjectType.  Postconditions: The Success function will be called with the number of objects upserted.  Example:
	var oarray = new Array();	oarray[0] = { “id” : “NEW”, “name” : “Teodoro Alonso”, “email” : “ta@gmail.com” } ;		function FailFunc(err) {	    Console.log (“No Objects upserted due to: ” + err);	};		function SuccessFunc(nUpserted) {	    Console.log (nUpserted + “objects upserted”);	};
			DSASynchronizedData.Put(“myContact”,oarray,SuccessFunc, FailFunc);//add a myContact for Teodoro Alonso