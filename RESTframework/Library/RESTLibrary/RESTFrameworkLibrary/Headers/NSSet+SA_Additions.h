//
//  NSSet+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 9/28/12.
//
//

#import <Foundation/Foundation.h>

@interface NSSet (SA_Additions)
@property (nonatomic, readonly) NSUInteger md5Hash;
- (NSSet *) sa_setByRemovingObject: (id) object;
@end
