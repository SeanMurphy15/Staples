//
//  DSA_DocumentDetailsView.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 8/18/13.
//
//

#import <UIKit/UIKit.h>
#import "MMSF_ContentVersion.h"

@interface DSA_DocumentDetailsView : UITextView
+ (void) showInfoForDocument: (MMSF_ContentVersion *) doc fromView: (UIView *) view;
@end
