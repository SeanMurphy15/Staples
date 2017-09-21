//
//  CK_Attachment.h
//  chattest
//
//  Created by Guy Umbright on 8/24/12.
//
//

#import "CK_ChatterKitObject.h"
#import "CK_UserSummary.h"
enum
{
    CK_AttachmentType_CaseComment=0,
    CK_AttachmentType_Content,
    CK_AttachmentType_Dashboard,
    CK_AttachmentType_Link,
    CK_AttachmentType_Unknown=-1
};

@interface CK_ChatterKitObject (CK_Attachment)
- (NSInteger) attachmentType;
@end

@interface CK_Attachment : CK_ChatterKitObject
@end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

#define CK_AttachmentCaseCommentKey_ActorType @"actorType"
#define CK_AttachmentCaseCommentKey_CreatedBy @"createdBy"
#define CK_AttachmentCaseCommentKey_CreatedDate @"createdDate"
#define CK_AttachmentCaseCommentKey_Id @"id"
#define CK_AttachmentCaseCommentKey_Published @"published"
#define CK_AttachmentCaseCommentKey_Text @"text"

@interface CK_AttachmentCaseComment : CK_Attachment
@end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
#define CK_AttachmentContentKey_Description @"description"
#define CK_AttachmentContentKey_DownloadURL @"downloadUrl"
#define CK_AttachmentContentKey_FileSize @"fileSize"
#define CK_AttachmentContentKey_FileType @"fileType"
#define CK_AttachmentContentKey_HasImagePreview @"hasImagePreview"
#define CK_AttachmentContentKey_HasPDFPreview @"hasPdfPreview"
#define CK_AttachmentContentKey_Id @"id"
#define CK_AttachmentContentKey_MimeType @"mimeType"
#define CK_AttachmentContentKey_Title @"title"
#define CK_AttachmentContentKey_VersionId @"versionId"

@interface CK_AttachmentContent : CK_Attachment
@end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
#define CK_AttachmentDashboardKey_ComponentId @"componentId"
#define CK_AttachmentDashboardKey_ComponentName @"componentName"
#define CK_AttachmentDashboardKey_DashboardBodyText @"dashboardBodyText"
#define CK_AttachmentDashboardKey_DashboardId @"dashboardId"
#define CK_AttachmentDashboardKey_DashboardName @"dashboardName"
#define CK_AttachmentDashboardKey_FullSizedImageURL @"fullSizedImageUrl"
#define CK_AttachmentDashboardKey_LastRefreshDate @"lastRefreshDate"
#define CK_AttachmentDashboardKey_LastRefreshDateDisplayText @"lastRefreshDateDisplayText"
#define CK_AttachmentDashboardKey_RunningUserId @"runningUserId"
#define CK_AttachmentDashboardKey_ThumbnailURL @"thumbnailUrl"

@interface CK_AttachmentDashboard : CK_Attachment
@end

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
#define CK_AttachmentLinkKey_Title @"title"
#define CK_AttachmentLinkKey_URL @"url"

@interface CK_AttachmentLink : CK_Attachment
@end