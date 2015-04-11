//
// Created by James Whitfield on 4/10/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJobManager.h"

@class NLDelayedJob;

@interface NLDelayedJobManager ()
#pragma mark - Job Reistration
- (void) registerJob: (Class) clazz;
+ (void) registerJob: (Class) clazz;

- (NSSet *)registeredJobs;
+ (NSSet *)registeredJobs;

#pragma mark - Job Locking

+ (BOOL)containsLockedJob:(NLJob *)job;

+ (void)lockJob:(NLJob *)job;

+ (void)unlockJob:(NLJob *)job;

- (BOOL)containsLockedJob:(NLJob *)job;

- (void)lockJob:(NLJob *)job;

- (void)unlockJob:(NLJob *)job;

- (void)unlockAllJobsOfClass:(Class)jobClass;

#pragma mark - Queue Tracking

- (void)registerQueue:(NLDelayedJob *)queue;

- (void)unregisterQueue:(NLDelayedJob *)queue;
@end