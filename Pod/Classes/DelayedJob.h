//
//  DelayedJob.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJob.h"
#import "NLJob.h"
#import "NLDelayedJobManager.h"
#import "NLJobsAbility.h"


#define DelayedJob NLDelayedJob

#define DelayedJob_schedule(jobOrClass,queue_name,queue_priority,...) [[NLDelayedJob sharedManager] scheduleJob: \
 [NLJob job:jobOrClass withArguments: __VA_ARGS__ , nil ] \
 queue:queue_name priority:queue_priority internet:NO]

#define DelayedJob_configure(config_block) \
    [NLDelayedJob configure: config_block]

#define DelayedJob_create(jobOrClass, ...)  [NLJob job:jobOrClass withArguments: __VA_ARGS__ , nil ]

