//
//  DSA_DocumentDetailsView.m
//  ios_dsa
//
//  Created by Ben Gottlieb on 8/18/13.
//
//

#import "DSA_DocumentDetailsView.h"
#import "MMSF_ContentVersion.h"

#define INFO_FONT				[UIFont systemFontOfSize: 12]

@implementation DSA_DocumentDetailsView

+ (void) showInfoForDocument: (MMSF_ContentVersion *) doc fromView: (UIView *) view {
	CGSize									size = [self optimalSizeForDocument: doc];
	
	if (CGSizeEqualToSize(size, CGSizeZero)) return;
	
	DSA_DocumentDetailsView					*info = [[DSA_DocumentDetailsView alloc] initWithFrame: CGRectFromSize(size)];
	info.editable = NO;
	info.text = doc[@"Description"];
	if (info.text.length == 0) info.text = doc[@"Title"];
	info.font = INFO_FONT;
	
	
	[UIPopoverController presentSA_PopoverForView: info fromRect: view.bounds inView: view permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
}

+ (CGSize) optimalSizeForDocument: (MMSF_ContentVersion *) version {
	NSString					*desc = version[@"Description"];
	
	if (desc == nil) desc = version[@"Title"];
	if (desc == nil) return CGSizeZero;
	
	return CGSizeMake(400, 200);
}


@end
