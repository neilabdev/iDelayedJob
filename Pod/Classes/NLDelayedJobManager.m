//
// Created by James Whitfield on 4/8/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//
#import "NLDelayedJobManager.h"
#import "NLJob.h"

@interface NLDelayedJobManager()
@end

@implementation NLDelayedJobManager {
    NSMutableSet * _registeredJobSet;
    NSMutableSet * _lockedJobSet;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _registeredJobSet =  [NSMutableSet set];
        _lockedJobSet = [NSMutableSet set];
    }
    return self;
}

+ (NLDelayedJobManager *)shared {
    static NLDelayedJobManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


#pragma mark - Job Locking

- (NLJob *) lockJob: (NLJob*) job {
    @synchronized (_lockedJobSet) {
        [_lockedJobSet addObject:job];
        job.locked_at  = [NSDate date];
        job.locked = [NSNumber numberWithBool:YES];
    }
    return job;
}

+ (void) lockJob: (NLJob*) job {
    [[self shared] lockJob:job];
}

- (void) unlockJob: (NLJob*) job {
    @synchronized (_lockedJobSet) {
        [_lockedJobSet removeObject:job];
        job.locked = [NSNumber numberWithBool:NO];
    }
}

+ (void) unlockJob: (NLJob*) job {
    [[self shared] unlockJob:job];
}

- (void) unlockAllJobs: (Class) jobClass {
    for(NLJob *job in [[[jobClass lazyFetcher] whereField:@"locked" equalToValue:@(YES)] fetchRecords]) {
        job.locked = @(NO);
        [job save];
    }
}


+ (BOOL) containsLockedJob:  (NLJob*) job {
    return [[self shared] containsLockedJob:job];
}

- (BOOL) containsLockedJob:  (NLJob*) job {
    @synchronized (_lockedJobSet) {
        return [_lockedJobSet containsObject:job];
    }
}

- (void) registerJob: (Class) clazz {
    @synchronized (_registeredJobSet) {
        if(![_registeredJobSet containsObject:clazz]) {
            [_registeredJobSet addObject:clazz];
            //This ensures that a stuck job, for any reason upon boot will be reset so it can be included in processing.
            [self unlockAllJobs:clazz];

        }
    }

}

+ (void) registerJob: (Class) clazz {
    [[self shared] registerJob:clazz];
}

- (NSSet *)registeredJobs {
    return _registeredJobSet;
}

+ (NSArray*) registeredJobs {
    NSSet * set  = [self shared].registeredJobs;

    return  [set allObjects];
    //  return [selregisteredJobs allObjects];
}

+ (void) registerAllJobs: (NSArray* ) jobClasses {
    for(Class clazz in jobClasses) {
        [[self shared] registerJob:clazz];
    }
}

+ (void) resetAllJobs {
    [[self shared] resetAllJobs];;
}
- (void) resetAllJobs {
    NSArray *registeredJobClasses = [_registeredJobSet allObjects];
    for(Class jobClass in registeredJobClasses) {
        [jobClass dropAllRecords];
    }
}

- (void) unlockJobs {

}

@end