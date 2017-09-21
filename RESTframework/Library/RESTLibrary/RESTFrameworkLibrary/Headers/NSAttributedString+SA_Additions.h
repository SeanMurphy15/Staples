//
//  NSAttributedString+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 3/14/14.
//
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (SA_Additions)
@property (nonatomic, readonly) NSRange fullRange;

+ (id) stringWithString: (NSString *) string;
+ (id) stringWithString: (NSString *) string attributes: (NSDictionary *) attr;

- (id) stringByAppendingAttributedString: (NSAttributedString *) string;

@end

@interface NSMutableAttributedString (SA_Additions)

- (void) appendString: (NSString *) string;
- (void) appendString: (NSString *) string attributes: (NSDictionary *) attr;

- (void) setFont: (UIFont *) font;
- (void) setColor: (UIColor *) color;

@end
