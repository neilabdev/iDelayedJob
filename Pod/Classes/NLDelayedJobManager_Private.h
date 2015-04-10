//
// Created by James Whitfield on 4/10/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLDelayedJobManager.h"

@interface NLDelayedJobManager()
#pragma mark - Job Locking
+ (BOOL) containsLockedJob:  (NLJob*) job;
+ (void) lockJob: (NLJob*) job;
+ (void) unlockJob: (NLJob*) job;

- (BOOL) containsLockedJob:  (NLJob*) job;
- (void) lockJob: (NLJob*) job;
- (void) unlockJob: (NLJob*) job;

@property (nonatomic, readonly) NSSet *registeredJobs;
@property (nonatomic, readonly) NSSet *lockedJobs;
@end