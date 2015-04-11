//
// Created by James Whitfield on 4/10/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJobManager.h"

@interface NLDelayedJobManager()

+ (NSArray*) registeredJobs;
- (NSArray*) registeredJobs;

+ (void) registerJob: (Class) clazz;
+ (void) registerAllJobs: (NSArray*) jobClasses;


#pragma mark - Job Locking
+ (BOOL) containsLockedJob:  (NLJob*) job;
+ (void) lockJob: (NLJob*) job;
+ (void) unlockJob: (NLJob*) job;

- (BOOL) containsLockedJob:  (NLJob*) job;
- (void) lockJob: (NLJob*) job;
- (void) unlockJob: (NLJob*) job;
- (void)unlockAllJobsOfClass: (Class) jobClass;

@property (nonatomic, readonly) NSSet *registeredJobs;
@property (nonatomic, readonly) NSSet *lockedJobs;

#pragma mark - Queue Tracking
- (void) registerQueue: (NLDelayedJob *) queue;
- (void) unregisterQueue: (NLDelayedJob *) queue;
@end