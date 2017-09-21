//
//  MM_SOQLQueryString.m
//
//  Created by Ben Gottlieb on 1/3/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import "MM_SOQLQueryString.h"
#import "MM_SyncManager.h"
#import "MMSF_Object.h"
#import "MM_ContextManager.h"
#import "MM_Log.h"

#define FILTERED_ID_CHUNK_SIZE				300		//the number of IDs to include in each chunk

@interface MM_SOQLQueryString ()
@property (nonatomic, strong) NSArray *filteredIDs;
@property (nonatomic, strong) NSString *filteredIDField;
@property (nonatomic, readwrite) BOOL isEmptyQuery;
@end

@implementation MM_SOQLQueryString

+ (instancetype) emptyQuery {
	MM_SOQLQueryString			*q = [self new];
	q.isEmptyQuery =YES;
	return q;
}

- (id) nextQueryTakingMoreStringIntoAccount: (NSString *) moreString {
	MM_SOQLQueryString					*query = nil;
	
	if (moreString.length) {
		query = self.copy;
		query.moreURLString = moreString;
		return query;
	}
	
	if ((self.filteredIDPosition + FILTERED_ID_CHUNK_SIZE) < self.predicate.filteredIDsPredicate.filterIDs.count) {
		query = self.copy;
		query.moreURLString = nil;
		query.filteredIDPosition = self.filteredIDPosition + FILTERED_ID_CHUNK_SIZE;
		query.predicate.filteredIDsPredicate.filterIDPosition = query.filteredIDPosition;
		[query.predicate removeFilteredIDCoOrPredicates];
		return query;
	}
	
	return nil;
}

+ (id) queryWithObjectName: (NSString *) name {
	MM_SOQLQueryString			*query = [[self	alloc] init];
	
	query.objectName = name;
	query.isSyncOperation = YES;
	return query;
}

+ (id) queryWithSOQL: (NSString *) soql {
	MM_SOQLQueryString			*query = [[self	alloc] init];
	
	query.rawSOQL = [self detokenizedSOQLString: soql];
	return query;
}

+ (NSString *) replacementForToken: (NSString *) token {
	if ([token hasPrefix: @"current_user."]) {		//pull a field out of the current user
		NSString				*keyName = [[token componentsSeparatedByString: @"."] lastObject];
		MMSF_Object				*user = [MM_SyncManager currentUserInContext: nil];
		id						value = [user valueForKey: keyName];
		return value;
	}
    else if ([token hasPrefix: @"current_user"]) { //spd
		MMSF_Object				*user = [MM_SyncManager currentUserInContext: nil];
        NSString *				value = [NSString stringWithFormat:@"'%@'",[user valueForKey: @"Id"]];
		return value;
    }
	return @"";
}

+ (NSString *) detokenizedSOQLString: (NSString *) base {
	if (base.length == 0 || ![base containsCString: "//"]) return base;
	
	NSMutableString				*results = [base mutableCopy];
	
	while (true) {
		NSUInteger				slashPosition = [results rangeOfString: @"//"].location;
		if (slashPosition == NSNotFound) break;
		NSUInteger				nextSlashPosition = [results rangeOfString: @"//" options: 0 range: NSMakeRange(slashPosition + 2, results.length - (slashPosition + 2))].location;
		if (nextSlashPosition == NSNotFound) break;
		
		NSString				*token = [results substringWithRange: NSMakeRange(slashPosition + 2, (nextSlashPosition - (slashPosition + 2)))];
		NSString				*replacement = [self replacementForToken: token];
		
		[results replaceCharactersInRange: NSMakeRange(slashPosition, (nextSlashPosition - slashPosition) + 2) withString: replacement ?: @""];
	}
	
	return results;
}

- (id) copy {
	MM_SOQLQueryString				*query = [[[self class] alloc] init];

	query.predicate = self.predicate.copy;
	query.objectName = self.objectName;
	query.fetchOrderField = self.fetchOrderField;
	query.fetchOrderDescending = self.fetchOrderDescending;
	query.fetchLimit = self.fetchLimit;
	query.lastModifiedDate = self.lastModifiedDate;
	query.isIDOnlyQuery = self.isIDOnlyQuery;
	query.isCountQuery = self.isCountQuery;
	query.fields = self.fields;
	query.rawSOQL = self.rawSOQL;
	query.moreURLString = self.moreURLString;
	query.filteredIDs = self.filteredIDs;
	query.filteredIDField = self.filteredIDField;
	query.filteredIDPosition = self.filteredIDPosition;
    query.aggregateOperation = self.aggregateOperation;
    query.aggregateField = self.aggregateField;
	query.isFirstSyncOperation = self.isFirstSyncOperation;
	
	return query;
}

- (BOOL) shouldSearchForExistingRecordsWhenImporting { return _shouldSearchForExistingRecordsWhenImporting || !self.isFirstSyncOperation; }

- (BOOL) isFullSyncOperation {
	return self.lastModifiedDate == nil;
}

- (BOOL) isContinuationQuery { return self.moreURLString.length || self.filteredIDPosition > 0; }

- (void) addAndPredicate: (MM_SOQLPredicate *) pred {
	if (self.predicate)
		self.predicate = [self.predicate predicateByAddingAndPredicate: pred];
	else
		self.predicate = pred;
}

- (void) addOrPredicate: (MM_SOQLPredicate *) pred {
	if (self.predicate)
		self.predicate = [self.predicate predicateByAddingOrPredicate: pred];
	else
		self.predicate = [MM_SOQLPredicate orPredicateWithSubPredicates: @[ pred ]];
}

- (BOOL)isAggregateQuery { return self.aggregateField.length && self.aggregateOperation.length; }

- (void) addPredicateString: (NSString *) predString {
	if (predString.length == 0) return;

	[self addAndPredicate: [MM_SOQLPredicate predicateWithString: predString]];
}

- (NSString *) queryString {
	if (self.rawSOQL.length) return self.rawSOQL;
	
	NSMutableString				*query = [NSMutableString stringWithString: @"SELECT "];
	NSInteger					fieldCount = 0;

	#if ALLOW_FIELD_REMAPPING
		MM_SFObjectDefinition		*def = [MM_SFObjectDefinition objectNamed: self.objectName inContext: nil];
	#endif
	
	if (self.isCountQuery) {
		[query appendString: @"count()"];
	} else if (self.isIDOnlyQuery) {
		[query appendFormat: @"Id"];
    } else if ([self isAggregateQuery]) {
        [query appendFormat:@"%@(%@)", self.aggregateOperation, self.aggregateField];
	} else for (NSString *name in self.fields) {
		NSString				*serverFieldName = name;
		#if ALLOW_FIELD_REMAPPING
			[def serverFieldNameForLocalName: name];
		#endif

		[query appendFormat: fieldCount ? @",%@" : @"%@", serverFieldName];
		fieldCount++;
	}

	[query appendFormat: @" FROM %@", [MM_SFObjectDefinition serverObjectNameForLocalName: self.objectName]];
	
	MM_SOQLPredicate					*pred = self.predicate, *datePred = nil;
	
	if (!self.isCountQuery && self.lastModifiedDate) datePred = [MM_SOQLPredicate predicateWithString: $S(@"LastModifiedDate > %@", self.lastModifiedDate.salesforceStringRepresentation)];
	
	if (datePred) pred = pred ? [pred predicateByAddingAndPredicate: datePred] : datePred;
	
	if (pred) [query appendFormat: @" WHERE (%@)", pred.stringValue];
	
	if (!self.isCountQuery) {
		if (self.fetchOrderField.length) [query appendFormat: @" ORDER BY %@ %@", self.fetchOrderField, self.fetchOrderDescending ? @"DESC" : @"ASC"];
		if (self.fetchLimit) [query appendFormat: @" LIMIT %d", (UInt16)  self.fetchLimit];
	}
	
	if (query.length > 9600) {
		MMLog(@"Warning, very long query string: %@…", [query substringToIndex: 100]);
	}
	
	MMVerboseLog(@"*********** Generated Query String: %@", query);
	return query;
}
- (NSString *) description {
	return $S(@"MM_SOQLQuery: %@", self.moreURLString ?: self.queryString);
}

- (void) filterForIDs: (NSArray *) ids inField: (NSString *) field {
	[self addAndPredicate: [MM_SOQLPredicate predicateWithFilteredIDs: ids forField: field]];
}
@end


@implementation MM_SOQLPredicate
//================================================================================================================
#pragma mark Factory

+ (id) predicateWithString: (NSString *) raw {
	MM_SOQLPredicate			*pred = [self new];
	
	pred.rawPredicate = raw;
	return pred;
}
+ (id) predicateWithFilteredIDs: (NSArray *) ids forField: (NSString *) field {
	if (ids.count == 0) return nil;
	
	MM_SOQLPredicate			*pred = [self new];
	NSMutableSet				*uniqued = [NSMutableSet setWithArray: ids];
	
	if ([ids containsObject: [NSNull null]]) {
		LOG(@"Trying to create a filter predicate with a NULL in the list (%@)", field);
		[uniqued removeObject: [NSNull null]];
	}
	
	pred.filterField = field;
	pred.filterIDs = uniqued.allObjects;
	return pred;
}

+ (id) andPredicateWithSubPredicates: (NSArray *) subPredicates {
	MM_SOQLPredicate			*pred = [self new];
	
	pred.subPredicates = subPredicates;
	return pred;
}

+ (id) orPredicateWithSubPredicates: (NSArray *) subPredicates {
	MM_SOQLPredicate			*pred = [self new];
	
	pred.subPredicates = subPredicates;
	pred.useOrForSubPredicates = YES;
	return pred;
}


//================================================================================================================
#pragma mark  Copying/adding
- (BOOL) isEqual: (MM_SOQLPredicate *) other {
	if (![other isKindOfClass: [MM_SOQLPredicate class]]) return NO;
	
	if ((other.rawPredicate.length != self.rawPredicate.length) || (other.rawPredicate && ![self.rawPredicate isEqual: other.rawPredicate])) return NO;
	if ((other.filterField.length != self.filterField.length) || (other.filterField && ![self.filterField isEqual: other.filterField])) return NO;
	if ((other.filterIDs.count != self.filterIDs.count) || (other.filterIDs && ![self.filterIDs isEqual: other.filterIDs])) return NO;
	
	if (self.subPredicates.count != other.subPredicates.count || (self.subPredicates && ![self.subPredicates isEqual: other.subPredicates])) return NO;
	return YES;
}


- (id) predicateByAddingOrPredicate: (MM_SOQLPredicate *) pred {
	if ([pred isEqual: self] || [self.subPredicates containsObject: pred]) return self;
	
	if (self.subPredicates && self.useOrForSubPredicates) {
		self.subPredicates = [self.subPredicates arrayByAddingObject: pred];
		return self;
	}
	
	return [MM_SOQLPredicate orPredicateWithSubPredicates: @[ self, pred]];
}

- (id) predicateByAddingAndPredicate: (MM_SOQLPredicate *) pred {
	if ([pred isEqual: self] || [self.subPredicates containsObject: pred]) return self;

	if (self.subPredicates && !self.useOrForSubPredicates) {
		self.subPredicates = [self.subPredicates arrayByAddingObject: pred];
		return self;
	}
	
	return [MM_SOQLPredicate andPredicateWithSubPredicates: @[ self, pred]];
}

- (MM_SOQLPredicate *) filteredIDsPredicate {
	if (self.filterIDs) return self;
	for (MM_SOQLPredicate *pred in self.subPredicates) {
		MM_SOQLPredicate			*filter = pred.filteredIDsPredicate;
		
		if (filter) return filter;
	}
	
	return nil;
}

- (void) removeFilteredIDCoOrPredicates {
	if (self.useOrForSubPredicates) {
		for (MM_SOQLPredicate *subsub in self.subPredicates) {
			if (subsub.filterField) {
				self.subPredicates = @[ subsub ];
				return;
			}
		}
	}

//	for (MM_SOQLPredicate *subsub in self.subPredicates) {
//		if (subsub.filterField) {
//			self.subPredicates = @[ subsub ];
//			return;
//		}
//	}
}

- (id) copyWithZone: (NSZone *) zone {
	MM_SOQLPredicate		*pred = [[self class] new];
	
	pred.rawPredicate = self.rawPredicate;
	pred.filterIDs = self.filterIDs;
	pred.filterField = self.filterField;
	pred.useOrForSubPredicates = self.useOrForSubPredicates;
	
	if (self.subPredicates.count) {
		NSMutableArray		*preds = [NSMutableArray array];
		
		for (MM_SOQLPredicate *subpred in self.subPredicates) {
			[preds addObject: subpred.copy];
		}
		pred.subPredicates = preds;
	}
	return pred;
}

- (NSString *) stringValue {
	if (self.rawPredicate) return [MM_SOQLQueryString detokenizedSOQLString: self.rawPredicate];
	
	if (self.filterIDPosition < self.filterIDs.count) {
		NSUInteger				chunkLength = MIN(FILTERED_ID_CHUNK_SIZE, self.filterIDs.count - self.filterIDPosition);
		
		return $S(@"%@ in ('%@')", self.filterField, [[self.filterIDs subarrayWithRange: NSMakeRange(self.filterIDPosition, chunkLength)] componentsJoinedByString: @"','"]);
	}
	
	if (self.subPredicates) {
		NSMutableString				*query = [NSMutableString stringWithString: @"("];
		NSMutableArray				*components = [NSMutableArray array];
		NSUInteger					predCount = 0;
		
		for (MM_SOQLPredicate *pred in self.subPredicates) {
			NSString			*chunk = pred.stringValue;
			
			if (chunk.length) [components addObject: chunk];
		}
		
		for (NSString *predString in components) {
			[query appendFormat: [predString containsCString: "("] ? @"%@" : @"(%@)", predString];
			predCount++;
			if (predCount < components.count) [query appendString: self.useOrForSubPredicates ? @" OR " : @" AND "];
		}
		
		[query appendString: @")"];
		return query;

	}
	
	return nil;
}

- (NSString *) description { return self.stringValue; }

@end
