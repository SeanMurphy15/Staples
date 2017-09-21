//
//  LeadsSearchController.h
//  DSA
//
//  Created by Jason Barker on 5/8/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>



@class MMSF_Lead;

@protocol LeadsSearchControllerDelegate;



@interface LeadsSearchController : NSObject

@property (nonatomic, weak) id <LeadsSearchControllerDelegate> delegate;
@property (nonatomic, readonly) NSString *searchString;

- (id) initWithDelegate: (id <LeadsSearchControllerDelegate>) delegate;
- (void) searchForLeadsWithString: (NSString *) searchString;
- (NSInteger) numberOfLeads;
- (MMSF_Lead *) leadAtIndex: (NSInteger) index;

@end



@protocol LeadsSearchControllerDelegate <NSObject>

- (void) leadsSearchController: (LeadsSearchController *) controller didFindLeadsWithString: (NSString *) searchString;

@end