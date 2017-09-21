//
//  DSA_AboutPaneController.h
//  Hydra
//
//  Created by Patrick McCarron on 7/19/11.
//  Copyright 2011 Model Metrics. All rights reserved.
//



@interface DSA_AboutPaneController : UIViewController {

    
}

@property (nonatomic) CGSize popoverContentSize;
@property (nonatomic, strong) IBOutlet UILabel* version;
@property (nonatomic, strong) IBOutlet UILabel* user;

+ (id) controller;
@end
