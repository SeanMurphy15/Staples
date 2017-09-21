//
// DSAContactPlugin.m
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import "DSAContactPlugin.h"
#import "NSArray+JSONOperations.h"
#import "MM_Headers.h"
#import "SBJson.h"
#import "SSZipArchive.h"
#import "DSA_AppDelegate.h"
#import "MM_LoginViewController.h"
#import "MMSF_Category__c.h"
#import "DSA_MediaDisplayViewController.h"
#import "MM_SyncManager.h"
#import "MMSF_Contact.h"

@implementation DSAContactPlugin

//-(void)print:(CDVInvokedUrlCommand*)command {
//    // The first argument in the arguments parameter is the callbackID.
//    // We use this to send data back to the successCallback or failureCallback
//    // through PluginResult
//    CDVPluginResult* pluginResult = nil;
//    NSString* javaScript = nil;
//
//    NSArray* echo = [command.arguments objectAtIndex:0];
//
//    if (echo != nil && [echo count] > 0) {
//        // Create Plugin Result
//        NSString *stringObtainedFromJavascript = [command.arguments objectAtIndex:0];
//        NSMutableString *stringToReturn = [NSMutableString stringWithString: @"StringReceived:"];
//        [stringToReturn appendString: stringObtainedFromJavascript];
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
//                                         messageAsString: [stringToReturn stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//        
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
//        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
//    } else {
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
//        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
//    }
//
//    [self writeJavascript:javaScript];
//}

- (void) writeErrorForCommand:(CDVInvokedUrlCommand *) command {
    CDVPluginResult *result;
    NSString *javaScript;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error"];
    javaScript = [result toErrorCallbackString:command.callbackId];
    [self writeJavascript:javaScript];
}

- (void) checkedInContact:(CDVInvokedUrlCommand*) command {
    CDVPluginResult* pluginResult;
    NSString *javaScript;

//    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
//        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
//        [self writeErrorForCommand:command];
//        return;
//    }

    NSMutableArray *resultsArray = nil;
    if (g_appDelegate.currentTrackingEntity == nil)  {
        MMLog(@"%@", @"ERROR. No contact is tracking right now");
        [self writeErrorForCommand:command];
        return;
    } else {
        MMSF_Contact *trackingContact = [g_appDelegate trackingContactInContext:nil];
        resultsArray = [self createFormattedArrayFromContacts:@[trackingContact]];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", [resultsArray JSONRepresentation]]];
    
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];

    [self performSelectorOnMainThread: @selector(writeJavascript:) withObject: javaScript waitUntilDone: NO];
}
- (NSMutableArray *)createFormattedArrayFromContacts:(NSArray *)contactsArray {
    // Create Plugin Result
    NSMutableArray *resultsArray = [NSMutableArray arrayWithCapacity:contactsArray.count];
    for (MMSF_Contact *contact in contactsArray) {
        NSString *nameString = contact.Name;
        if (!nameString) nameString = @"";
        
        NSString *contactId = contact.Id;
        if (!contactId) contactId = @"";
        
        NSString *ownerId = contact.OwnerId.Id;
        if (!ownerId) ownerId = @"";
        
        NSDate *lastModifiedDate = contact.LastModifiedDate;
        if (!lastModifiedDate) lastModifiedDate = [NSDate distantPast];
        
        NSString *firstName = contact.FirstName;
        if (!firstName) firstName = @"";
        
        NSString *lastName = contact.LastName;
        if (!lastName) lastName = @"";
        
        NSString *email = contact.Email;
        if (!email) email = @"";
        
        NSDictionary *categoryDictionary = @{@"Name":nameString, @"id":contactId, @"OwnerId":ownerId, @"LastModifiedDate":lastModifiedDate, @"FirstName":firstName,@"LastName":lastName,@"Email":email/*,@"AccountId":contact.*/};
        [resultsArray addObject:categoryDictionary];
    }
    return resultsArray;
}

- (void) searchContact:(CDVInvokedUrlCommand*) command {			//FIXME should pass in a context
    CDVPluginResult* pluginResult;
    NSString *javaScript;
	MM_ManagedObjectContext			*ctx = [MM_ContextManager sharedManager].threadContentContext;
    
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    
    // Get the string that javascript sent us
    NSString *contactName = command.arguments[0];
    
    NSArray *contactsArray = [ctx allObjectsOfType:@"Contact"
                         matchingPredicate:[NSPredicate predicateWithFormat:
                                            [NSString stringWithFormat:@"Name contains [cd]'%@'", contactName]]
                                  sortedBy:nil];
    
    // Create Plugin Result
    
    if (contactsArray.count != 0) {
        NSMutableArray *resultsArray;
        resultsArray = [self createFormattedArrayFromContacts:contactsArray];
        
        if (resultsArray.count != 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", [resultsArray JSONRepresentation]]];
            
            javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
            [self writeJavascript:javaScript];
        } else {
            [self writeErrorForCommand:command];
        }
    } else {
        [self writeErrorForCommand:command];
        return;
    }
}

- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    controller.mediaDisplayViewControllerDelegate = nil;
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
