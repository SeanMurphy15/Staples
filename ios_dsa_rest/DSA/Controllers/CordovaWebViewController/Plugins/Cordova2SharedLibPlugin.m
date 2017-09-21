//
// Cordova2SharedLibPlugin.m
//
// Copyright (c) ModelMetrics 2012
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import "Cordova2SharedLibPlugin.h"
#import "NSArray+JSONOperations.h"
#import "MM_Headers.h"
#import "SBJson.h"
#import "SSZipArchive.h"
#import "DSA_AppDelegate.h"
#import "MM_LoginViewController.h"

@implementation Cordova2SharedLibPlugin

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

- (void) getRecordsUsingQuery:(CDVInvokedUrlCommand *) command {
    
    CDVPluginResult *pluginResult = nil;
    NSString *javaScript = nil;
    
    NSArray *echoArray = command.arguments[0];
    
    if (echoArray != nil && [echoArray count] > 0) {
    
        NSManagedObjectContext *ctx = [MM_ContextManager sharedManager].contentContextForWriting;
        
        // Zero parameter should be a record name. Be careful when passing records name here, record's API name could be different! Double check the API name.
        NSArray *array = [ctx allObjectsOfType:echoArray[0]
                             matchingPredicate:[NSPredicate predicateWithFormat:
                                                [NSString stringWithFormat:@"%@", echoArray[1]]]
                          //@"Name beginswith [C] 'A'"]
                                      sortedBy:nil];
        
        // Create Plugin Result
        
        NSString *stringToReturn = [array JSONValueFromArrayOfMMSF_Objects];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsString: stringToReturn];//[stringToReturn
                
        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
    }
    
    [self writeJavascript:javaScript];
}

- (void) syncButtonPressed:(CDVInvokedUrlCommand *) command {
    LOG(@"Sync button pressed");
    [g_appDelegate refreshUser: nil];
}

- (void) logoutButtonPressed:(CDVInvokedUrlCommand *) command {

    
    LOG(@"Logout button pressed");
}

- (void) getOAuthSessionID:(CDVInvokedUrlCommand *) command {
    CDVPluginResult *pluginResult = nil;
    NSString *javaScript = nil;
    
    NSMutableString *stringToReturn = [NSMutableString stringWithString: [SFOAuthCoordinator currentAccessToken]];
    if(stringToReturn != nil|| [stringToReturn length]!=0){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: [NSString stringWithFormat:@"'%@'", stringToReturn]];
        ////                                         messageAsString: [stringToReturn stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
    }
    
    [self writeJavascript:javaScript];
}


- (void) getHTML5BundleFilePath:(CDVInvokedUrlCommand *) command {
    CDVPluginResult *pluginResult = nil;
    NSString *javaScript = nil;
    
    NSArray *echoArray = command.arguments[0];
    
    if (echoArray != nil && [echoArray count] > 0) {
        // Get the string that javascript sent us
        NSString *stringObtainedFromJavascript = echoArray [0];

		MM_ManagedObjectContext			*ctx = [MM_ContextManager sharedManager].threadContentContext;
        NSArray *array = [ctx allObjectsOfType:@"ContentVersion"
//                             matchingPredicate:[NSPredicate predicateWithFormat:@"Id = %@", @"001U0000002MBzyIAG"]//@"title == %@", stringObtainedFromJavascript]
                             matchingPredicate:[NSPredicate predicateWithFormat:
                                                [NSString stringWithFormat:@"Title = '%@'", stringObtainedFromJavascript]]
//                                                [NSString stringWithFormat:@"Title == Manual"]]
                          //@"Name beginswith [C] 'A'"]
                                      sortedBy:nil];
        
        // Create Plugin Result

        if (array.count != 0) {
            MMSF_ContentVersion *contentVersionObject = array[0];
            
            NSString *fullPathString = contentVersionObject.fullPath;
            NSString *htmlBundleDataPath = nil;
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentPath = [paths objectAtIndex:0];
            NSError				*e = nil;
            NSString *directoryPath = [documentPath stringByAppendingPathComponent:@"Test"];
            NSString * itemFileName = [NSString stringWithFormat:@"%@.htmlbundle", stringObtainedFromJavascript];
            NSString * newPath = [NSString stringWithFormat:@"%@/%@", directoryPath, itemFileName];
            
            BOOL isDir;
            if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:&e];
            }
                       
            if (![[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
                [SSZipArchive unzipFileAtPath:fullPathString toDestination:newPath];
            } else {
                //LOG(@"found html5 bundle... already unzipped");
            }
            
            htmlBundleDataPath = newPath;

//            htmlBundleDataPath = [htmlBundleDataPath stringByAppendingPathComponent:@"index.html"];
            htmlBundleDataPath = [htmlBundleDataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"index.html"]];
            newPath = [NSString stringWithFormat:@"'%@'", [htmlBundleDataPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                              messageAsString: newPath];
            javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
    }
    
    [self writeJavascript:javaScript];
}

- (void) createRecord:(CDVInvokedUrlCommand *) command {
    CDVPluginResult* pluginResult = nil;
    NSString *javaScript = nil;
    
    NSArray *echoArray = command.arguments[0];
    
    if (echoArray != nil && [echoArray count] > 0) {
        LOG(@"createRecord");
        NSManagedObjectContext *ctx = [MM_ContextManager sharedManager].contentContextForWriting;
        
        // Zero parameter should be a record name. Be careful when passing records name here, record's API name could be different! Double check the API name.
        NSString *recordName = echoArray[0];
        
        if (recordName.length == 0) {
            LOG(@"Please fill in record name");
            return;
        }
        
        if (![[MM_ContextManager sharedManager] objectExistsInContentModel:recordName]) {
            LOG(@"Record with name %@ doesn't exists in current content model, consider checking sync_objects.plist", recordName);
            return;
        }
        
        MMSF_Object *survey = [ctx insertNewEntityWithName:recordName];
        
        for (int i = 1; i < echoArray.count; i++) {
            NSArray *fieldArray = echoArray[i];
            NSString *valueString = @"";
            for (int j = 0; j < fieldArray.count - 1; j++) {
                if (j > 0) {
                    valueString = [valueString stringByAppendingString:@";"];
                }

                valueString = [valueString stringByAppendingString:fieldArray[j]];
            }
            [survey setStringValue: valueString forKey: echoArray[i][fieldArray.count - 1]];
        }
        
        if (g_appDelegate.currentTrackingContact) {
            NSArray *array = [ctx allObjectsOfType:@"Contact"
                                 matchingPredicate:[NSPredicate predicateWithFormat:
                                                    [NSString stringWithFormat:@"Id == '%@'", g_appDelegate.currentTrackingContact.Id]]
                                          sortedBy:nil];

            if (array.count != 0) {
                [survey setValue:array[0] forKey:@"Contact__c"];
            } else {
                LOG(@"Error, cannot find contact with Id = %@", g_appDelegate.currentTrackingContact.Id);
            }
        }
        [survey finishEditingSavingChanges:YES];
        
        [MM_SFChange pushPendingChangesWithCompletionBlock:nil];
        
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
    }
    
    [self writeJavascript:javaScript];
}

@end

#endif
