//
//  MM_XMLDocument.m
//  SOQLBrowser
//
//  Created by Ben Gottlieb on 6/13/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "MM_XMLDocument.h"

@interface MM_XMLDocument ()
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) MM_XMLNode *root, *top;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) xmlDocBlock completion;
@end

static NSSet			*s_parsingDocuments = nil;


@interface MM_XMLNode ()
+ (instancetype) nodeWithName: (NSString *) name attributes: (NSDictionary *) attr;
@property (nonatomic, strong, readwrite) NSDictionary *attributes;
@property (nonatomic, strong, readwrite) NSMutableArray *children;
@property (nonatomic, strong, readwrite) NSString *content;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, weak) MM_XMLNode *parent;
- (void) addChild: (MM_XMLNode *) node;
- (NSString *) descriptionWithIndent: (NSString *) indent;
- (void) addContent: (NSString *) content;
@end

@implementation MM_XMLDocument

+ (void) parseData: (NSData *) data withCompletion: (xmlDocBlock) completion {
	MM_XMLDocument			*doc = [self new];
	
	s_parsingDocuments = s_parsingDocuments ? [s_parsingDocuments setByAddingObject: doc] : [NSSet setWithObject: doc];
	
	doc.data = data;
	doc.completion = completion;
	[doc start];
}

- (void) start {
	[self.queue addOperationWithBlock: ^{
		self.parser = [[NSXMLParser alloc] initWithData: self.data];
		self.parser.shouldProcessNamespaces = YES;
		self.parser.shouldResolveExternalEntities = NO;
		self.parser.delegate = self;
		[self.parser parse];
		
		[self.queue addOperationWithBlock: ^{
			NSMutableSet			*activeDocuments = s_parsingDocuments.mutableCopy;
			
			[activeDocuments removeObject: self];
			s_parsingDocuments = activeDocuments;
			self.completion(self);
		}];
	}];
}

- (NSString *) description { return [self.root descriptionWithIndent: @""]; }
- (id) objectForKeyedSubscript: (id) key { return self.root[key]; }
- (NSString *) stringRepresentation { return [self.root descriptionWithIndent: @""]; }

//=============================================================================================================================
#pragma mark Properties
- (NSOperationQueue *) queue {
	if (_queue == nil) {
		_queue = [NSOperationQueue new];
		_queue.maxConcurrentOperationCount = 1;
	}
	return _queue;
}

//=============================================================================================================================
#pragma mark NSXMLParserDelegate

- (void) parser: (NSXMLParser *) parser didStartElement: (NSString *) elementName namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName attributes: (NSDictionary *) attributeDict {
	MM_XMLNode			*node = [MM_XMLNode nodeWithName: elementName attributes: attributeDict];
	
	if (self.top == nil) {
		self.root = node;
		self.top = node;
	} else {
		[self.top addChild: node];
		self.top = node;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	self.top = self.top.parent;
}

- (void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string {
	[self.top addContent: string];
}

@end



@implementation MM_XMLNode
+ (instancetype) nodeWithName: (NSString *) name attributes: (NSDictionary *) attr {
	MM_XMLNode		*node = [self new];
	node.attributes = attr;
	node.name = name;
	
	return node;
}

- (void) addChild: (MM_XMLNode *) node {
	node.parent = self;
	if (self.children == nil) self.children = [NSMutableArray array];
	[(id) self.children addObject: node];
}

- (NSString *) description {
	return [self descriptionWithIndent: @""];
}

- (id) objectForKeyedSubscript: (id) key {
	for (MM_XMLNode *node in self.children) {
		if ([node.name isEqual: key]) return node;
	}
	return nil;
}

- (NSString *) descriptionWithIndent: (NSString *) indent {
	NSMutableString			*desc = [NSMutableString stringWithFormat: @"%@<%@", indent, self.name];
	
	for (NSString *key in self.attributes) {
		[desc appendFormat: @" %@=\"%@\"", key, self.attributes[key]];
	}
	[desc appendFormat: @">%@", self.content ?: @""];
	if (self.children.count) {
		NSString			*childIndent = [indent stringByAppendingString: @"   "];
		for (MM_XMLNode *node in self.children) {
			[desc appendFormat: @"\n%@", [node descriptionWithIndent: childIndent]];
		}
		[desc appendFormat: @"\n%@", indent];
	}
	[desc appendFormat: @"</%@>", self.name];
	return desc;
}

- (BOOL) isArray {
	NSString			*type = self.attributes[@"type"];
	
	if ([type isEqual: @"array"]) return YES;
	if (type == nil && self.children.count == 1 && [self.name hasSuffix: @"s"]) return YES;
	if (self.children.count <= 1) return NO;
	
	NSString				*childType = [self.children[0] name];
	
	for (MM_XMLNode *node in self.children) {
		if (![node.name isEqual: childType]) return NO;
	}
	
	return YES;
}

- (NSString *) stringRepresentation { return self.description; }

- (id) objectValue {
	if (self.children.count) {
		if (self.isArray) {
			NSMutableArray					*array = [NSMutableArray array];
			
			for (MM_XMLNode *node in self.children) {
				[array addObject: node.objectValue];
			}
			return array;
		} else {
			NSMutableDictionary				*dict = [NSMutableDictionary new];
			
			for (MM_XMLNode *node in self.children) {
				if (dict[node.name] == nil) {
					dict[node.name] = node.objectValue;
				} else {
					if (![dict[node.name] isKindOfClass: [NSMutableArray class]]) {
						dict[node.name] = @[ dict[node.name] ].mutableCopy;
					}
					[dict[node.name] addObject: node.objectValue];
				}
			}
			return dict;
		}
	} else {
		if (self.content.length) return self.content;
		if (self.isArray) return @[];
		
	}
	return @{};
}


- (void) addContent: (NSString *) content {
	self.content = self.content ? [self.content stringByAppendingString: content] : content;
}

@end
