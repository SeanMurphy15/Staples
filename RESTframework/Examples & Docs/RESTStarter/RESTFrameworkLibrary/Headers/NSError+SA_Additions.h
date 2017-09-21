//
//  NSError+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 12/30/13.
//
//

#import <Foundation/Foundation.h>

@interface NSError (SA_Additions)
@property (nonatomic, readonly) BOOL isNoInternetConnectionError, shouldProbablyBeSupressedForMostUsers;
@end
