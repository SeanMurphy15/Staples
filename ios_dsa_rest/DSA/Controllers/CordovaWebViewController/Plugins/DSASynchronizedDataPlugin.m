//
// DSASynchronizedDataPlugin.m
//
// Copyright (c) ModelMetrics 2013
// Created by Alexey Bilous
//

#if BUILD_WITH_CORDOVA

#import "DSASynchronizedDataPlugin.h"
#import "NSArray+JSONOperations.h"
#import "SBJson.h"

@implementation DSASynchronizedDataPlugin

- (void) writeErrorForCommand:(CDVInvokedUrlCommand *) command {
    CDVPluginResult *result;
    NSString *javaScript;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error"];
    javaScript = [result toErrorCallbackString:command.callbackId];
    [self writeJavascript:javaScript];
}

- (void) get:(CDVInvokedUrlCommand*) command {
    if (![command.arguments[0] isKindOfClass:[NSArray class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSArray class]);
        [self writeErrorForCommand:command];
        return;
    }
    
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
   
    NSManagedObjectContext *ctx = [MM_ContextManager sharedManager].contentContextForWriting;
    NSArray *objectsToSync = [[MM_OrgMetaData sharedMetaData] objectsToSync];
    NSMutableArray *foundObjectsArray = [NSMutableArray array];

    NSMutableArray *predicatesArray = [NSMutableArray array];

    for (NSString *idToSearch in echo) {
        [predicatesArray addObject:[NSPredicate predicateWithFormat:@"Id = %@", idToSearch]];
    }
    
    for (NSDictionary *object in objectsToSync) {
        NSArray *array = [ctx allObjectsOfType:[object valueForKey:@"name"]
                             matchingPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:predicatesArray]
                                      sortedBy:nil];
        if (array.count != 0) {
            [foundObjectsArray addObjectsFromArray:array];
        }
    }
    // Create Plugin Result
    NSString *javaScript = nil;
    NSString *stringToReturn = [foundObjectsArray JSONValueFromArrayOfMMSF_Objects];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsString: stringToReturn];    
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];

    [self performSelectorOnMainThread: @selector(writeJavascript:) withObject: javaScript waitUntilDone: NO];
}

- (void) search:(CDVInvokedUrlCommand *)command {
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        MMLog(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    NSArray *echo = [command.arguments[0] componentsSeparatedByString:@","];
    
    if ([echo count] != 3) {
        [self writeErrorForCommand:command];
    }
    
    NSManagedObjectContext *ctx = [MM_ContextManager sharedManager].contentContextForWriting;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ = '%@'", echo[1], echo[2]]];
    
    NSArray *array = [ctx allObjectsOfType:echo[0]
                             matchingPredicate:predicate//@"%@ = %@", echo[1], echo[2]]
                                      sortedBy:nil];
    if (array.count != 0) {
        // Create Plugin Result
        NSString *javaScript = nil;
        NSString *stringToReturn = [array JSONValueFromArrayOfMMSF_Objects];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsString: stringToReturn];
        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
        
        [self performSelectorOnMainThread: @selector(writeJavascript:) withObject: javaScript waitUntilDone: NO];
        
        return;
    }

    [self writeErrorForCommand:command];
}

- (void) upsert:(CDVInvokedUrlCommand*) command {
    if (![command.arguments[0] isKindOfClass:[NSString class]]) {
        LOG(@"ERROR. Received argument is %@, was expecting %@", [command.arguments[0] class], [NSString class]);
        [self writeErrorForCommand:command];
        return;
    }
    
    int createdObjectsCounter = 0;
    NSString *argumentsString = command.arguments[0];
    NSRange recordNameRange = [argumentsString rangeOfString:@","];
    NSString *recordName = [argumentsString stringByPaddingToLength:recordNameRange.location withString:@"" startingAtIndex:0];
    if (recordName.length == 0) {
        [self writeErrorForCommand:command];
        return;
    }
    
    argumentsString = [argumentsString stringByReplacingCharactersInRange:NSMakeRange(0, recordNameRange.location + 1) withString:@""];
    NSArray *echo = [argumentsString JSONValue];
    
    if ([echo count] == 0) {
        LOG(@"No fields to create");
        [self writeErrorForCommand:command];
        return;
    }
    
    if (recordName.length == 0) {
        LOG(@"Please fill in record name");
        [self writeErrorForCommand:command];
        return;
    }
    
    if (![[MM_ContextManager sharedManager] objectExistsInContentModel:recordName]) {
        [self writeErrorForCommand:command];
        LOG(@"Record with name %@ doesn't exists in current content model, consider checking sync_objects.plist", recordName);
        return;
    }
    
    for (NSDictionary *recordFields in echo) {
        // Create record
        if ([[recordFields valueForKey:@"id"] isEqualToString:@"NEW"]) {
            NSManagedObjectContext *ctx = [MM_ContextManager sharedManager].contentContextForWriting;
            MMSF_Object *newRecord = [ctx insertNewEntityWithName:recordName];
            
            for (NSString *key in [recordFields allKeys]) {
                if ([key isEqualToString:@"id"]) {
                    continue;
                }

                id value = [self getSpecifiedValueForFieldName:key inObjectDefinition:newRecord.definition fromValue:[recordFields valueForKey:key] managedContext:ctx];

                [newRecord setValue:value forKey:key];
            }
            [newRecord finishEditingSavingChanges:YES];
            createdObjectsCounter++;
            [MM_SFChange pushPendingChangesWithCompletionBlock:nil];
            
        } else { // Upsert record
            NSManagedObjectContext *ctx = [MM_ContextManager sharedManager].contentContextForWriting;
            
            NSArray *array = [ctx allObjectsOfType:recordName
                                 matchingPredicate:[NSPredicate predicateWithFormat:@"Id = %@", [recordFields valueForKey:@"id"]]
                                          sortedBy:nil];
            if (array.count == 0) {
                LOG(@"\n There is no record with Id = %@", [recordFields valueForKey:@"id"]);
                continue;
            }
            MMSF_Object *objectToChange = array[0];
            for (NSString *key in [recordFields allKeys]) {
                if ([key isEqualToString:@"id"]) {
                    continue;
                }

                id value = [self getSpecifiedValueForFieldName:key inObjectDefinition:objectToChange.definition fromValue:[recordFields valueForKey:key] managedContext:ctx];
                [objectToChange setValue:value forKey:key];
            }
            [objectToChange finishEditingSavingChanges:YES];
            createdObjectsCounter++;
        }
    }
    
    // Create Plugin Result
    NSString *javaScript = nil;
    NSString *stringToReturn = [NSString stringWithFormat:@"Number of created/upserted records = %d", createdObjectsCounter];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsString: stringToReturn];
    javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
    
    [self performSelectorOnMainThread: @selector(writeJavascript:) withObject: javaScript waitUntilDone: NO];
}

- (id) getSpecifiedValueForFieldName:(NSString *) key inObjectDefinition:(MM_SFObjectDefinition *) objectDefinition fromValue:(NSString *) value managedContext:(NSManagedObjectContext *) context
{
    NSDictionary *info = [objectDefinition infoForField:key];
    NSString *relationshipName = info[@"relationshipName"];
    if (relationshipName != nil && relationshipName != (NSString*)[NSNull null]) {
        NSArray *arrayOfRelationshipObjects = [context allObjectsOfType:relationshipName
                                                  matchingPredicate:[NSPredicate predicateWithFormat:@"Id = %@", value]
                                                           sortedBy:nil];
        if (arrayOfRelationshipObjects.count != 0) {
            return arrayOfRelationshipObjects[0];
        } else {
            LOG(@"Can't find record with id %@ to setup relationship", value);
            return nil;
        }
    }
    return value;
}

@end

#endif
