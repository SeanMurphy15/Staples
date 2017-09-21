//
// DSAContentPlugin.m
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import "DSAContentPlugin.h"
#import "NSArray+JSONOperations.h"
#import "MM_Headers.h"
#import "SBJson.h"
#import "SSZipArchive.h"
#import "DSA_AppDelegate.h"
#import "MM_LoginViewController.h"
#import "MMSF_Category__c.h"
#import "DSA_MediaDisplayViewController.h"

@implementation DSAContentPlugin

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

- (BOOL) isCategory:(MMSF_Category__c *) category matchHierarchyOrder:(NSArray *) categoryNamesArray startAt:(NSInteger) startingIndex {
    BOOL answer = YES;
    
    if ([category.Parent_Category__c.Name isEqualToName:categoryNamesArray[startingIndex - 1]]) {
        if (startingIndex == 1) {
            return answer;
        }
        [self isCategory:category.Parent_Category__c matchHierarchyOrder:categoryNamesArray startAt:startingIndex - 1];
    } else {
        answer = NO;
    }
    
    return answer;
}

- (NSArray *) getCategoryContentArrayInternal:(NSArray *) categoryNamesArray {
    NSMutableArray *resultsArray = nil;
    NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].threadContentContext;
	
    NSMutableArray *activeCategories = [NSMutableArray arrayWithArray:[MMSF_Category__c allActiveCategoriesInContext: moc]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Name = [cd] %@", categoryNamesArray.lastObject];
    activeCategories = [NSMutableArray arrayWithArray:[activeCategories filteredArrayUsingPredicate:predicate]];
    
    for (MMSF_Category__c *category in activeCategories.copy) {
        if (categoryNamesArray.count > 1 && ![self isCategory:category matchHierarchyOrder:categoryNamesArray startAt:categoryNamesArray.count - 1])
            [activeCategories removeObject:category];
    }
    
    if (activeCategories != nil && [activeCategories count] > 0) {
        // Create Plugin Result
        resultsArray = [NSMutableArray arrayWithCapacity:activeCategories.count];
        
        for (MMSF_Category__c *category in activeCategories.copy) {
            NSArray *sortedSubcategories = [category sortedSubcategories];
            NSArray *sortedContent = [category sortedContents];
            NSMutableArray *subcategoryNames = [NSMutableArray arrayWithCapacity:sortedSubcategories.count];
            NSMutableArray *contentNames = [NSMutableArray arrayWithCapacity:sortedContent.count];
            
            for (MMSF_Category__c *subcategory in sortedSubcategories.copy) {
                [subcategoryNames addObject:@{@"Name":[subcategory valueForKey:@"Name"]}];
            }
            
            for (MMSF_ContentVersion *content in sortedContent) {
                [contentNames addObject:@{@"SFDCID": content.documentID, @"URI": [content fullPath], @"Type":[content mimeType],@"Name":[content valueForKey:@"Title"]}];
            }
            NSDictionary *categoryDictionary = @{@"Name":category.Name, @"sub-categories":subcategoryNames, @"content":contentNames};
            [resultsArray addObject:categoryDictionary];
        }
    }
    return resultsArray;
}

- (void) getCategoryContentArray:(CDVInvokedUrlCommand*) command {
    CDVPluginResult* pluginResult = nil;
    NSString *javaScript = nil;
    
//    NSArray *echo = [command.arguments[0] componentsSeparatedByString:@","];
    
//    NSString *zeroArgumentClassName = [[command.arguments[0] class] description];
    
//    if (![zeroArgumentClassName isEqualToString:@"CDVJKArray"]) {
//        MMLog(@"%@", @"ERROR. Category names array argument doesn't contain array!");
//        [self writeErrorForCommand:command];
//        return;
//    }
    NSArray *echo = command.arguments[0];
    
    if (command.arguments.count > 1) {
        // Arguments are array elements
        echo = [NSArray arrayWithArray:command.arguments];
    } else {
        if (echo.count == 1) {
            // All arguments in one line
            if ([echo[0] rangeOfString:@"\",\""].length != 0) {
                NSString *zeroArgumentString = [echo[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                echo = [zeroArgumentString componentsSeparatedByString:@","];
                
            } else if ([echo[0] rangeOfString:@"','"].length != 0) {
                NSString *zeroArgumentString = [echo[0] stringByReplacingOccurrencesOfString:@"'" withString:@""];
                echo = [zeroArgumentString componentsSeparatedByString:@","];
            }
            
            echo = @[[echo[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
            echo = @[[echo[0] stringByReplacingOccurrencesOfString:@"'" withString:@""]];
            echo = [echo[0] componentsSeparatedByString:@","];
        }
    }
    
    NSArray *resultsArray = [self getCategoryContentArrayInternal:echo];
    
    if (resultsArray.count != 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", [resultsArray JSONRepresentation]]];
        
        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
        [self writeJavascript:javaScript];
    } else {
        [self writeErrorForCommand:command];
    }
}

- (void) getCategoryContent:(CDVInvokedUrlCommand *) command {
    CDVPluginResult* pluginResult = nil;
    NSString *javaScript = nil;
    
    NSString *zeroArgumentClassName = [[command.arguments[0] class] description];
    
    if (![zeroArgumentClassName isEqualToString:@"CDVJKArray"]) {
        MMLog(@"%@", @"ERROR. Category names array argument doesn't contain array!");
        [self writeErrorForCommand:command];
        return;
    }
    NSArray *echo = command.arguments[0];
    if ([echo[0] rangeOfString:@"\",\""].length != 0) {
        NSString *zeroArgumentString = [echo[0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        echo = [zeroArgumentString componentsSeparatedByString:@","];
        
    } else if ([echo[0] rangeOfString:@"','"].length != 0) {
        NSString *zeroArgumentString = [echo[0] stringByReplacingOccurrencesOfString:@"'" withString:@""];
        echo = [zeroArgumentString componentsSeparatedByString:@","];
        
    }
    
    NSArray *resultsArray = [self getCategoryContentArrayInternal:echo];
    
    if ([resultsArray count] != 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%@", [resultsArray[0] JSONRepresentation]]];
        
        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
        [self writeJavascript:javaScript];
    }
        
    [self writeErrorForCommand:command];
}

- (void) displayContent:(CDVInvokedUrlCommand *) command {
    MMLog(@"%@", @"displayContent");
    CDVPluginResult* pluginResult;
    NSString *javaScript;
    
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    
    // Get the string that javascript sent us
    NSString *contentPath = command.arguments[0];
    
    if (contentPath.length == 0) {
        [self writeErrorForCommand:command];
        return;
    }
    
    NSRange idRangeBegin = [contentPath rangeOfString:@"["];
    NSRange idRangeEnd = [contentPath rangeOfString:@"]"];
    
    idRangeBegin.location += 1;
    idRangeBegin.length = idRangeEnd.location - idRangeBegin.location;
    if ((idRangeBegin.location - 1) == NSNotFound) {
        [self writeErrorForCommand:command];
        return;
    }

    contentPath = [contentPath substringWithRange:idRangeBegin];

    if (contentPath.length == 0) {
        [self writeErrorForCommand:command];
        return;
    }

    if (![self displayContentFromSFIDInternal:contentPath]) {
        [self writeErrorForCommand:command];
        return;
    }
        
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsString: @"Success"];
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    [self writeJavascript:javaScript];
}

- (void) displayContentFromSFID:(CDVInvokedUrlCommand *) command {
    CDVPluginResult* pluginResult;
    NSString *javaScript;
    
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    
    // Get the string that javascript sent us
    NSString *contentPath = command.arguments[0];
    
    if (![self displayContentFromSFIDInternal:contentPath]) {
        [self writeErrorForCommand:command];
        return;
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                     messageAsString: @"Success"];
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    [self writeJavascript:javaScript];
}

- (BOOL) displayContentFromSFIDInternal:(NSString *) sfid {		//FIXME should pass in a context
	MM_ManagedObjectContext			*ctx = [MM_ContextManager sharedManager].threadContentContext;
    NSArray *array = [ctx allObjectsOfType:@"ContentVersion"
                         matchingPredicate:[NSPredicate predicateWithFormat:
                                            [NSString stringWithFormat:@"Id = '%@'", sfid]]
                                  sortedBy:nil];
    
    // Create Plugin Result
    
    if (array.count != 0) {
        MMSF_ContentVersion *item = array[0];
        
        DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controller];
        vc.sendDocumentTrackerNotifications = YES;
        
        vc.item = item;
        vc.mediaDisplayViewControllerDelegate = (NSObject<DSA_MediaDisplayViewControllerDelegate>*)  self;
        
        [self.viewController presentViewController:vc animated:YES completion:nil];
        
    } else {
        return NO;
    }
    return YES;
}

- (void) getContentPathFromSFID:(CDVInvokedUrlCommand *) command {
    MMLog(@"%@", @"getContentPathFromSFID");
//    CDVPluginResult* pluginResult = nil;
    NSString *javaScript, *foundPath = nil;
    
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    
    // Get the string that javascript sent us
    NSString *contentId = command.arguments[0];
    
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].threadContentContext;
    MMSF_ContentVersion *contentVersionObject = [MMSF_ContentVersion versionMatchingDocumentID: contentId inContext: moc];
    if (contentVersionObject == nil) return;
	
    // Create Plugin Result
    
	if (contentVersionObject.isZipFile) {
		NSString *fullPathString = contentVersionObject.fullPath;
		NSString *htmlBundleDataPath = nil;
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentPath = [paths objectAtIndex:0];
		NSError				*e = nil;
		NSString *directoryPath = [documentPath stringByAppendingPathComponent:@"Test"];
		NSString * itemFileName = [NSString stringWithFormat:@"%@.htmlbundle", contentVersionObject.Title];
		foundPath = [NSString stringWithFormat:@"%@/%@", directoryPath, itemFileName];
		
		BOOL isDir;
		if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:&e];
		}
				 
		if (![[NSFileManager defaultManager] fileExistsAtPath:foundPath]) {
			[SSZipArchive unzipFileAtPath:fullPathString toDestination:foundPath];
		} else {
			//MMLog(@"found html5 bundle... already unzipped");
		}
		
		htmlBundleDataPath = foundPath;
		
		//            htmlBundleDataPath = [htmlBundleDataPath stringByAppendingPathComponent:@"index.html"];
		htmlBundleDataPath = [htmlBundleDataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"index.html"]];
		foundPath = [NSString stringWithFormat:@"'%@'", [htmlBundleDataPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	
	else if([contentVersionObject ContentUrl]) {
		NSURL *url = [NSURL URLWithString:[contentVersionObject.ContentUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        foundPath = url.absoluteString;
	}

	else if ([contentVersionObject fullPath ].length)
	{
		//this may seem a little weird but here is why it is here:
		//
		//Initially the stringByReplacingPercentEscapesUsingEncoding was added to handle a file name that had a umlat and all was happy
		//but one day a file name  with a % in it came by, it confused the replace and everybody was sad
		//But along came stringByAddingPercentEscapesUsingEncoding and it now worked for both cases and everybody lived happily ever after.
		//
		NSString* s = [contentVersionObject.fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		foundPath = [[NSURL fileURLWithPath: [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] absoluteString];
	}

	if (foundPath.length == 0) {
		[self writeErrorForCommand:command];
		return;
	}
	CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
													  messageAsString: foundPath];
	javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
	[self writeJavascript:javaScript];
}

- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
