//
//  MM_XMLDocument.h
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 6/13/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MM_XMLDocument;

typedef void (^xmlDocBlock)(MM_XMLDocument *doc);

@interface MM_XMLDocument : NSObject <NSXMLParserDelegate>

+ (void) parseData: (NSData *) data withCompletion: (xmlDocBlock) completion;
- (id) objectForKeyedSubscript: (id) key;
@end



@interface MM_XMLNode : NSObject
@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, readonly) id objectValue;
@property (nonatomic, readonly) NSArray *children;
@property (nonatomic, readonly) BOOL isArray;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *content, *stringRepresentation;
- (id) objectForKeyedSubscript: (id) key;
@end