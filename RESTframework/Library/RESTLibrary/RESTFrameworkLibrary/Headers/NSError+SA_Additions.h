//
//  NSError+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 12/30/13.
//
//

#import <Foundation/Foundation.h>

extern NSString			*SA_BaseErrorDomain;

typedef NS_ENUM(NSUInteger, sa_base_error) {
	sa_base_error_connection_failed =					100,
	sa_base_error_sentinel_timeout,
	sa_base_error_sentinel_decrement_timeout,
};


@interface NSError (SA_Additions)
@property (nonatomic, readonly) BOOL isNoInternetConnectionError, shouldProbablyBeSupressedForMostUsers;
@end
