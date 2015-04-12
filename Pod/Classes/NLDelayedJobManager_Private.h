//
//  NLDelayedJobManager_private.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
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

+ (BOOL)containsLockedJob:(NLDelayableJob *)job;

+ (void)lockJob:(NLDelayableJob *)job;

+ (void)unlockJob:(NLDelayableJob *)job;

- (BOOL)containsLockedJob:(NLDelayableJob *)job;

- (void)lockJob:(NLDelayableJob *)job;

- (void)unlockJob:(NLDelayableJob *)job;

- (void)unlockAllJobsOfClass:(Class)jobClass;

#pragma mark - Queue Tracking

- (void)registerQueue:(NLDelayedJob *)queue;

- (void)unregisterQueue:(NLDelayedJob *)queue;
@end