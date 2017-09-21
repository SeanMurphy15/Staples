//
//  DSARestClient+SyncStatus.m
//  ios_dsa
//
//  Created by Steve Deren on 8/26/13.
//
//

#import "DSARestClient+SyncStatus.h"

@implementation DSARestClient (SyncStatus)

+ (NSString*)statusDisplayForObjectName:(NSString*) objectName {
    
    if([objectName isEqualToString:@"ContentVersion"]) {
        return @"Downloading Content";
    }
    else if([objectName isEqualToString:@"Attachment"]) {
        return @"Downloading Attachments";
    }
    else if([objectName isEqualToString:@"User"]) {
        return @"Downloading Users";
    }
    else if([objectName isEqualToString: MNSS(@"MobileAppConfig__c")]) {
        return @"Downloading Configurations";
    }
    else if([objectName isEqualToString: MNSS(@"Category__c")]) {
        return @"Downloading Categories";
    }
    else if([objectName isEqualToString: MNSS(@"CategoryMobileConfig__c")]) {
        return @"Downloading Category Configurations";
    }
    else if([objectName isEqualToString: MNSS(@"Category__c")]) {
        return @"Downloading Categories";
    }
    else if([objectName isEqualToString:@"ContentDocument"]) {
        return @"Downloading Content Documents";
    }
    else if([objectName isEqualToString:@"Contact"]) {
        return @"Downloading Contacts";
    }
    else if([objectName isEqualToString: MNSS(@"Cat_Content_Junction__c")]) {
        return @"Downloading Junction Records";
    }
    return nil;
}

@end
