//
//  DSA_SyncProgressImageView.h
//  DSA
//
//  Created by Mike McKinley on 3/27/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DSA_SyncProgressState) {
    DSA_SyncProgressState_Waiting,
    DSA_SyncProgressState_Syncing,
    DSA_SyncProgressState_Finished
};

@interface DSA_SyncProgressImageView : UIImageView

@property (assign,nonatomic) DSA_SyncProgressState syncState;

@end
