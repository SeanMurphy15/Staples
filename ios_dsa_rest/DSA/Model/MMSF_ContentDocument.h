//
//  MMSF_ContentDocument.h
//  ios_dsa
//
//  Created by Guy Umbright on 11/20/12.
//
//

#import "MMSF_Object.h"

@interface MMSF_ContentDocument : MMSF_Object

@property (nonatomic, strong) NSString *publishStatus;

+ (NSInteger) countOfPersonalContent;
+ (NSArray*) personalLibraryContentDocuments;

@end
