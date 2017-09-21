//
//  dispatch_additions.h
//  SABase
//
//  Created by Ben Gottlieb on 2/26/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

void	dispatch_sync_main_queue(dispatch_block_t block);		//if running on the main queue, fires now, otherwise fires sync
void	dispatch_async_main_queue(dispatch_block_t block);
void	dispatch_on_main_queue(dispatch_block_t block);			//if running on the main queue, fires now, otherwise fires async
void	dispatch_after_main_queue(NSTimeInterval delay, dispatch_block_t block);
