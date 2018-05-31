//
//  NLDelayedJobManager.m
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//
#import "NLDelayedJobManager.h"
#import "NLDelayableJob.h"
#import "NLDelayedJob.h"

@interface NLDelayedJobManager()

+ (void) prepareJob: (Class) clazz;
- (void) prepareAllJobs;

@end

@implementation NLDelayedJobManager {
    NSMutableSet * _registeredJobSet;
    NSMutableSet * _lockedJobSet;
    NSMutableSet * _activeQueueSet;
    NSMutableDictionary *_activeQueueMap;
    NSMutableSet * _lazyUnlockJobSet;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _registeredJobSet =  [NSMutableSet set];
        _lockedJobSet = [NSMutableSet set];
        _activeQueueSet = [NSMutableSet set];
        _lazyUnlockJobSet = [NSMutableSet set];
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

- (NLDelayableJob *) lockJob: (NLDelayableJob *) job {
    @synchronized (_lockedJobSet) {
        [_lockedJobSet addObject:job];
        job.locked_at  = [NSDate date];
        job.locked = @(YES);
    }
    return job;
}

+ (void) lockJob: (NLDelayableJob *) job {
    [[self shared] lockJob:job];
}

- (void) unlockJob: (NLDelayableJob *) job {
    @synchronized (_lockedJobSet) {
        [_lockedJobSet removeObject:job];
        job.locked = @(NO);
    }
}

+ (void) unlockJob: (NLDelayableJob *) job {
    [[self shared] unlockJob:job];
}

- (void)unlockAllJobsOfClass: (Class) jobClass {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
    for(NLDelayableJob *job in [[[jobClass lazyFetcher] whereField:@"locked" equalToValue:@(YES)] fetchRecords]) {
        job.locked = @(NO);
        [job save];
    }
#pragma clang diagnostic pop
}


+ (BOOL) containsLockedJob:  (NLDelayableJob *) job {
    return [[self shared] containsLockedJob:job];
}

- (BOOL) containsLockedJob:  (NLDelayableJob *) job {
    @synchronized (_lockedJobSet) {
        return [_lockedJobSet containsObject:job];
    }
}

#pragma mark - Job Class Management


+ (void) prepareJob: (Class) clazz {
    [[self shared] prepareJob:clazz];
}

- (void) prepareJob: (Class<NLJob>) clazz {
    if(![clazz conformsToProtocol:@protocol(NLJob)])
        NSAssert(nil,@"registering a class %@ that is not a job or does not conform to protocol <NLJob>", NSStringFromClass(clazz));

    if([_lazyUnlockJobSet containsObject:clazz]) {
        [_lazyUnlockJobSet removeObject:clazz];
        [self unlockAllJobsOfClass:clazz];
    }
}

- (void) prepareAllJobs {
    NSArray *_lazyUnlockableJobs = [_lazyUnlockJobSet allObjects];
    for(Class <NLJob> clazz in _lazyUnlockableJobs) {
        [self prepareJob:clazz];
    }
}


- (void) registerJob: (Class<NLJob>) clazz {
    @synchronized (_registeredJobSet) {
        if(![clazz conformsToProtocol:@protocol(NLJob)])
            NSAssert(nil,@"registering a class %@ that is not a job or does not conform to protocol <NLJob>", NSStringFromClass(clazz));
        if(![_registeredJobSet containsObject:clazz]) {
            [_registeredJobSet addObject:clazz];
            //This ensures that a stuck job, for any reason upon boot will be reset so it can be included in processing.
            // [self unlockAllJobsOfClass:clazz]; //TODO: Trigger DB callls before database initialized
            [_lazyUnlockJobSet addObject:clazz];

        }
    }
}

+ (void) registerJob: (Class) clazz {
    [[self shared] registerJob:clazz];
}

- (NSArray*) registeredJobs {
    return [_registeredJobSet allObjects];
}

+ (NSArray*) registeredJobs {
    return  [[self shared] registeredJobs];;
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
        NSString *className = NSStringFromClass(jobClass);
        if(![jobClass isSubclassOfClass:[NLDelayableJob class]])
            NSAssert(nil,@"Class %@ is not a subclass of NLDelaybableJob",className);
        [jobClass dropAllRecords];
    }
}

- (void) registerQueue: (NLDelayedJob *) delayedJob {
    @synchronized (_activeQueueSet) {
        if([_activeQueueSet count] == 0) { //presumed to be when work is actually about to be done, which means app loaded
            [self prepareAllJobs];
        }

        [_activeQueueSet addObject:delayedJob];
        NSAssert([_activeQueueMap objectForKey:delayedJob.queue]==nil,@"Attepting to register a delayed job with an existing queue named: %@",delayedJob.queue);
        [_activeQueueMap setObject:delayedJob forKey:delayedJob.queue];
    }
}

- (void) unregisterQueue: (NLDelayedJob *) delayedJob {
    @synchronized (_activeQueueSet) {
        [_activeQueueSet removeObject:delayedJob];
        [_activeQueueMap removeObjectForKey:delayedJob.queue];
    }
}

#pragma mark -
- (NLDelayableJob *) scheduleJob: (NLDelayableJob *) job queue: (NSString*) name priority: (NSInteger) priority internet: (BOOL) internet {
    NSString *queueName = name ? name : @"default";
    NLDelayedJob *delayedJob =  _activeQueueMap[queueName];
    if(!delayedJob) //allows breakpoint at next line
        NSAssert(delayedJob,@"Unable to locate delayed job with queue named %@",queueName);
    return [delayedJob scheduleJob:job priority:priority internet:internet];
}

- (NLDelayedJob *) delayedJobQueue: (NSString*) name {
    NLDelayedJob *delayedJob = _activeQueueMap[name];
    return delayedJob;
}

- (NSArray*) allDelayableJobs {
    NSMutableArray *jobs = [NSMutableArray array];

    NSArray *registeredJobClasses = [_registeredJobSet allObjects];
    for(Class jobClass in registeredJobClasses) {
        NSString *className = NSStringFromClass(jobClass);
        if(![jobClass isSubclassOfClass:[NLDelayableJob class]])
            NSAssert(nil,@"Class %@ is not a subclass of NLDelaybableJob",className);
       // [(NLDelayedJob)jobClass ]
        NSArray *results =  [jobClass allRecords];//  [[[VinylRecord lazyFetcher] where:@" ", nil] fetchRecords];

        if(results && [results count]>0)
            [jobs addObjectsFromArray:results];

    }
    return jobs;
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