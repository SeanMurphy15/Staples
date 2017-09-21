//
//  ChatterPostViewController.h
//  ios_dsa
//
//  Created by Guy Umbright on 10/24/12.
//
//

#import <UIKit/UIKit.h>
#import "ChatterKit.h"
#import "MMSF_ContentVersion.h"

@class ChatterPostViewController;

@protocol ChatterPostViewControllerDelegate

- (void) chatterPostViewController:(ChatterPostViewController*) controller donePressedWithPostBody:(NSString*) postBody;
- (void) chatterPostViewControllerCancelPressed:(ChatterPostViewController*) controller;

@end

@interface ChatterPostViewController : UIViewController

@property (nonatomic, unsafe_unretained) NSObject<ChatterPostViewControllerDelegate>* chatterPostDelegate;
@property (nonatomic, unsafe_unretained) UIPopoverController* containerPopoverController;  //???
@property (nonatomic, readwrite, unsafe_unretained) MMSF_ContentVersion *item;  //???
@end
