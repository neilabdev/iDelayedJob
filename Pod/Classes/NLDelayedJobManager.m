//
//  NLDelayedJobManager.m
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//
#import "NLDelayedJobManager.h"
#import "NLJob.h"
#import "NLDelayedJob.h"

@interface NLDelayedJobManager()
@end

@implementation NLDelayedJobManager {
    NSMutableSet * _registeredJobSet;
    NSMutableSet * _lockedJobSet;
    NSMutableSet * _activeQueueSet;
    NSMutableDictionary *_activeQueueMap;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _registeredJobSet =  [NSMutableSet set];
        _lockedJobSet = [NSMutableSet set];
        _activeQueueSet = [NSMutableSet set];
        _activeQueueMap = [NSMutableDictionary dictionary];
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

- (void)unlockAllJobsOfClass: (Class) jobClass {
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

#pragma mark - Job Class Management

- (void) registerJob: (Class) clazz {
    @synchronized (_registeredJobSet) {
        if(![_registeredJobSet containsObject:clazz]) {
            [_registeredJobSet addObject:clazz];
            //This ensures that a stuck job, for any reason upon boot will be reset so it can be included in processing.
            [self unlockAllJobsOfClass:clazz];

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
    NSSet * set  = [[self shared] registeredJobs];
    return  [set allObjects];
}

#pragma mark - Queue Management

+ (void) registerAllJobs: (NSArray* ) jobClasses {
    for(Class clazz in jobClasses) {
        [[self shared] registerJob:clazz];
    }
}


+ (void) resetAllJobs {
    [[self shared] resetAllJobs];
}

- (void) resetAllJobs {
    NSArray *registeredJobClasses = [_registeredJobSet allObjects];
    for(Class jobClass in registeredJobClasses) {
        [jobClass dropAllRecords];
    }
}


- (void) registerQueue: (NLDelayedJob *) delayedJob {
    @synchronized (_activeQueueSet) {
        [_activeQueueSet addObject:delayedJob];
        NSAssert([_activeQueueMap objectForKey:delayedJob.queue]==nil,@"Attepting to register a delayed job with an existing queue named: %@",delayedJob.queue);
        [_activeQueueMap setObject:delayedJob forKey:delayedJob.queue];
    }
}

- (NLJob*) scheduleJob: (NLJob*) job queue: (NSString*) name priority: (NSInteger) priority internet: (BOOL) internet {
    NSString *queueName = name ? name : @"default";
    NLDelayedJob *delayedJob = [_activeQueueMap objectForKey:queueName];
    NSAssert(delayedJob,@"Unable to locate delayed job with queue named %@",queueName);
    return [delayedJob scheduleJob:job priority:priority internet:internet];
}


- (void) unregisterQueue: (NLDelayedJob *) delayedJob {
    @synchronized (_activeQueueSet) {
        [_activeQueueSet removeObject:delayedJob];
        [_activeQueueMap removeObjectForKey:delayedJob.queue];
    }
}

- (void) shutdown {
    @synchronized (_activeQueueSet) {
        NSArray *jobs = [_activeQueueSet allObjects];
        for(NLDelayedJob *job in jobs) {
            [job stop];
        }
        [_activeQueueMap removeAllObjects];
        [_activeQueueSet removeAllObjects];
        [_lockedJobSet removeAllObjects];
    }
}

- (void) pause {
    @synchronized (_activeQueueSet) {
        NSArray *jobs = [_activeQueueSet allObjects];
        for(NLDelayedJob *job in jobs) {
            [job pause];
        }
    }
}

- (void) resume {
    @synchronized (_activeQueueSet) {
        NSArray *jobs = [_activeQueueSet allObjects];
        for(NLDelayedJob *job in jobs) {
            [job resume];
        }
    }
}
@end