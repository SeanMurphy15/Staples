//
//  InfrastructureTests.m
//  ios_dsa
//
//  Created by Guy Umbright on 2/28/13.
//
//

#import "InfrastructureTests.h"
#import "MM_ContextManager.h"
#import "MM_ContextManager+Model.h"
#import "MMSF_Contact.h"
#import "MMSF_ContentVersion.h"

//!!!
//Critical point #1
//
//This category on MM_ContextManager allows us to use an MM_ContextManager of our own devising rather than the
//singleton normally accessed through MM_ContextManager
//
#import "MM_ContextManager+UnitTesting.h"

@implementation InfrastructureTests

/////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////
- (void)setUp
{
    //!!!
    //Critical point #2
    //
    //MM_ContextManager has had some configurability added so that we can override the defaults and
    //specify the locations for our desired Core Data components
    //
    NSURL* url = [[NSBundle bundleForClass:[self class]] URLForResource:@"Metadata" withExtension:@"db"];
    url = [url URLByDeletingLastPathComponent];
    [MM_ContextManager setDataStoreRoot:url];
    [MM_ContextManager setMetadataFilename:@"Metadata.db"];
    [MM_ContextManager setContentFilename:@"Main.db"];
    
    url = [[NSBundle bundleForClass:[self class]] URLForResource:@"ContentModel" withExtension:@"mom"];
    url = [url URLByDeletingLastPathComponent];
    [MM_ContextManager setContentModelRoot:url];
    [MM_ContextManager setContentModelFilename:@"ContentModel.mom"];
    
    //!!!
    //Critical point #3
    //
    //This needs to be done because MM_ContextManager normally creates the model from merged models in the bundle.
    //But in the testing bundle there can possibly be multiple models and a merged version of those is not what
    //we want at all.  So my specifying the location we just load that model alone.  In most cases these two lines
    //should just be copied as is for it to work.
    //
    url = [[NSBundle bundleForClass:[self class]] URLForResource:@"MetaModel" withExtension:@"momd"];
    [MM_ContextManager setMetadataModelRoot:url];

    //!!!
    //Critical point #4
    //
    //Here is where we are providing the custom configured MM_ContextManager that we want used for the tests
    //After this the sharedManager method on MM_ContextManager will return our custom configured MM_ContextManager
    //due to the Category override in MM_ContextManager+UnitTesting
    //
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
