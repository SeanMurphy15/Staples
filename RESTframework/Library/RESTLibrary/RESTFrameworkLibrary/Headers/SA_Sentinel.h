//
//  SA_Sentinel.h
//  SABase
//
//  Created by Ben Gottlieb on 4/17/14.
//
//

#import <Foundation/Foundation.h>


@interface SA_Sentinel : NSObject

+ (instancetype) sentinelWithCompletionBlock: (booleanArgumentBlock) block;		//this should be weak referenced, and will go away after firing

@property (nonatomic, copy) errorArgumentBlock errorBlock;				//set this, and then call -abortWithError: or -decrementWithError:
@property (nonatomic) NSTimeInterval timeout;							//call -abortWithError: if the sentinel hasn't completed before the timeout
@property (nonatomic) NSTimeInterval decrementTimeout;					//call -abortWithError: if the sentinel hasn't decremented before the timeout, reset each decrement

- (void) increment;
- (void) decrement;
- (void) decrementWithError: (NSError *) error;

- (void) abort;
- (void) abortWithError: (NSError *) error;



@end
