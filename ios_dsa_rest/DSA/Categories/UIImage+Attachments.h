//
//  UIImage+Attachments.h
//  DSA
//
//  Created by Mike McKinley on 4/11/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Attachments)
+ (UIImage*)imageWithAttachmentId:(NSString*)salesforceId;
@end
