//
//  NSDate+ExtendedNSDate.m
//  PhoneGap2SalesforceSDK
//
//  Created by Alexey Bilous on 9/10/12.
//
//

#import "NSDate+ExtendedNSDate.h"

@implementation NSDate (ExtendedNSDate)

- (id)proxyForJson {
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"];
    
    NSString *resultString = [outputFormatter stringFromDate:self];
    return resultString;
}
@end
