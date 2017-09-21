// Cordova2SharedLibPlugin.h
//
//
// Copyright (c) ModelMetrics 2012
// Created by Alexey Bilous
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>


@interface Cordova2SharedLibPlugin : CDVPlugin {
    NSString *callbackID;  
    
}

@property (nonatomic, copy) NSString *callbackID;

// Instance Method  

- (void) print:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options;
- (void) getRecordsUsingQuery:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options;
- (void) syncButtonPressed:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options;
- (void) logoutButtonPressed:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options;

@end

