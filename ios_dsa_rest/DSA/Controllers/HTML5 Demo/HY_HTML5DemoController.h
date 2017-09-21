//
//  HY_HTML5DemoController.h
//  Hydra
//
//  Created by Ben Gottlieb on 7/25/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MM_Headers.h"


@interface HY_HTML5DemoController : UIViewController {

}

@property (nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIWebView *webView, *docWebView;

+ (id) controller;
@end
