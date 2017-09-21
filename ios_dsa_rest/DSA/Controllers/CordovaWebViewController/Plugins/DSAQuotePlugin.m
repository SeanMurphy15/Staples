//
//  DSAQuotePlugin.m
//  ios_dsa
//
//  Created by Amisha Goyal on 5/15/13.
//
//

#import "DSAQuotePlugin.h"
#import "DSA_AppDelegate.h"
//#import "Quote.h"
@implementation DSAQuotePlugin

- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView{
//    [super initWithWebView:theWebView];
//    [self addAsObserverForName:kNotification_SignedPDFSaved selector:@selector(callbackPDFSigned:)];
//    return self;
    return nil;
}
-(void)create:(CDVInvokedUrlCommand *) command{
//    CDVPluginResult *pluginResult = nil;
//    NSString *javaScript = nil;
//    
//    NSArray *echoArray = command.arguments;
//    NSMutableDictionary *quoteDict = [NSMutableDictionary dictionaryWithDictionary:[echoArray objectAtIndex:0]];
//    NSMutableDictionary *headerDict = [NSMutableDictionary dictionaryWithDictionary:[quoteDict objectForKey:@"Header"]];    
//    NSMutableDictionary *billingDict = [headerDict objectForKey:@"BillingAddress"];
//    NSMutableDictionary *installationDict = [headerDict objectForKey:@"InstallationAddress"];
//    DSA_AppDelegate *appdelegate = (DSA_AppDelegate*)[[UIApplication sharedApplication]delegate];
//    Quote *quoteObj = appdelegate.selectedQuote;
//    
//    quoteObj.CustomerNeeds = [self checkForNullString:[quoteDict valueForKey:@"CustomerNeeds"]];
//    NSString *installationAddressString = [NSString stringWithFormat:@"%@ %@",[installationDict valueForKey:@"Street"],[installationDict valueForKey:@"PostalCode"]];
//    quoteObj.InstallationName = [self checkForNullString:[installationDict valueForKey:@"Name"]];
//    quoteObj.InstallationAddress = [self checkForNullString:installationAddressString];
//    quoteObj.InstallationMobile = [self checkForNullString:[installationDict valueForKey:@"Mobile"]];
//    quoteObj.InstallationTelephone = [self checkForNullString:[installationDict valueForKey:@"Telephone"]];
//    
//    NSString *billingAddressString = [NSString stringWithFormat:@"%@ %@",[billingDict valueForKey:@"Street"],[billingDict valueForKey:@"PostalCode"]];
//    quoteObj.BillingName =[self checkForNullString: [billingDict valueForKey:@"Name"]];
//    quoteObj.BillingAddress = billingAddressString;
//    quoteObj.BillingMobile = [self checkForNullString:[billingDict valueForKey:@"Mobile"]];
//    quoteObj.BillingTelephone = [self checkForNullString:[billingDict valueForKey:@"Telephone"]];
//    
//    quoteObj.Balance = [self checkForNullString:[headerDict valueForKey:@"Balance"]];
//    quoteObj.Deposit =[self checkForNullString: [headerDict valueForKey:@"Deposit"]];
//    quoteObj.DepositPaidBy = [self checkForNullString:[headerDict valueForKey:@"DepositPaidBy"]];
//    quoteObj.DepositReference = [self checkForNullString:[headerDict valueForKey:@"DepositReference"]];
//    quoteObj.QuoteDate = [self checkForNullString:[headerDict valueForKey:@"QuoteDate"]];
//    quoteObj.QuoteNumber =[self checkForNullString: [headerDict valueForKey:@"QuoteNumber"]];
//    quoteObj.totalPricePayable = [self checkForNullString:[headerDict valueForKey:@"TotalPricePayable"]];
//    quoteObj.TransactionId = [self checkForNullString:[headerDict valueForKey:@"TranscationId"]];
//
//    quoteObj.balancePaidBy = [self checkForNullString:[headerDict valueForKey:@"BalancePaidBy"]];
//    quoteObj.contact = [self checkForNullString:[headerDict valueForKey:@"Contact"]];
//
//    NSMutableDictionary *footerDict = [NSMutableDictionary dictionaryWithDictionary:[quoteDict objectForKey:@"Footer"]];
//    quoteObj.TotalGrossPrice = [self checkForNullString:[footerDict valueForKey:@"TotalGrossPrice"]];
//    quoteObj.NetContractPrice = [self checkForNullString:[footerDict valueForKey:@"NetContractPrice"]];
//    
//    NSMutableDictionary *detailDict = [quoteDict objectForKey:@"Details"];
//    quoteObj.DetailDescription = [self checkForNullString:[detailDict valueForKey:@"Description"]];
//    quoteObj.quoteDetailArray = [detailDict objectForKey:@"Products"];
//    if([echoArray count]>=3){
//    appdelegate.savePDFFlag = [[echoArray objectAtIndex:1] boolValue];
//    appdelegate.encryptPDF = [[echoArray objectAtIndex:2] boolValue];
//    }
//    [appdelegate launchPDF];
//    
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
//    NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionary];
//    [resultDictionary setValue:[NSString stringWithFormat:@"%d",appdelegate.isPDFSigned] forKey:@"signed"];
//    [resultDictionary setValue:PDF_PATH forKey:@"URI"];
//    if([fileMgr fileExistsAtPath:PDF_PATH]){
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultDictionary];
//        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
//    } else {
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
//        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
//    }
//    callbackId = command.callbackId;
//    appdelegate.appdelWebView = self.webView;
//    [self writeJavascript:javaScript];
}

-(void)callbackPDFSigned:(NSNotification*)note{
    [self.webView stringByEvaluatingJavaScriptFromString:@"PDFSigned()"];
}

-(void)deletePDF:(CDVInvokedUrlCommand *) command{
//    CDVPluginResult *pluginResult = nil;
//    NSString *javaScript = nil;
//    NSError *error;
//    NSString *pdfPath = command.arguments[0];
//    NSLog(@"pdf path :%@",pdfPath);
//    // Create file manager
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
//    if([fileMgr fileExistsAtPath:PDF_PATH]){
//        // Attempt to delete the file at filePath2
//        if ([fileMgr removeItemAtPath:PDF_PATH error:&error] != YES){
//            NSLog(@"Unable to delete file: %@", [error localizedDescription]);
//            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
//            javaScript = [pluginResult toErrorCallbackString:command.callbackId];
//        }
//        else{
//            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"Success"];
//            javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
//        }
//        
//   }
//    else{
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
//        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
//    }    
//    [self writeJavascript:javaScript];
//    
}


-(NSString*)checkForNullString:(NSString*)dataString{
    if([dataString isKindOfClass:[NSNull class]])
        return @" ";
    return dataString;
    
}

@end
