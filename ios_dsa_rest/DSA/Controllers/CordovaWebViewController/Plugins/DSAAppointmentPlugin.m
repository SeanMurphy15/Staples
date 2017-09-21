//
//  DSAAppointmentPlugin.m
//  ios_dsa
//
//  Created by Amisha Goyal on 5/15/13.
//
//
#if BUILD_WITH_CORDOVA

#import "DSAAppointmentPlugin.h"
#import "DSA_AppDelegate.h"
//#import "MMSF_Appointment__c.h"
@implementation DSAAppointmentPlugin

- (void) checkedInAppointment:(CDVInvokedUrlCommand*) command{
//    CDVPluginResult *pluginResult =nil;
//    NSString *javaScript =nil;
//    // Create Plugin Result
//    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
//    DSA_AppDelegate *appDelegate =(DSA_AppDelegate*) [[UIApplication sharedApplication] delegate];
//    
//    if(appDelegate.checkinAppointment){
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Id"] forKey:APPOINTMENT_ID];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Name"] forKey:APPOINTMENT_NAME];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Assigned_To_Name__c"] forKey:ASSIGNED_TO_NAME];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Subject__c"] forKey:SUBJECT];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Status__c"] forKey:STATUS];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"EmployeeName__c"] forKey:EMPLOYEE_NAME];
//        [dataDictionary setValue:[NSString stringWithFormat:@"%@", appDelegate.checkinAppointment[@"Visit_Date__c"]] forKey:VISIT_DATE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"End_Time__c"] forKey:END_TIME];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Start_Time__c"] forKey:START_TIME];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Contact_Customer_Name__c"] forKey:CONTACT_CUSTOMER_NAME];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Account_Address__c"] forKey:ACCOUNT_ADDRESS];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Contact_Mobile__c"] forKey:CONTACT_MOBILE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Contact_Home_Phone__c"] forKey:CONTACT_HOME_PHONE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Contact_Phone__c"] forKey:CONTACT_PHONE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Customer_Category__c"] forKey:CUSTOMER_CATEGORY];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Customer_Email_Address__c"] forKey:CUSTOMER_EMAIL_ADDRESS];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"Customer_Greeting_Name__c"] forKey:CUSTOMER_GREETING_NAME];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_Bedrooms__c"] forKey:NUMBER_OF_BEDROOMS];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_boilerWorking__c"] forKey:BOILER_WORKING];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_HotWater_Available__c"] forKey:HOT_WATER_AVAILABLE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_InstallationRating__c"] forKey:INSTALLATION_RATING];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_leadsource__c"] forKey:LEAD_SOURCE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_otherFormsOfHeating__c"] forKey:OTHER_FORMS_OF_HEATING];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_productInterest__c"] forKey:PRODUCT_INTEREST];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_SmartMeter__c"] forKey:SMARTMETER];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_VulenrableReason__c"] forKey:VULNERABLE_REASON];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_Vulnerable__c"] forKey:VULNERABLE];
//        [dataDictionary setValue:appDelegate.checkinAppointment[@"cs_WaterHardness__c"] forKey:WATER_HARDNESS];
//        [dataDictionary setValue:[NSString stringWithFormat:@"%@", appDelegate.checkinAppointment[@"Date_Visit_Booked__c"]] forKey:DATE_VISIT_BOOKED];
//    }
//    
//    if(dataDictionary != nil|| [[dataDictionary allKeys] count]!=0){
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dataDictionary];
//        javaScript = [pluginResult toSuccessCallbackString:command.callbackId];
//        
//    } else {
//        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
//        javaScript = [pluginResult toErrorCallbackString:command.callbackId];
//    }
//    
//    [self writeJavascript:javaScript];
}
@end

#endif