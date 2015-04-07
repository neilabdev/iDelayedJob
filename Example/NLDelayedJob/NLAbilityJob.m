//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLAbilityJob.h"


@implementation NLAbilityJob {}

+ (BOOL)performJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    return NO;
}

+ (NSDate *)scheduleJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSInteger add_seconds = ([job.attempts intValue] + 5) * 4;
    NSDate *nextRunTime = [NSDate dateWithTimeIntervalSinceNow:(int) add_seconds];

    return nextRunTime;
}


@end