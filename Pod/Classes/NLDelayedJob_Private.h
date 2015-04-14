//
//  NLDelayedJob_Private.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJob.h"

@interface NLDelayedJob ()
- (NSInteger)processJobsUpToMaximum:(NSInteger)maximum;

- (NSArray *)allScheduledJobs; // returns a list of all jobs in the queue
- (void)reset;
@end