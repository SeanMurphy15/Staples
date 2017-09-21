//
//  DSAQuotePlugin.h
//  ios_dsa
//
//  Created by Amisha Goyal on 5/15/13.
//
//
#import <Foundation/Foundation.h>

#if BUILD_WITH_CORDOVA

#import <Cordova/CDVPlugin.h>

@interface DSAQuotePlugin : CDVPlugin{
    NSString *callbackId;
}

-(void)create:(CDVInvokedUrlCommand *) command;
-(void)deletePDF:(CDVInvokedUrlCommand *) command;
@end
#endif