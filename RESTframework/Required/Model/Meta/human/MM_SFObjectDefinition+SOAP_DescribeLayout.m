//
//  MM_SFObjectDefinition+SOAP_DescribeLayout.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 5/6/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "MM_SFObjectDefinition+SOAP_DescribeLayout.h"
#import "SBJson.h"
//#import <SalesforceOAuth/SFOAuthCoordinator.h>
#import "MM_LoginViewController.h"
#import "MM_ContextManager.h"
#import "MM_Notifications.h"
#import "MM_Constants.h"
#import "MM_Log.h"
#import "MM_XMLDocument.h"

@implementation MM_SFObjectDefinition (SOAP_DescribeLayout)

+ (void) setupSOAPURL {
	[self setupSOAPURLWithCompletionBlock: nil];
}

+ (void) setupSOAPURLWithCompletionBlock: (simpleBlock) block {
	NSURL				*url = [SFOAuthCoordinator currentIdentityURL];
	if (url == nil) return;
	
	SA_Connection		*connection = [SA_Connection connectionWithURL: url payload: nil method: @"GET" priority: 5 completionBlock: ^(SA_Connection *incoming, NSInteger result, NSError *error) {
		NSError					*jsonError;
		NSDictionary			*results = [NSJSONSerialization	JSONObjectWithData: incoming.data options: 0 error: &jsonError];
		int						preferredAPIVersion = 32;
		NSString				*rawURL = [[results objectForKey: @"urls"] objectForKey: @"partner"];
		
		rawURL = [rawURL stringByReplacingOccurrencesOfString: @"{version}" withString: $S(@"%d.0", preferredAPIVersion)];
		
		[[NSUserDefaults standardUserDefaults] setObject: rawURL forKey: DEFAULTS_SOAP_URL];
		if (block) block();
	}];
	
	[connection addHeader: $S(@"OAuth %@", [SFOAuthCoordinator currentAccessToken]) label: @"Authorization"];
	[connection queue];
	
}

- (void) checkForDeletedRecordsSince: (NSDate *) date {
//	if ([self.name isEqual: @"Account"]) {
//		date = [NSDate dateWithTimeIntervalSinceNow: -3600 * 24 * 30];
//	}
	
	NSString				*name = [MM_SFObjectDefinition serverObjectNameForLocalName: self.name];
				
	if ([[self valueForKey: @"replicateable"] intValue] == 0) return;			//not replicable
	if (date == nil) date = self.lastSyncedAt_mm;
	if (date == nil || date.absoluteTimeIntervalFromNow < 60) return; //never synced. or synced too recently
	NSManagedObjectID	*objectID = (id) self.objectID;
	NSString			*soap = $S(@"<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns='urn:partner.soap.sforce.com'>"
								   @"<s:Header>"
								   @"<SessionHeader><sessionId>%@</sessionId></SessionHeader>"
								   @"</s:Header>"
								   @"<s:Body>"
								   @"<getDeleted><sObjectType>%@</sObjectType><startDate>%@</startDate><endDate>%@</endDate></getDeleted>"
								   @"</s:Body>"
								   @"</s:Envelope>", [SFOAuthCoordinator currentAccessToken], name, [date salesforceStringRepresentation], [[NSDate date] salesforceStringRepresentation]);
	NSData				*soapData = [NSData dataWithString: soap];
	NSString			*soapURL = [[NSUserDefaults standardUserDefaults] objectForKey: DEFAULTS_SOAP_URL];
	
	if (soapURL == nil) return;
	
	SA_Connection		*connection = [SA_Connection connectionWithURL: [NSURL URLWithString: soapURL] payload: soapData method: @"POST" priority: 5 completionBlock: ^(SA_Connection *incoming, NSInteger result, NSError *error) {
		[MM_XMLDocument parseData: incoming.data withCompletion:^(MM_XMLDocument *doc) {
			NSArray					*removedIDNodes = [doc[@"Body"][@"getDeletedResponse"][@"result"][@"deletedRecords"] children];
			
			if (removedIDNodes == nil) {		//might be a fault
				MM_XMLNode				*fault = doc[@"Body"][@"Fault"][@"faultstring"];
				MM_SFObjectDefinition	*def = (id) [[MM_ContextManager sharedManager].threadMetaContext objectWithID: objectID];
				BOOL					clearOut = fault != nil;
				
				if (fault) {
                    NSString *faultString = fault.stringRepresentation;
					MMLog(@"Error while checking for deleted records: %@", faultString);			//better re-sync
					if ([faultString hasPrefix: @"INVALID_TYPE"])
                        clearOut = NO;
				}
                
				NSString					*dateString = doc[@"Body"][@"getDeletedResponse"][@"result"][@"earliestDateAvailable"];
				NSDate						*date = [NSDate dateWithUNIXString: dateString];
				
				if ([date earlierDate: def.lastSyncedAt_mm] == def.lastSyncedAt_mm) clearOut = YES;
				
				if (clearOut) {
					[def resetLastSyncDate];
					[def save];
				}
			} else {
				NSMutableArray				*removedIDs = [NSMutableArray array];
				
				@try {
					for (MM_XMLNode *node in removedIDNodes) {
						if ([node.name isEqual: @"id"]) [removedIDs addObject: node.content];
					}
				} @catch (id e) {
					NSLog(@"Failed to extract deleted IDs from SOAP (got %@)", removedIDNodes);
					MM_SFObjectDefinition	*def = (id) [[MM_ContextManager sharedManager].threadMetaContext objectWithID: objectID];
					[def resetLastSyncDate];
					[def save];
				}
				
				if (removedIDs.count) {
					NSManagedObjectContext				*moc = [MM_ContextManager sharedManager].contentContextForWriting;
					
					[moc deleteObjectsOfType: name matchingPredicate: $P(@"Id in %@", removedIDs)];
					[moc save];
					[MM_ContextManager saveContentContext];
				}
			}
		}];
	}];
	[connection addHeader: $S(@"OAuth %@", [SFOAuthCoordinator currentAccessToken]) label: @"Authorization"];
	[connection addHeader: @"text/xml" label: @"Content-Type"];
	[connection addHeader: @"\"\"" label: @"Soapaction"];
	[connection queue];
}

- (void) downloadDescribeLayout {
	NSString			*name = [MM_SFObjectDefinition serverObjectNameForLocalName: self.name];
	NSString			*soap = $S(@"<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns='urn:partner.soap.sforce.com'>"
								   @"<s:Header>"
								   @"<SessionHeader><sessionId>%@</sessionId></SessionHeader>"
								   @"</s:Header>"
								   @"<s:Body>"
								   @"<describeLayout><sObjectType>%@</sObjectType></describeLayout>"
								   @"</s:Body>"
								   @"</s:Envelope>", [SFOAuthCoordinator currentAccessToken], name);
	NSData				*soapData = [NSData dataWithString: soap];
	NSString			*soapURL = [[NSUserDefaults standardUserDefaults] objectForKey: DEFAULTS_SOAP_URL];
	
	
	if (soapURL == nil) return;
	
	SA_Connection		*connection = [SA_Connection connectionWithURL: [NSURL URLWithString: soapURL] payload: soapData method: @"POST" priority: 5 completionBlock: ^(SA_Connection *incoming, NSInteger result, NSError *error) {
		[MM_XMLDocument parseData: incoming.data withCompletion: ^(MM_XMLDocument *doc) {
			MM_SFObjectDefinition	*def = [MM_SFObjectDefinition objectNamed: self.name inContext: nil];
			MM_XMLNode				*result = doc[@"Body"][@"describeLayoutResponse"][@"result"];
			
			def.layout_mm = [result objectValue];
			[def save];
			[[MM_ContextManager sharedManager] saveMetaContext];
			[MM_SFObjectDefinition clearCachedObjectDefinitions];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_ObjectLayoutDescriptionAvailable object: def.name];
		}];
	}];
	[connection addHeader: $S(@"OAuth %@", [SFOAuthCoordinator currentAccessToken]) label: @"Authorization"];
	[connection addHeader: @"text/xml; charset=utf-8" label: @"Content-Type"];
	[connection addHeader: @"\"\"" label: @"Soapaction"];
	[connection queue];
}

- (void) refreshDescribeLayout {
	self.layout_mm = nil;
	[self.moc save];
	[self describeLayout];
}

- (NSDictionary *) describeLayout {
	if (self.layout_mm) return (id) self.layout_mm;
	if ([[NSUserDefaults standardUserDefaults] objectForKey: DEFAULTS_SOAP_URL] == nil) {
		NSManagedObjectID	*objectID = self.objectID;

		[MM_SFObjectDefinition setupSOAPURLWithCompletionBlock: ^{
			NSManagedObjectContext	*moc = [MM_ContextManager sharedManager].metaContextForWriting;
			MM_SFObjectDefinition	*def = (id) [moc objectWithID: objectID];

			[def downloadDescribeLayout];
		}];
	} else {
		[self downloadDescribeLayout];
	}
	return nil;
}

@end
