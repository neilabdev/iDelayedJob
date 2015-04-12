//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLAbilityJob.h"


@implementation NLAbilityJob {}

+ (BOOL)performJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSLog(@"performJob: job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",job.handler,job.job_id,job.queue,job.attempts,job.run_at);
    return NO;
}

+ (NSDate *)scheduleJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSInteger add_seconds = ([job.attempts intValue] + 5) * 4;
    NSDate *nextRunTime = [NSDate dateWithTimeIntervalSinceNow:(int) add_seconds];
    return nextRunTime;
}


+ (BOOL)shouldRestartJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSLog(@"shouldRestartJob: job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",job.handler,job.job_id,job.queue,job.attempts,job.run_at);
    return NO;
}

+ (void)beforeDeleteJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSLog(@"beforeDeleteJobs: job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",job.handler,job.job_id,job.queue,job.attempts,job.run_at);

    return;
}


@end