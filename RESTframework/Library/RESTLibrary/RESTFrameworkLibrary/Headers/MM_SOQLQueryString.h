//
//  MM_SOQLQueryString.h
//
//  Created by Ben Gottlieb on 1/3/12.
//  Copyright (c) 2012 Model Metrics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MM_SOQLPredicate : NSObject <NSCopying>

+ (id) predicateWithString: (NSString *) raw;
+ (id) predicateWithFilteredIDs: (NSArray *) ids forField: (NSString *) field;
+ (id) andPredicateWithSubPredicates: (NSArray *) subPredicates;
+ (id) orPredicateWithSubPredicates: (NSArray *) subPredicates;

@property (nonatomic, strong) NSString *rawPredicate;
@property (nonatomic, strong) NSArray *filterIDs;
@property (nonatomic, strong) NSString *filterField;
@property (nonatomic, strong) NSArray *subPredicates;
@property (nonatomic) BOOL useOrForSubPredicates;
@property (nonatomic) NSUInteger filterIDPosition;
@property (nonatomic, readonly) MM_SOQLPredicate *filteredIDsPredicate;
@property (nonatomic) NSUInteger filteredIDPosition;

@property (nonatomic, readonly) NSString *stringValue;

- (id) predicateByAddingAndPredicate: (MM_SOQLPredicate *) pred;
- (id) predicateByAddingOrPredicate: (MM_SOQLPredicate *) pred;
@end




@interface MM_SOQLQueryString : NSObject

@property (nonatomic, readonly) NSString *queryString;

@property (nonatomic, strong) NSArray *fields;
//@property (nonatomic, strong) NSMutableArray *predicateStrings;		//not actual predicates, just stuff like (ModifiedDate < 12/12/12)
@property (nonatomic, strong) NSString *objectName, *fetchOrderField, *rawSOQL;
@property (nonatomic) BOOL fetchOrderDescending, isIDOnlyQuery, isCountQuery;
@property (nonatomic) NSUInteger fetchLimit;
@property (nonatomic, strong) NSDate *lastModifiedDate;
@property (nonatomic) BOOL isSyncOperation;								//is this operation a sync operation (full or delta)?
@property (nonatomic, readonly) BOOL isFullSyncOperation;				//is this operation going to pull down 'all' data?
@property (nonatomic) BOOL isRetryQuery;								//are we retrying a failed operation?
@property (nonatomic, strong) NSString *moreURLString;
@property (nonatomic) NSUInteger filteredIDPosition;
@property (nonatomic, readonly) BOOL isContinuationQuery;
@property (nonatomic, strong) MM_SOQLPredicate *predicate;

+ (id) queryWithObjectName: (NSString *) name;
+ (NSString *) detokenizedSOQLString: (NSString *) base;
+ (id) queryWithSOQL: (NSString *) soql;

- (void) addPredicateString: (NSString *) predString;
- (void) addAndPredicate: (MM_SOQLPredicate *) pred;
- (void) addOrPredicate: (MM_SOQLPredicate *) pred;
- (void) clearPredicates;


//If you need to filter your query to narrow it down by salesforce ID, use the following method. For example, instead of
//adding "where Id in (list of ids)", simply call [query filterForIds: idsToFilterOn inField: @"Id"]
//this will allow us to break the query into multiple sub queries if necessary to avoid query length restrictions.
- (void) filterForIDs: (NSArray *) ids inField: (NSString *) field;

- (id) nextQueryTakingMoreStringIntoAccount: (NSString *) moreString;
@end


