#DSAv3 -- REST/Touch Platform

Model Metrics Digital Sales Aid. Built on Touch Platform / Mobile SDKs using RESTFramework synchronization engine.

* [Internal Implementation Guide](https://na1.salesforce.com/06930000002mS4s)
* [Customer Implementation Guide](https://na1.salesforce.com/06930000002qB7p)
* [DSA Image Asset Specifications](https://na1.salesforce.com/06930000002lsbh)

**READ DEPENDENCIES SECTION BELOW TRYING TO BUILD DSA**

##Proprietary Material

**Note: Everything contained in this repository is the private property of Salesforce.com.** Nothing contained within this repository should be shared externally to the company, except as a deliverable in a paid Salesforce Services engagement.

Do not email code or post on Chatter. Access is to be granted via Source Control only.

In the event this code is to be delivered to a Salesforce Services client, the [Code Delivery Checklist](https://org62.my.salesforce.com/06930000003GQNY) must be followed.

##Current Version

* 3.2

##Change Log

* 3.2 -- "Hoa Kula" version, includes n-level navigation
* 3.1 -- Major Trust Release (bugfixes only)
* 3.0 -- Initial RESTframework Version, requires use of RestFramework_For_DSA branch.

##Dependencies

Version 1.4 of the [Salesforce Mobile SDK for iOS](https://github.com/forcedotcom/SalesforceMobileSDK-iOS)

[MM RESTFramework](https://github.com/ModelMetrics/RESTframework) (See build notes below)

**NOTE:** You will need to configure your RESTFramework location in XCode Preferences for the DSA project to be able to find it. To do that:

1. Navigate to XCode Preferences (XCode Menu=>Preferences)
2. Choose the Locations Tab
3. Choose Source Trees
4. Click the + button at the bottom
5. Add a new Setting named MMREST. Leave "Display Name" blank, and specify the path to RESTframework under Path.
6. Add a new Setting named IDNAME. This is used to parameterize the bundle identifier for Continuous Integration with Jenkins.

![image](http://mm-factory.s3.amazonaws.com/dsa/documentation/Screenshot_2_21_13_11_05_AM.png)


##Client Projects (READ THIS FIRST)

When starting a client DSA project that will involve customizing the DSA, follow these steps:

1. Using the **Master Branch**, Create a new **Remote Branch** with the name of the client and the name of the project.
2. Use that branch for your project.

##Mainline Branches

Please do not commit any changes directly to **master** branch. Follow this procedure:

* **master** : main branch -- use this for projects
* **dev** : feature development occurs here
* **hotfix** : bugfixes occur here if they need to be merged into master before the next planned feature update.

Additionally, topic branches can be created at will, and merged into **dev** or **hotfix** prior to being merged into **master**.

###Merging to Master Branch

Do These Things when merging from **dev** or **hotfix** branches to **master**:

1. All new non-client specific feature development is done in "dev" branch.
2. All emergency bugfixing is done in "hotfix" branch. This would be used for bugs that must be fixed in Master before the next planned merge from "Dev".
3. Any merge to master from either branch is accompanied by an update to Readme.md with a description of changes in the Changelog and a version # update.
5. Bugfix merges increment the version number by 0.0.1 (so 1.0.0 would change to 1.0.1)
6. Feature dev merges increment the version number by 0.1.0 (1.0.1 would change to 1.1.0).
7. Post any updates to Master branch to the **Chatter Group** in Org62 named "MM RESTFramework - iOS Sync Engine".
8. **Tag** the version with a Git Tag.

##Namespaces and Prefixes
When using the managed DSA package, custom objects and fields on SFDC are prefixed with a "ModelM__" label*. When using the unmanaged DSA package, however, this prefix is missing. In addition, it is conceivable that a version of the DSA package could be deployed with a custom prefix label. In order to maximize the flexibility and reusability of the code, the DSA has added namespace support.

By # defining a **NAMESPACE** constant in the project's pch file, a namespace prefix can be assigned. The default DSA configuration uses "ModelM_" as the pre-defined namespace. Note that there is only ONE underscore ( _ ) after the "ModelM". If a namespace is defined, an additional underscore will be appended, so always be sure to only add one less than the required number. 

To run the DSA in an unmanaged org, simply comment out the #defne for the NAMESPACE. To use a different prefix, replace the "ModelM_" string with your own.

* there are a very few exceptions to this rule: ContentVersion.ModelM_Category__c is one of them; note that it has only one underscore after the prefix, not two. 

##Build Notes

Please note that you have to download the code and as the source tree in XCODE with the name "MMREST" and also specify the path.

###Targets

* **DSA_Custom**: For use on DSA client projects.
* **DSA_Appstore**: For building for the Apple App Store
* **DSAREST Library**: Builds RESTframework

##Defects

Defects are tracked in Rally in the DSA Version 3 Project.

##PhoneGap/Cordova

###Building with PhoneGap/Cordova

To be able sucessfully use PhoneGap/Cordova in DSA you need to walk through next steps:
 
1. Download latest version of PhoneGap library here: http://phonegap.com/download.
2. Unpack it anywhere you want and drag CordovaLib.xcodeproj file just right into left pane of this project. After this you will see that CordovaLib.xcodeproj is
now should be added as a sub-project. If it's not opens, close all other Xcode project where CordovaLib.xcodeproj is used and reopen current project.
3. Add CordovaLib as ios_dsa target dependency in project settings -> Build Phases.
4. Add libCordova.a into "Link Binary With Libraries" list.
5. Update the reference:
     5.1. Launch Terminal.app.
     5.2. Go to the location where you installed Cordova (see Step 1), in the bin sub-folder.
     5.3. Run the script below where the first parameter is the path to your project's .xcodeproj file:
     update_cordova_subproject path/to/your/project/xcodeproj.
6. Set BUILD_WITH_CORDOVA to 1 and try to build.
7. If you did everything right but you see Cordova related errors, write email to abilous@modelmetris.com with a list of errors.


###Preloading Username and Password for Development Only

**ALWAYS UNDO THIS BEFORE SENDING CODE TO A CLIENT**

A default username and password can be entered into the Scheme Environment Variables Settings using PRELOADED_USERNAME and PRELOADED_PASSWORD:

**ALWAYS UNDO THIS BEFORE SENDING CODE TO A CLIENT**

![image](http://mm-factory.s3.amazonaws.com/dsa/documentation/PreloadUserPass-3.png)

**ALWAYS UNDO THIS BEFORE SENDING CODE TO A CLIENT**

###Description of available methods in Cordova2SharedLibPlugin.js


#####window.getRecordsUsingQuery(recordName, queryValue, function(result) {});

Used to get JSON array of records from internal database. 

######Parameters

*recordName*

Can be any standard or custom record which previously existed in sync_objects.plist file. For example: Contacts, Accounts, etc.

*queryValue*
	
String created using SQL syntax. 
Example: Name beginswith [C] 'A'. This means that the query will look for all records of previously specified type where field 'Name' begins with letter 'A'.

######Return Value
JSON array of dictionaries. In case search returned no results, the array will be empty.



#####window.getOAuthSessionID ([dummyValue], function(result) {});
Returns the OAuth session ID.

######Return Value
Returns the OAuth session ID if user is logged in. Can be used to send requests to SFDC without involving native code.


#####window.createRecord(['recordName', [fieldValue, 'fieldName'], ...], function(result) {});

Used to create object of record of existing type, save it to internal database and synchronize with SFDC.

######Parameters

*recordName*

Can be any standard or custom record which previously existed in
sync_objects.plist file. For example: Contacts, Accounts, etc.

*[fieldValue, 'fieldName']*

JSON array of values and key, last element must be a key always.
Number of values in one array is not limited. Number of fields is limited to number of fields inside particular record.


#####window.syncButtonPressed

Used to initiate a synchronization process if user is logged in.
