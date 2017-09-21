//
// DSANavigationPlugin.m
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import "DSANavigationPlugin.h"
#import "NSArray+JSONOperations.h"
#import "SBJson.h"
#import "SSZipArchive.h"
#import "DSA_AppDelegate.h"
#import "MMSF_CategoryMobileConfig__c.h"
#import "MMSF_Category__c.h"
#import "DSA_MediaDisplayViewController.h"
#import "DSA_BaseTabsViewController.h"
#import "DSA_TabBar.h"

@implementation DSANavigationPlugin

- (void) writeErrorForCommand:(CDVInvokedUrlCommand *) command {
    CDVPluginResult *result;
    NSString *javaScript;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error"];
    javaScript = [result toErrorCallbackString:command.callbackId];
    [self writeJavascript:javaScript];
}

- (void) openURL:(CDVInvokedUrlCommand*) command {
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    
    NSArray *echo = [command.arguments[0] componentsSeparatedByString:@","];
    
    if (echo.count != 3) {
        MMLog(@"%@", @"ERROR. Wrong number of arguments!");
        [self writeErrorForCommand:command];
        return;
    }
   
    // Refresh OAuth tokens
    if ([SA_ConnectionQueue sharedQueue].offline) {
        MMLog(@"%@", @"ERROR. Cannot open external web-page while offline");
        [self writeErrorForCommand:command];
        return;			//can't sync while offline
    }

	if (![MM_SyncManager sharedManager].oauthValidated) {
		[[MM_SyncManager sharedManager] validateOAuthTagged: NSStringFromSelector(_cmd) withCompletionBlock: nil];
    }
    CDVPluginResult* pluginResult = nil;
    NSString *javaScript = nil;
    NSString *urlArgument = echo[0];
    NSString *urlResultString;

    if ([urlArgument rangeOfString:@"salesforce.com"].length != 0 && [echo[1] isEqualToString:@"true"]) {
        // We need to do SSO login
        
        NSRange dotComRange = [urlArgument rangeOfString:@"salesforce.com"];
        
        NSString *relativePath = [urlArgument substringFromIndex:dotComRange.location + dotComRange.length];
        
        urlResultString = [NSString stringWithFormat:@"%@/secur/frontdoor.jsp?sid=%@&retURL=%@", [SFOAuthCoordinator currentInstanceURL], [SFOAuthCoordinator currentAccessToken], relativePath];
    } else {
        urlResultString = urlArgument;
    }
    
    NSURL *url = [NSURL URLWithString:[urlResultString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    if ([echo[2] isEqualToString:@"true"]) {
        // Open in Mobile Safari window
        if (![[UIApplication sharedApplication] openURL:url]) {
            MMLog(@"URL %@ was not opened", urlResultString);
            [self writeErrorForCommand:command];
            return;
        } else {
            MMLog(@"URL %@ was opened", urlResultString);
        }
    } else {
        // Open in Media Viewer
        DSA_MediaDisplayViewController* vc = [DSA_MediaDisplayViewController controller];
        vc.sendDocumentTrackerNotifications = YES;
        
        vc.url = url;
        vc.mediaDisplayViewControllerDelegate = (NSObject<DSA_MediaDisplayViewControllerDelegate>*)  self;
        
        [self.viewController presentViewController:vc animated:YES completion:nil];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Success"];
    
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
//    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread: @selector(writeJavascript:) withObject: javaScript waitUntilDone: NO];
//    }
//}
//	} else {
//        MMLog(@"ERROR. Cannot refresh new OAuth token");
//        [self writeErrorForCommand:command];
//        return;
//    }
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

- (MMSF_Category__c *) getCategoryInternal:(NSArray *) categoryNamesArray {
	NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadContentContext;
    NSMutableArray *activeCategories = [NSMutableArray arrayWithArray:[MMSF_Category__c allActiveCategoriesInContext: moc]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Name = [cd] %@", categoryNamesArray.lastObject];
    activeCategories = [NSMutableArray arrayWithArray:[activeCategories filteredArrayUsingPredicate:predicate]];
    
    for (MMSF_Category__c *category in [NSArray arrayWithArray:activeCategories]) {
        if (categoryNamesArray.count > 1 && ![self isCategory:category matchHierarchyOrder:categoryNamesArray startAt:categoryNamesArray.count - 1])
            [activeCategories removeObject:category];
    }

    if (activeCategories.count == 0) {
        return nil;
    }
    return activeCategories[0];
}

- (NSArray *) getCategoryConfigFromCategory: (MMSF_Category__c *) category listOfCategoryConfigs:(NSArray *) allConfigs {
    
    NSMutableArray *foundCategory = [NSMutableArray arrayWithCapacity:allConfigs.count];
    
    for (MMSF_CategoryMobileConfig__c *catConfig in allConfigs) {
        if ([catConfig.CategoryId__c.Id isEqualToString:category.Id]) {
            [foundCategory addObject:catConfig];
            break;
        }
    }
    
    if (category.Parent_Category__c != nil) {
        NSArray *catConfigsArray = [self getCategoryConfigFromCategory:category.Parent_Category__c listOfCategoryConfigs:allConfigs];
        if (catConfigsArray.count != 0) {
            [foundCategory addObjectsFromArray:catConfigsArray];
        }
    }
    return foundCategory;
}

- (void) openCategory:(CDVInvokedUrlCommand*) command {
  //  NSString *zeroArgumentClassName = [[command.arguments[0] class] description];
    
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
    
    // Create Plugin Result
    MMSF_Category__c *category = [self getCategoryInternal:echo];
    if (category == nil) {
        MMLog(@"No category with name = %@ has been found", echo);
        [self writeErrorForCommand:command];
        return;
    }

	NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadContentContext;
    NSArray *allConfigs = [MMSF_CategoryMobileConfig__c allActiveCategoryMobileConfigurationsInContext: moc];
    NSArray *catConfigsArray = [self getCategoryConfigFromCategory:category listOfCategoryConfigs:allConfigs];

    if (catConfigsArray.count == 0) {
        MMLog(@"%@", @"No such categories found");
        [self writeErrorForCommand:command];
        return;
    }
    
    // Predicate to check whether the file type for a content in a category is html bundle file
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"FileType = %@", @"ZIP"];
    NSArray *htmlBundleArray = [category contentsAndSubcategoriesMatchingPredicate:predicate];
    //[moc allObjectsOfType:@"ContentVersion" matchingPredicate:predicate];
    
    // Opening html bundle files if the count is exactly 1  and no subcategories are present
    if(htmlBundleArray.count == 1 && [[self sortedSubcategories] count] == 0){
        MMSF_ContentVersion	*item = [htmlBundleArray objectAtIndex:0];
        DSA_MediaDisplayViewController* viewController = [DSA_MediaDisplayViewController controller];
        viewController.sendDocumentTrackerNotifications = YES;
        viewController.item = item;
        viewController.mediaDisplayViewControllerDelegate = (NSObject<DSA_MediaDisplayViewControllerDelegate> *) self;
        [self.viewController presentViewController:viewController animated:YES completion:nil];
    } else {
        UIViewController *parentController = (UIViewController *)self.webView.delegate;
        [parentController performSelector: @selector(donePressed) withObject:nil];

        DSA_TabBar *baseTabController = g_appDelegate.baseViewController.tabBar;
        g_appDelegate.baseViewController.selectedIndex = 0;
        [baseTabController performSelector: @selector(setSelectedTabIndex:) withObject: nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_VisualBrowserCategorySelected object:catConfigsArray];
        });
    }
}

/* Fetch the array of SubCategories */
- (NSArray *) sortedSubcategories {
	NSManagedObjectContext		*moc = [MM_ContextManager sharedManager].threadContentContext;

    if(_sortedSubCategories == nil)
    {
        /* Hide the subcategories which are selected to be hidden using a predicate */
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"BG_DSA__Parent_Category__c = %@",self];
        NSArray	*subs = [moc allObjectsOfType:@"BG_DSA__Category__c" matchingPredicate:pred];
        NSMutableArray *array = [NSMutableArray array];
        for(MMSF_Category__c* record in subs)
        {
            if(![record isEmpty])
                [array addObject:record];
        }
        _sortedSubCategories = array;
    }
	return _sortedSubCategories;
}

- (void) donePressed:(DSA_MediaDisplayViewController*) controller {
    controller.mediaDisplayViewControllerDelegate = nil;
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end

#endif
