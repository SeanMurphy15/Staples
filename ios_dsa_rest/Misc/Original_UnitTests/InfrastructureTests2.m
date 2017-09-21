//
//  InfrastructureTests.m
//  ios_dsa
//
//  Created by Guy Umbright on 2/28/13.
//
//

#import "InfrastructureTests2.h"
#import "MM_ContextManager.h"
#import "MM_ContextManager+Model.h"
#import "MMSF_Contact.h"
#import "MMSF_ContentVersion.h"
#import "MM_ContextManager+UnitTesting.h"

@implementation InfrastructureTests2

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)setUp
{
    NSURL* url = [[NSBundle bundleForClass:[self class]] URLForResource:@"Metadata2" withExtension:@"db"];
    url = [url URLByDeletingLastPathComponent];
    [MM_ContextManager setDataStoreRoot:url];
    [MM_ContextManager setMetadataFilename:@"Metadata2.db"];
    [MM_ContextManager setContentFilename:@"Main2.db"];

    url = [[NSBundle bundleForClass:[self class]] URLForResource:@"ContentModel2" withExtension:@"mom"];
    url = [url URLByDeletingLastPathComponent];
    [MM_ContextManager setContentModelRoot:url];
    [MM_ContextManager setContentModelFilename:@"ContentModel2.mom"];
 
    url = [[NSBundle bundleForClass:[self class]] URLForResource:@"MetaModel" withExtension:@"momd"];
    [MM_ContextManager setMetadataModelRoot:url];
    
    [MM_ContextManager setOverrideContextManager:[[MM_ContextManager alloc] init]];
   
    NSManagedObjectContext* ctx = [MM_ContextManager sharedManager].mainMetaContext;
    ctx = [MM_ContextManager sharedManager].mainContentContext;
    
    [super setUp];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)tearDown
{
    [super tearDown];
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) testGetContacts
{
    NSError* error;
    
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName: [MMSF_Contact entityName]];
    NSArray* result = [[MM_ContextManager sharedManager].contentContextForReading executeFetchRequest: request error: &error];
    
    STAssertTrue((result.count == 26), @"count was wrong");
}

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void) testGetContentVersions
{
    NSError* error;
    
    NSFetchRequest* request = [[NSFetchRequest alloc] initWithEntityName: [MMSF_ContentVersion entityName]];
    NSArray* result = [[MM_ContextManager sharedManager].contentContextForReading executeFetchRequest: request error: &error];
    
    STAssertTrue((result.count == 13), @"count was wrong");
}
@end
