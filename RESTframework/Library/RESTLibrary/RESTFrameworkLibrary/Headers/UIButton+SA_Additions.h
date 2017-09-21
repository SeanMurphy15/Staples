//
//  UIButton+SA_Additions.h
//
//  Created by Ben Gottlieb on 8/13/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIButton (UIButton_SA_Additions)

//user _highlighted.png, _disabled.png, _selected.png, and _highlighted_selected.png for additional button configuration
+ (id) buttonWithImageNamed: (NSString *) imageName;
@end
