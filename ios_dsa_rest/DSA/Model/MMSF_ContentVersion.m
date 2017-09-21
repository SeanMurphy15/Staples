//
//  MMSF_ContentVersion.m
//  ios_dsa
//
//  Created by Gokul Sengottuvelu on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MMSF_ContentVersion.h"
#import "MMSF_Attachment.h"
#import "MMSF_Category__c.h"
#import "MMSF_ContentDocument.h"
#import "DSA_ThumbnailManager.h"
#import "DSA_CellularDataDefender.h"
#import "MMSF_Playlist_Content_Junction__c.h"

static NSCache			*s_thumbnailsCache = nil;
NSUInteger				s_thumbnailFileSizeLimit = NSUIntegerMax;

NSString * const DSA_EmailBodyString = @"Here are the documents you requested during our meeting.\n";

#define kCompetitiveInformationLabel		@"Competitive Information"

@implementation MMSF_ContentVersion

@synthesize documentsPath = _documentsPath,contentItemsPath = _contentItemsPath;
@synthesize breadcrumbPathString,mimeType;
@synthesize thumbnailImage,thumbnailImageExists;
@synthesize thumbnailMemCache;

@dynamic ContentModifiedDate;
@dynamic ContentSize;
@dynamic ContentUrl;
@dynamic CreatedDate;
@dynamic Description;
@dynamic FeaturedContentBoost;
@dynamic FeaturedContentDate;
@dynamic FileType;
@dynamic LastModifiedDate;
@dynamic ModelM_Category__c;
@dynamic NegativeRatingCount;
@dynamic PathOnClient;
@dynamic Title;
@dynamic TagCsv;
@dynamic VersionNumber;
@dynamic ContentDocumentId;

MMNS_OBJECT_PROPERTY(Document_Type__c);
MMNS_OBJECT_PROPERTY(MobileAppConfigId__c);


- (BOOL) requiresQuicklook {
	NSString				*type = [[[self valueForKey:@"PathOnClient"] pathExtension] lowercaseString];
	
	return [self.FileType containsCString: "POWER_POINT"] || [type isEqual: @"ppt"] || [type isEqual: @"pptx"];
}

- (NSString*) previewItemTitle {
    return self.Title;
}

- (NSURL*) previewItemURL {
    return [NSURL fileURLWithPath: self.fullPath];
}

- (BOOL) isMovieFile {
	NSString				*type = [[[self valueForKey:@"PathOnClient"] pathExtension] lowercaseString];
	
	return ([type isEqualToString: @"m4v"] || [type isEqualToString: @"mov"] || [type isEqualToString: @"3gp"] || [type isEqualToString: @"mp4"]);
}

- (BOOL) isZipFile {
	NSString				*type = [[[self valueForKey:@"PathOnClient"] pathExtension] lowercaseString];

	return ([type isEqualToString: @"zip"] || [type isEqualToString: @"gz"]);
}

- (BOOL) canEmail {
    return (![self isProtectedContent] && ![self isZipFile]);
}

- (NSString *) fullPath {
	return  [self pathForDataField:@"VersionData"];
}

- (BOOL)isFileDownloaded
{
    NSFileManager		*mgr = [NSFileManager defaultManager];
	
	if ([mgr fileExistsAtPath: [self fullPath]]) {
        return YES;
    }
    return NO;
}

- (UIImage *) tableCellImage {
	NSString *type = [[[self valueForKey:@"PathOnClient"] pathExtension] lowercaseString];
	
	if ([self valueForKey:@"ContentUrl"]!= nil)
        type = @"link";
	else if ([self isMovieFile])
        type = @"mov";
	else if (self.isZipFile)
        type = @"zip";
	else if ([type isEqualToString: @"jpg"] || [type isEqualToString: @"jpeg"] || [type isEqualToString: @"gif"] || [type isEqualToString: @"tiff"] || [type isEqualToString:@"png"])
        type = @"png";
	
	UIImage	*image = [UIImage imageNamed: $S(@"%@.png", type)];
	
	return image;
}


- (void)generateThumbnailSize:(CGSize)size completionBlock:(void(^)(UIImage*))completionBlock
{
    [[DSA_ThumbnailManager sharedManager] thumbnailForContentVersion:self size:size completionBlock:completionBlock];
}

- (void)generateThumbnailSize:(CGSize)size backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor*)borderColor outsets:(UIEdgeInsets)borderOutsets completionBlock:(void(^)(UIImage*))completionBlock;
{
    [[DSA_ThumbnailManager sharedManager] thumbnailForContentVersion:self size:size backgroundColor:backgroundColor borderColor:borderColor outsets:borderOutsets completionBlock:completionBlock];
}

- (BOOL) isProtectedContent {
    return ([[self valueForKey:MNSS(@"Document_Type__c") ] isEqualToString:kCompetitiveInformationLabel]);
}

- (NSString *) breadcrumbPathString {
    NSMutableArray				*categories = [NSMutableArray array];
	NSString					*format = $S(@"%@ LIKE %%@", MNSS(@"ContentId__c"));
    NSPredicate *pred = [NSPredicate predicateWithFormat: format,self.ContentDocumentId];
    MMSF_Cat_Content_Junction__c	*ccJ = [self.moc anyObjectOfType: [MMSF_Cat_Content_Junction__c entityName] matchingPredicate: pred];
    MMSF_Category__c					*parent = [ccJ valueForKey: @"Category__c"];
    NSMutableString				*path = [NSMutableString string];

	while (parent) {
		[categories addObject: parent];
		if (parent == parent.Parent_Category__c) break;
		parent = parent.Parent_Category__c;
	}
	
	NSArray				*reversedCategories = [[categories reverseObjectEnumerator] allObjects];
	
	for (MMSF_Category__c *category in reversedCategories) {
		if (path.length) [path appendFormat: @" ➨ "];
		[path appendFormat: @"%@", category.Name];
	}
	
	IF_DEBUG([path appendFormat: @" [%@]", self.PathOnClient]);
    
	return path;
}

- (NSString *) fileName {
	return  [self valueForKey:@"Title"];
}

- (NSString *) documentsPath {
    if (!_documentsPath)
        _documentsPath = [@"~/Library/Private Documents/" stringByExpandingTildeInPath];
    return _documentsPath;
}

- (NSString *) contentItemsPath {
    if (!_contentItemsPath)
        _contentItemsPath = [self.documentsPath stringByAppendingPathComponent: @"Files & Attachments"];
    return _contentItemsPath;
}

- (NSString*)categoryLocationPath {
    NSString *location = @"";
    MM_ManagedObjectContext	*moc = [MM_ContextManager sharedManager].threadContentContext;
    
    // find the Junctions that hold our Content
    NSPredicate *junctionPredicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", MNSS(@"ContentId__c"), self.documentID];
    MMSF_Cat_Content_Junction__c *junction = [moc anyObjectOfType:[MMSF_Cat_Content_Junction__c entityName] matchingPredicate:junctionPredicate];
    if (junction) {
        // immediate category
        NSString *categoryKey = MNSS(@"Category__c");
        MMSF_Category__c *category = junction[categoryKey];
        location = category.Name;
        
        // parent categories
        NSArray *parentCategories = [category parentCategories];
        for (MMSF_Category__c *parent in parentCategories) {
            location = [NSString stringWithFormat:@"%@/%@", parent.Name, location];
        }
    }
    
    return location;
}

+ (MMSF_ContentVersion*) contentItemBySalesforceId:(NSString*) sfid {
	//FIXME: should probably pass a context in here
    MM_ManagedObjectContext			*moc = [MM_ContextManager sharedManager].threadContentContext;
    
    return [moc anyObjectOfType:@"ContentVersion" matchingPredicate:[NSPredicate predicateWithFormat:@"Id = %@",sfid]];
}

/*thumbnail image*/
- (UIImage *) thumbnailImage {
    
	UIImage			*image = [s_thumbnailsCache objectForKey: self.objectIDString];
	if (image) return image;
	
	if (s_thumbnailsCache == nil) {
		s_thumbnailsCache = [[NSCache alloc] init];
		[s_thumbnailsCache setCountLimit: 100];
	}
	
	if (image) {
		[s_thumbnailsCache setObject: image forKey: self.objectIDString];
		return image;
	}
	
	if (![self.FileType isEqualToString: @"PDF"]) return nil;
    
	NSString				*path = self.thumbnailImagePath;
	if (path && [[NSFileManager defaultManager] fileExistsAtPath: path]) {
		image = [UIImage imageWithContentsOfFile: path];
		if (image) {
			[s_thumbnailsCache setObject: image forKey: self.objectIDString];
			return image;
		}
	}
	
	if ([self extractThumbnailImage]) return [s_thumbnailsCache objectForKey: self.objectIDString];
	return nil;
}

- (BOOL) thumbnailImageExists {
	if (thumbnailImage) return YES;
	
	NSString					*thumbnailSFID = [self valueForKey: @"customField2"];
	NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"linkedSalesforceID == %@ && deletePending == NO", thumbnailSFID];
	if ([self.managedObjectContext numberOfObjectsOfType: [MMSF_Attachment entityName] matchingPredicate: predicate]) return YES;
	
	NSString				*path = self.thumbnailImagePath;
	if (path && [[NSFileManager defaultManager] fileExistsAtPath: path]) return YES;
    
	return NO;
}

- (NSString *) thumbnailImagePath {
	NSString *imageDir = [[self documentsPath] stringByAppendingPathComponent:[self PathOnClient]]; 
	NSError				*error = nil;
	
	[[NSFileManager defaultManager] createDirectoryAtPath: imageDir withIntermediateDirectories: YES attributes: nil error: &error];
	
	NSString *imagePath = [imageDir stringByAppendingPathComponent: $S(@"%@.png", self.fullPath.lastPathComponent)];
    
	return imagePath;
}

+ (void) setThumbnailFileSizeLimit: (NSUInteger) limit {
	s_thumbnailFileSizeLimit = limit;
}

- (BOOL) extractThumbnailImage {    
	if (![self.FileType isEqualToString: @"PDF"]) return YES;
    
	@try {
		NSUInteger			size = [[[[NSFileManager defaultManager] attributesOfItemAtPath: self.fullPath error: nil] objectForKey: NSFileSize] intValue];
		
		if (s_thumbnailFileSizeLimit && size > s_thumbnailFileSizeLimit) {		//too big, bail
			MMLog(@"Skipping thumbnail for %@, %ld K", self.Title, (long) (size / 1024));
			return NO;
		}
		CGPDFDocumentRef	doc = CGPDFDocumentCreateWithURL((__bridge CFURLRef) [NSURL fileURLWithPath: self.fullPath]);
		CGPDFPageRef		page = CGPDFDocumentGetPage(doc, 1);
		CGRect				pageFrame = CGPDFPageGetBoxRect(page, kCGPDFCropBox), targetFrame = CGRectMake(0, 0, 200, 200);
		float				scale = targetFrame.size.width / pageFrame.size.width;
		CGAffineTransform	transform = CGAffineTransformIdentity;
		float				targetAspect = targetFrame.size.width / targetFrame.size.height, pageAspect = pageFrame.size.width / pageFrame.size.height;
		
		MMLog(@"Generating thumbnail for %@, %ld K", self.Title, (long) (size / 1024));
        
		if (pageAspect < targetAspect) scale = targetFrame.size.height / pageFrame.size.height;
		
		transform = CGAffineTransformScale(transform, 1, -1);
		transform = CGAffineTransformTranslate(transform, 0, -targetFrame.size.height);
		
		transform = CGAffineTransformScale(transform, scale, scale);
		
		float					xOffset = (targetFrame.origin.x - pageFrame.origin.x);
		float					yOffset = (targetFrame.origin.y - pageFrame.origin.y);
		
		yOffset -= (targetFrame.size.height - targetFrame.size.height) / (2 * scale);
		xOffset -= (targetFrame.size.width - targetFrame.size.width) / (2 * scale);
		
		transform = CGAffineTransformTranslate(transform, xOffset, yOffset);
		
		UIGraphicsBeginImageContext(targetFrame.size);
		CGContextRef					context = UIGraphicsGetCurrentContext();
		CGContextConcatCTM(context, transform);
		CGContextDrawPDFPage(context, page);
		
		thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		NSError				*error = nil;
		NSData				*data = UIImagePNGRepresentation(thumbnailImage);
		
		if (![data writeToFile: self.thumbnailImagePath options: 0 error: &error]) {
			MMLog(@"Error writing thumbnail image to %@: %@", self.thumbnailImagePath, error);
		}
        [s_thumbnailsCache setObject: thumbnailImage forKey: self.objectIDString];
        
		if (doc) CGPDFDocumentRelease(doc);
	} @catch (id e) {
		
	} @finally {
	}
	MMLog(@"%@", @"Thumbnail Generated");

    return YES;
}

/*MFMailcompose view controller*/
+ (void) mailComposeController: (MFMailComposeViewController *) controller  didFinishWithResult: (MFMailComposeResult) result error: (NSError *) error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

+ (MFMailComposeViewController *) controllerForMailing {
	MFMailComposeViewController			*controller = [[[MFMailComposeViewController alloc] init] autorelease];
	
#if MAILTOSALESFORCE_ENABLED
    NSString* mailToAddress = @"emailtosalesforce@n-2or5imetpuonkzsicq0x3n7w3.uhymxma4.u.le.salesforce.com";//[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultKey_MailToSalesforceAddress];
    if (mailToAddress != nil) {
        [controller setBccRecipients:[NSArray arrayWithObject:mailToAddress]];
    }
#endif
	controller.mailComposeDelegate = (id) self;

    return controller;
}

- (NSString *) filenameForMailing {
	NSString				*name = self.Title;
	name = [name stringByReplacingOccurrencesOfString: @"/" withString: @" "];
	name = [name stringByReplacingOccurrencesOfString: @"\\" withString: @" "];
	name = [name stringByReplacingOccurrencesOfString: @"|" withString: @" "];
	name = [name stringByReplacingOccurrencesOfString: @"\"" withString: @" "];
	name = [name stringByReplacingOccurrencesOfString: @":" withString: @" "];
	
	NSString				*fileExtension = self.PathOnClient.pathExtension, *nameExtension = name.pathExtension;
	
	if (nameExtension == nil || ![fileExtension isEqual: nameExtension]) name = [name stringByAppendingPathExtension: fileExtension];
	
	if (name.length == 0) name = self.titleForMailing;
	
	if (name.length > 64) {
		NSString			*ext = name.pathExtension;
		
		if (ext.length < 10) {
			name = [name stringByDeletingPathExtension];
		} else
			ext = nil;
		
		if (name.length > (64 - ext.length)) {
			name = [name substringToIndex: 63 - ext.length];
			name = [name stringByAppendingString: @"…"];
			if (ext.length) name = [name stringByAppendingPathExtension: ext];
		}
	}
	return name;
}

- (NSString *)removeSpecialCharactersFromString:(NSString *)title {
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"/\\#~`&(),;'*|%^@<>.\""];
    return [[title componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
}

- (NSString *) subjectForMailing {
	NSString			*extension = self.Title.pathExtension;
	
    if (extension.length && extension.length < 5) {
        return [self removeSpecialCharactersFromString:[self.Title stringByDeletingPathExtension]];
    }
	
	return [self removeSpecialCharactersFromString:self.Title];
}

- (NSString *) titleForMailing {
	NSString			*extension = self.Title.pathExtension;
	
    if (extension.length) {
        return [[self removeSpecialCharactersFromString:[self.Title stringByDeletingPathExtension]] stringByAppendingPathExtension:extension];
    }
	
	return [[self removeSpecialCharactersFromString:self.Title] stringByAppendingPathExtension: self.PathOnClient.lastPathComponent.pathExtension];
}

/*  Create the portion of the body for emailing content using ContentDistribution if available.
 *  Returns nil if a matching ContentDistribution object is not found or if the Public Url is nil.
 *  Requires SFDC API v32
 */

- (NSString *)contentDistibutionEmailBody {
    NSString *contentBody = nil;

    MM_ManagedObjectContext *moc = [MM_ContextManager sharedManager].mainContentContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"ContentDocumentId", self.documentID];
    NSPredicate *sentinelPredicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", @"Name", @"DSA",@"ContentDocumentId", self.documentID];
    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate,sentinelPredicate]];
    
    MMSF_Object *contentDistribution = [moc anyObjectOfType:@"ContentDistribution" matchingPredicate:predicate];
    if (!contentDistribution) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[sentinelPredicate,[NSPredicate predicateWithFormat:@"%K == %@", RELATIONSHIP_SFID_SHADOW(@"ContentDocumentId"), self.documentID]]];
        contentDistribution = [moc anyObjectOfType:@"ContentDistribution" matchingPredicate:predicate];
    }
    
    if (contentDistribution) {
        NSString *publicUrl = contentDistribution[@"DistributionPublicUrl"];
        if (publicUrl) {
            contentBody = [NSString stringWithFormat:@"<a href='%@'>%@</a><br/>", publicUrl, [self subjectForMailing]];
        }
    }
    
    return contentBody;
}

- (NSString *)contentBodyForMailing {
    NSString *contentBody = nil;
    
    if (self.ContentUrl)
    {
        contentBody = self.ContentUrl;
    }
    else
    {
        NSString *contentDistributionBody = [self contentDistibutionEmailBody];
        if (contentDistributionBody)
        {
            contentBody = contentDistributionBody;
        }
    }
    
    return contentBody;
}

- (MFMailComposeViewController *) controllerForMailingTo:(NSArray *)addresses {
    MFMailComposeViewController	*controller = [MMSF_ContentVersion controllerForMailing];
    NSString *contentBody = nil;
    
    contentBody = [self contentBodyForMailing];
    if (contentBody && contentBody.length) {
        [controller setMessageBody:contentBody isHTML:!self.ContentUrl];
    } else {
        // add attachment
        [controller setMessageBody:DSA_EmailBodyString isHTML:NO];
        [controller addAttachmentData:[NSData dataWithContentsOfMappedFile:self.fullPath] mimeType:self.mimeType fileName:self.filenameForMailing];
    }
    
    [controller setToRecipients:addresses];
    [controller setSubject:[self subjectForMailing]];
    
    return controller;
}

/*mimetype*/
- (NSString *) mimeType {
	NSString *type = [self.FileType lowercaseString];
    NSString *outMimeType = @"application/octet-stream";
	
	if ([type isEqualToString: @"m4v"] || [type isEqualToString: @"move"]  || [type isEqualToString: @"mov"])
        outMimeType = @"video/quicktime";
	else if ([type isEqualToString: @"mp4"])
        outMimeType =  @"video/mp4";
	else if ([type isEqualToString: @"pdf"])
        outMimeType =  @"application/pdf";
	else if ([type isEqualToString: @"ppt"] || [type isEqualToString: @"pptx"])
        outMimeType =  @"application/vnd.ms-powerpoint";
	else if ([type isEqualToString: @"xls"] || [type isEqualToString: @"xlsx"])
        outMimeType =  @"application/vnd.ms-excel";
	else if ([type isEqualToString: @"doc"] || [type isEqualToString: @"docx"]|| [type isEqualToString: @"word_x"])
        outMimeType =  @"application/msword";
	else if ([type isEqualToString: @"png"])
        outMimeType =  @"image/png";
	else if ([type isEqualToString: @"jpg"] || [type isEqualToString: @"jpeg"])
        outMimeType =  @"image/jpeg";
	else if ([type isEqualToString: @"gif"])
        outMimeType =  @"image/gif";
	
	return outMimeType;
}

- (NSData*) contentItemAsData {
    NSData *myData = [NSData dataWithContentsOfFile:self.fullPath];
    
    return myData;
}

+ (void) processCategory:(MMSF_Category__c*) category categorySet:(NSMutableSet*) categorySet {
    [categorySet addObject: [NSString stringWithFormat:@"'%@'",category.Id]];
    for (MMSF_Category__c* currCat in category.sortedSubcategories.copy) {
        [self processCategory:currCat categorySet:categorySet];
    }
}

+ (MM_SOQLQueryString *) baseQueryIncludingData: (BOOL) includeDataBlobs {
    NSManagedObjectContext  *metaContext = [MM_ContextManager sharedManager].metaContextForWriting;
    MM_SFObjectDefinition   *def = [MM_SFObjectDefinition objectNamed: @"ContentVersion" inContext: metaContext];
    
    // Getting the all the Category ID's that are to be added in the Where Clause
    NSManagedObjectContext  *mainContext = [MM_ContextManager sharedManager].contentContextForWriting;
    
    //Get the Query object from the definition and add the filters
    MM_SOQLQueryString *query = [def baseQueryIncludingData:NO];

    NSArray *contentVersionArray = [mainContext allObjectsOfType: [MMSF_Cat_Content_Junction__c entityName] matchingPredicate:nil] ;
    NSArray *documentIDs = [contentVersionArray valueForKey: MNSS(@"ContentId__c")];
	
    // Add personal library items too to fetch relative content versions
    NSMutableArray *ids = documentIDs.mutableCopy;
    NSArray *personalContentDocuments = [MMSF_ContentDocument personalLibraryContentDocuments];
    [ids addObjectsFromArray:[personalContentDocuments valueForKey:@"Id"]];
    
    //now the playlist content
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != NULL",MNSS(@"ContentId__c")];
    NSArray *playlistVersionArray = [mainContext allObjectsOfType: [MMSF_Playlist_Content_Junction__c entityName] matchingPredicate:predicate];
    NSArray *playistDocumentIDs = [playlistVersionArray valueForKey: MNSS(@"ContentId__c")];
    [ids addObjectsFromArray:[playistDocumentIDs valueForKey:@"Id"]];

    MM_SOQLPredicate* pred, *pred2;
    
    documentIDs = [[NSSet setWithArray:ids] allObjects];
    pred = [MM_SOQLPredicate predicateWithString:@"PublishStatus = 'P'"];
    pred = [pred predicateByAddingAndPredicate:[MM_SOQLPredicate predicateWithString:@"isLatest = true"]];
    pred = [pred predicateByAddingAndPredicate:[MM_SOQLPredicate predicateWithString:@"StaplesDSA__Available_Offline__c = true"]];
    if (documentIDs.count) {
        [pred predicateByAddingAndPredicate: [MM_SOQLPredicate predicateWithFilteredIDs: documentIDs forField: @"ContentDocumentId"]];
    } else {
        query.fetchLimit = 1;
    }
    
    pred2 = [MM_SOQLPredicate predicateWithString:@"PublishStatus = 'R'"];
    pred2 = [pred2 predicateByAddingAndPredicate:[MM_SOQLPredicate predicateWithString:@"isLatest = true"]];
    pred2 = [pred2 predicateByAddingAndPredicate:[MM_SOQLPredicate predicateWithString:@"StaplesDSA__Available_Offline__c = true"]];
    
    pred = [pred predicateByAddingOrPredicate:pred2];
    query.predicate = pred;
    return query;
}

+(NSString*)deduplicatedStringFromArray:(NSMutableArray*)contentArray{
    //Creating an NSSet from NSArray of ConetntIds to remove duplicates.
    NSSet *contentIdSet = [NSSet setWithArray:contentArray];   
    NSString *contentIdString = [NSString stringWithFormat: @"'%@'", [contentIdSet.allObjects componentsJoinedByString: @"','"]];
    
    return contentIdString;
}

- (BOOL) isLinkContent {
    NSString* itemType = [self valueForKey:@"FileType"];
    
    return ([itemType isEqualToString:@"LINK"]);
}

- (NSString *) documentID {
	return self[RELATIONSHIP_SFID_SHADOW(@"ContentDocumentId")];
    id              doc = self[@"ContentDocumentId"];
    
    if ([doc isKindOfClass: [NSString class]]) return doc;
    if ([doc isKindOfClass: [MMSF_Object class]]) return doc[@"Id"];
    return nil;
    
}

#pragma mark - 

+ (MMSF_ContentVersion *) versionMatchingDocumentID:(NSString *)docID inContext:(NSManagedObjectContext *)inMoc {
    NSManagedObjectContext *moc = inMoc;
    if (!moc) { moc = [MM_ContextManager sharedManager].threadContentContext; }
    
	NSString *fieldName = RELATIONSHIP_SFID_SHADOW(@"ContentDocumentId");
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", fieldName, docID];
    MMSF_ContentVersion *content = [moc anyObjectOfType:[self entityName] matchingPredicate:predicate];
	
    return content;
}

+ (NSArray*)personalLibraryContentVersions {
    // get content documents  where publish status = R
    NSArray *documents = [MMSF_ContentDocument personalLibraryContentDocuments];
    NSMutableArray *contentItemIds = [documents valueForKey:@"Id"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K in %@", @"ContentDocumentId.Id", contentItemIds];
    NSManagedObjectContext *moc = [MM_ContextManager sharedManager].contentContextForReading;
    NSArray *contentVersions = [moc allObjectsOfType:[self entityName] matchingPredicate:predicate];
    
    return contentVersions;
}

- (void) refreshDataBlobs: (BOOL) onlyIfNeeded {
    if (([[self ContentSize] compare:[[DSA_CellularDataDefender sharedInstance] fileSizeLimitInBytes]] == NSOrderedDescending) && [[DSA_CellularDataDefender sharedInstance] willAlertAboutFileSizeWithDismissBlock:nil])
    {
        return;
    }
    
    [super refreshDataBlobs:onlyIfNeeded];
}
@end
