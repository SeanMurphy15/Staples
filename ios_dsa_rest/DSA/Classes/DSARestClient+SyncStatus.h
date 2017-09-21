//
//  DSARestClient+SyncStatus.h
//  ios_dsa
//
//  Created by Steve Deren on 8/26/13.
//
//

#import "DSARestClient.h"

@interface DSARestClient (SyncStatus)
+ (NSString*)statusDisplayForObjectName:(NSString*) objectName;
@end
