//
//  NLDelayedJob.m
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLDelayedJob.h"
#import "Reachability.h"
#import "JSONKit.h"
#import "MSWeakTimer.h"
#import "NLDelayedJobManager_Private.h"
#import "NLDelayableJobAbility.h"

@implementation NLDelayedJobConfiguration
@synthesize interval, host, hasInternet, max_attempts, queue;
@end

@interface NSDate (NLDelayedJob)
- (NSNumber *)numberWithTimeIntervalSince1970;
@end

@interface NSNumber (NLDelayedJob)
- (NSDate *)dateWithTimeIntervalSince1970;
@end

@implementation NSDate (NLDelayedJob)
- (NSNumber *)numberWithTimeIntervalSince1970 {
    return @([self timeIntervalSince1970]);
}
@end

@implementation NSNumber (NLDelayedJob)
- (NSDate *)dateWithTimeIntervalSince1970 {
    return [NSDate dateWithTimeIntervalSince1970:[self doubleValue]];
}
@end

@interface NLDelayedJob ()
@property(nonatomic, assign) BOOL hasInternet;
@property(nonatomic, assign) BOOL hasWifi;
@property(nonatomic, retain) MSWeakTimer *timer;
@property(nonatomic, retain) Reachability *reachability;
@property(nonatomic, readonly) NSArray *allJobClasses;
@property (nonatomic,assign) BOOL is_paused;

- (NSArray *)findJobWhere:(NSString *)whereSQL;

- (BOOL)updateJob:(NLDelayableJob *)job;

- (BOOL)insertJob:(NLDelayableJob *)job;

- (BOOL)deleteJob:(NLDelayableJob *)job;

- (void)processJobsThreadWorker:(MSWeakTimer *)tmr;

- (void)stop;

- (NLDelayedJob *)start;
@end

@implementation NLDelayedJob {
    NSString *_queue;
}
@synthesize max_attempts;
@synthesize hasInternet;
@synthesize hasWifi;
@synthesize interval;
@synthesize host;
@synthesize timer;
@synthesize queue = _queue;
#pragma mark - Initialization
static NLDelayedJob *sharedInstance = nil;

+ (instancetype)queueWithName:(NSString *)name interval:(NSTimeInterval)seconds attemps:(NSInteger)attempts {
    return [[self alloc] initWithQueue:name interval:seconds attemps:attempts];
}

- (instancetype)initWithQueue:(NSString *)name interval:(NSTimeInterval)seconds attemps:(NSInteger)attempts {
    if (self = [super init]) {
        _queue = name ? name : @"default";
        self.max_attempts = attempts > 1 ? attempts : 10;
        self.interval = seconds > 1 ? seconds : 2;
        self.hasInternet = YES;
        self.hasWifi = NO;
        self.is_paused = NO;
    //    self.reachability = [Reachability reachabilityForInternetConnection];
        [VinylRecord applyConfiguration:^(ARConfiguration *config) {}];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}

- (id)init {
    if (self = [self initWithQueue:nil interval:2 attemps:10]) {
    }
    return self;
}

+ (void) dropAllRecords {
    NSLog(@"woops");
}

+ (NLDelayedJob *)defaultQueue {
    static NLDelayedJob *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (NLDelayedJobManager *)sharedManager {
    return [NLDelayedJobManager shared];
}

#pragma mark - Service Management

+ (NLDelayedJob *)configure:(NLDelayedJobConfigurationBlock)configBlock {
    NLDelayedJobConfiguration *configuration = [[NLDelayedJobConfiguration alloc] init];
    NLDelayedJob *delayedJob = nil;
    configBlock(configuration);
    delayedJob = [[self alloc] initWithQueue:configuration.queue
                                    interval:configuration.interval
                                     attemps:configuration.max_attempts];
    delayedJob.host = configuration.host;
    return delayedJob;
}

- (NLDelayedJob *)start {
    @synchronized (self) {
        const char *queue_label = [[NSString stringWithFormat:@"com.neilab.delayedjob.queue.%@", self.queue] UTF8String];
        dispatch_queue_t queue = dispatch_queue_create(queue_label, DISPATCH_QUEUE_SERIAL);
        [self _cleanup];
        self.reachability = self.host ?
                [Reachability reachabilityWithHostname:self.host] :
                [Reachability reachabilityForInternetConnection];

        __block NLDelayedJob *this = self;
        self.reachability.reachableBlock =^(Reachability*reach) {

            this.hasInternet = YES;
            this.hasWifi = reach.isReachableViaWiFi;
        };

        self.reachability.unreachableBlock = ^(Reachability*reach)
        {
            this.hasInternet = NO;
            this.hasWifi = NO;
        };


        [self.reachability startNotifier];

        self.timer = [MSWeakTimer scheduledTimerWithTimeInterval:self.interval
                                                          target:self
                                                        selector:@selector(processJobsThreadWorker:)
                                                        userInfo:nil
                                                         repeats:YES
                                                   dispatchQueue:queue];
        [[NLDelayedJobManager shared] registerQueue:self];
    }

    return self;
}
- (void)_cleanup {
    [self.reachability stopNotifier];
    [self.timer invalidate];
    self.timer = nil;
    self.reachability = nil;
    self.is_paused = NO;
}
- (void)stop {
    @synchronized (self) {
       [self _cleanup];
        [[NLDelayedJobManager shared] unregisterQueue:self];
    }
}

#pragma mark - Schedule Jobs

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority {
    return [self scheduleJob:jobOrClass priority:priority internet:NO];
}

- (NLDelayableJob *)scheduleInternetJob:(id) jobOrClass priority:(NSInteger)priority {
    return [self scheduleJob:jobOrClass priority:priority internet:YES];
}

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority internet:(BOOL)requireInternet {
    return [self scheduleJob:jobOrClass priority:priority internet:requireInternet wifi: NO ];
}

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority wifi:(BOOL)requireInternet {
    return [self scheduleJob:jobOrClass priority:priority internet:YES wifi: requireInternet ];
}

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority internet:(BOOL)requireInternet wifi: (BOOL) requiresWifi {
    NLDelayableJob *job = [self _detectJob:jobOrClass];
    NSString *paramString = [job.params JSONString];
    BOOL success = NO;
    job.internet = @(requireInternet);
    job.wifi = @(requiresWifi);
    job.parameters = paramString;
    job.queue = self.queue;
    job.job_id = [[NSUUID UUID] UUIDString];
    job.priority = @(priority);
    success = [self insertJob:job];
    NSAssert(paramString != nil, @"Error serializing NLDelayableJob.parameters to JSON. Check types.");
    NSAssert(success, @"Unable to save job %@", job);
    return job;
}

- (NLDelayableJob *) _detectJob: (id) jobOrClass {

    NSAssert([jobOrClass conformsToProtocol:@protocol(NLJob)], @"jobOrClass parameter does not subclass or implement a protocol <NLJob>");

    if(class_isMetaClass(object_getClass(jobOrClass))) {
        Class jobClass = jobOrClass;

        if(![jobClass conformsToProtocol:@protocol(NLDelayableJobAbility)])
            return (NLDelayableJob*)[jobClass record];

        return [NLDelayableJob jobWithClass:jobClass];
    }
    return jobOrClass;
}

- (NSArray *)activeJobs {
    return [self findJobWhere:@"locked = 0"];
}

- (void) resume {
    self.is_paused = NO;
}

- (void) pause {
    self.is_paused = YES;
}

- (NSInteger)run {
    return [self processJobsUpToMaximum:-1];
}

- (NSInteger)processJobsUpToMaximum:(NSInteger)maximum {
    NSInteger qty = maximum < 0 ? LONG_MAX : maximum > 0 ? maximum : 1;
    NLDelayableJob *nextJob = nil;
    NSInteger total_processed = 0;
    do {
        nextJob = [self nextJob];
        [self workJob:nextJob];
        if (nextJob)
            total_processed++;
    } while (--qty && nextJob);
    return total_processed;
}

#pragma mark - Job Worker

- (void)processJobsThreadWorker:(MSWeakTimer *)tmr {
    if(!self.is_paused)
        [self processJobsUpToMaximum:1];
}

- (BOOL)updateJob:(NLDelayableJob *)job {
    if ([job.locked boolValue]) { //FIXME: Works, but logic seems bad
        [NLDelayedJobManager lockJob:job];
    } else {
        [NLDelayedJobManager unlockJob:job];
    }
    return [job save];
}

- (void)reset {
    NSArray *resetJobClasses = self.allJobClasses;
    for (Class jobClass in resetJobClasses) {
        [jobClass dropAllRecords];
    }
}

#pragma mark - Job Invocation

- (BOOL)deleteJob:(NLDelayableJob *)job {
    [NLDelayedJobManager unlockJob:job];
    [job dropRecord];
    return YES;
}

- (NSArray *)allJobClasses {
    NSArray *jobClasses = [NLDelayedJobManager registeredJobs];

    return jobClasses;
}

- (NSArray*)allScheduledJobs {
    NSMutableArray *jobs = [NSMutableArray array];

    for (Class jobClass in self.allJobClasses) {
        NSArray *foundJobs = [[[[(jobClass) lazyFetcher] where:@"queue = %@ ",self.queue, nil] orderBy:@"priority" ascending:NO] fetchRecords];
        if ([foundJobs count] > 0)
            [jobs addObjectsFromArray:foundJobs];
    }

    return jobs;
}


- (NLDelayableJob *)nextJob {
    NLDelayableJob *lockedJob = nil;
    @synchronized (self) {
        NSMutableArray *jobs = [NSMutableArray array];
        for (Class jobClass in self.allJobClasses) {
            NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970];
            NSArray *foundJobs = [[[[(jobClass) lazyFetcher] where:@"datetime(run_at,'unixepoch') <= datetime(%@,'unixepoch') and locked = 0 and queue = %@ ", @(seconds), self.queue, nil] orderBy:@"priority" ascending:NO] fetchRecords];
            if ([foundJobs count] > 0)
                [jobs addObjectsFromArray:foundJobs];
        }
        NSArray *sortedArray = // ensures sort by priority across model types
                [jobs sortedArrayUsingSelector:@selector(priorityCompare:)];
        for (NLDelayableJob *job in sortedArray) {
            if ([NLDelayedJobManager containsLockedJob:job]) {
                continue;
            }
            if (([job.internet boolValue] && !self.hasInternet ) ||
                    ([job.wifi boolValue] && !self.hasWifi)) {
                [self updateJob:job];  //effectively places job at end of queue.
                continue;
            }
            job.locked = @(YES);
            if ([self updateJob:job]) {
                lockedJob = job;
                break;
            }
        }    //for(NLJOb)
    }       //synchronized
    return lockedJob;
}

- (BOOL)workJob:(NLDelayableJob *)job {
    bool success = YES;
    if (!job) return NO;
    if (job.is_internet && !self.hasInternet)
        return NO;
    if(job.is_wifi && !self.hasWifi)
        return NO;
    if ([job run]) {
        [job onBeforeDeleteEvent];
        success = [self deleteJob:job];
        if(success) {
            [job onAfterDeleteEvent];
            [job onCompleteEvent];
        }
    } else if (([job.attempts intValue] > self.max_attempts) || (job.descriptor.code == kJobDescriptorCodeLoadFailure)) {
        if ([job shouldRestartJob]) {
            if (([job.attempts intValue] > self.max_attempts))
                job.attempts = @(0);
            job.locked = @(NO);
            success = [self updateJob:job];
        } else {
            [job onBeforeDeleteEvent];
            success = [self deleteJob:job];
            if(success) {
                [job onAfterDeleteEvent];
            }
        }
    } else {
        job.locked = @(NO);
        success = [self updateJob:job];
    }

    return success;
}

- (BOOL)insertJob:(NLDelayableJob *)job {
    if (job.is_unique) {
        NSArray *priorJobs = [[[[job class] lazyFetcher] where:@"handler = %@ and locked = 0 and queue = %@", job.handler, self.queue, nil] fetchRecords];
        for (NLDelayableJob *current_job in priorJobs) {
            [self deleteJob:current_job];
        }
    }
    return [job save];
}

- (NSArray *)findJobWhere:(NSString *)whereSQL {
    NSMutableArray *jobs = [NSMutableArray array];
    NSString *whereQuery = [NSString stringWithFormat:@"%@ and queue = '%@'", whereSQL, self.queue];
    for (Class jobClass in self.allJobClasses) {
        NSArray *foundJobs = [[[(jobClass) lazyFetcher] where:whereQuery, nil] fetchRecords];
        if ([foundJobs count] > 0)
            [jobs addObjectsFromArray:foundJobs];
    }
    return jobs;
}

#pragma mark - UIApplication Events

- (void)onAppWillResignActive {
    [self pause];
}

- (void)onAppWillTerminate {
    [self stop];
}

- (void)onAppDidBecomeActive {
    [self resume];
}

- (void)onAppWillEnterForeground {
    [self resume];
}

#pragma mark - cleanup

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _cleanup];
    self.reachability = nil;
    self.timer = nil;
    self.host = nil;
    _queue = nil;
}
@end