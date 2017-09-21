//
//  CK_AttachmentInput.m
//  chatterkitdemo
//
//  Created by Guy Umbright on 8/28/12.
//  Copyright (c) 2012 Model Metrics, Inc.. All rights reserved.
//

#import "CK_AttachmentInput.h"
#import "MM_Headers.h"

//@implementation CK_AttachmentInput
//#if 0
//contentDocumentId	String	ID of the existing content
//Attachment Input: Link
//Name	Type	Description
//url	String	URL included in the attachment
//urlName	String	Optional. Name of the URL. If not provided, a name is generated from the domain name of the URL
//Attachment Input: New File Upload
//The HTTP request should also carry a file upload part holding the file itself. Note
//If you’re uploading a new file, you must include a binary file in the multipart request.
//Name	Type	Description
//desc	String	Description of the file
//fileName	String	Name of the file
//title	String	Title of the file
//#endif

@interface CK_AttachmentInput ()

- (void) addKeys:(NSMutableDictionary*) dict;

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_AttachmentInput

////////////////////////////
//
////////////////////////////
- (NSString*) attachmentInputType
{
    NSAssert(NO, @"messageSegmentInputType must be overridden by subclass");
    return nil;
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:[self attachmentInputType] forKey:@"type"];
}

////////////////////////////
//
////////////////////////////
- (NSDictionary*) asDictionary
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [self addKeys:dict];
    
    return dict;
}

@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_AttachmentInputExistingContent

////////////////////////////
//
////////////////////////////
+ (CK_AttachmentInputExistingContent*) attachmentWithExistingContent:(NSString*) contentDocumentId
{
    CK_AttachmentInputExistingContent* attachment = [[CK_AttachmentInputExistingContent alloc] init];
    attachment.contentDocumentId = contentDocumentId;
    return [attachment autorelease];
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:self.contentDocumentId forKey:@"contentDocumentId"];
    [super addKeys:dict];
}

////////////////////////////
//
////////////////////////////
- (NSString*) attachmentInputType
{
    return @"ExistingContent";
}
@end

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
@implementation CK_AttachmentInputLink

////////////////////////////
//
////////////////////////////
+ (CK_AttachmentInputLink*) attachmentWithLink:(NSURL*) link forName:(NSString*) name;
{
    CK_AttachmentInputLink* attachment = [[CK_AttachmentInputLink alloc] init];
    attachment.link = link;
    attachment.name = name;
#if !__has_feature(objc_arc)
    return [attachment autorelease];
#else
    return attachment;
#endif
}

////////////////////////////
//
////////////////////////////
- (void) addKeys:(NSMutableDictionary *)dict
{
    [dict setObject:[self.link absoluteString] forKey:@"url"];
    [dict setObject:self.name forKey:@"urlName"];
    [super addKeys:dict];
}

////////////////////////////
//
////////////////////////////
- (NSString*) attachmentInputType
{
    return @"Link";
}

@end
