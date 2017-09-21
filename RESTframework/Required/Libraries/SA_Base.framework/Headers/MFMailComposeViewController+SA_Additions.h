//
//  MFMailComposeViewController+SA_Additions.h
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 8/15/12.
//
//

#import <MessageUI/MessageUI.h>
#import "SA_Utilities.h"

typedef void (^mailComposeCompletionBlock)(MFMailComposeResult result);

@interface MFMailComposeViewController (SA_Additions) <MFMailComposeViewControllerDelegate>
@property (nonatomic, copy) mailComposeCompletionBlock SA_CompletionBlock;
@end
