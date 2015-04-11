//
// Created by ghost on 6/14/12.
//
// To change the template use AppCode | Preferences | File Templates.
//
#import "NLDelayedJob.h"
#import <objc/runtime.h>
#import "Reachability.h"
#import "JSONKit.h"
#import "MSWeakTimer.h"
#import "NLDelayedJobManager_Private.h"

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
    return [NSNumber numberWithDouble:[self timeIntervalSince1970]];
}
@end

@implementation NSNumber (NLDelayedJob)
- (NSDate *)dateWithTimeIntervalSince1970 {
    return [NSDate dateWithTimeIntervalSince1970:[self doubleValue]];
}
@end

@interface NLDelayedJob ()
@property(nonatomic, assign) BOOL hasInternet;
@property(nonatomic, retain) MSWeakTimer *timer;
@property(nonatomic, retain) Reachability *reachability;
@property(nonatomic, readonly) NSArray *allJobs;
@property (nonatomic,assign) BOOL is_paused;

- (NSArray *)findJobWhere:(NSString *)whereSQL;

- (BOOL)updateJob:(NLJob *)job;

- (BOOL)insertJob:(NLJob *)job;

- (BOOL)deleteJob:(NLJob *)job;

- (void)processJobsThreadWorker:(MSWeakTimer *)tmr;

- (void)stop;

- (NLDelayedJob *)start;
@end

@implementation NLDelayedJob {
    NSString *_queue;
}
@synthesize max_attempts;
@synthesize hasInternet;
@synthesize interval;
@synthesize host;
@synthesize timer;
@synthesize queue = _queue;
#pragma mark - Initialization
static NLDelayedJob *sharedInstance = nil;

+ (instancetype)queueWithName:(NSString *)name interval:(NSInteger)interval attemps:(NSInteger)attempts {
    return [[self alloc] initWithQueue:name interval:interval attemps:attempts];
}

- (instancetype)initWithQueue:(NSString *)name interval:(NSInteger)interval attemps:(NSInteger)attempts {
    if (self = [super init]) {
        _queue = name ? name : @"default";
        self.max_attempts = attempts > 1 ? attempts : 10;
        self.interval = interval > 1 ? interval : 2;
        self.hasInternet = YES;
        self.is_paused = NO;
        self.reachability = [Reachability reachabilityForInternetConnection];
        [VinylRecord applyConfiguration:^(ARConfiguration *config) {}];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityChanged:) name:kReachabilityChangedNotification object:self.reachability];
    }
    return self;
}

- (id)init {
    if (self = [self initWithQueue:nil interval:2 attemps:10]) {
    }
    return self;
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
        char *queue_label = [[NSString stringWithFormat:@"com.neilab.delayedjob.queue.%@", self.queue] UTF8String];
        dispatch_queue_t queue = dispatch_queue_create(queue_label, DISPATCH_QUEUE_SERIAL);
        [self stop];
        self.reachability = self.host ?
                [Reachability reachabilityWithHostname:self.host] :
                [Reachability reachabilityForInternetConnection];

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

- (void)stop {
    @synchronized (self) {
        [self.reachability stopNotifier];
        if (self.timer)
            [self.timer invalidate];
        self.timer = nil;
        self.is_paused = NO;
        [[NLDelayedJobManager shared] unregisterQueue:self];
    }
}

#pragma mark - Schedule Jobs

- (void)scheduleJob:(NLJob *)job priority:(NSInteger)priority {
    [self scheduleJob:job priority:priority internet:NO];
}

- (void)scheduleJob:(NLJob *)job priority:(NSInteger)priority internet:(BOOL)requireInternet {
    NSString *paramString = [job.params JSONString];
    job.internet = [NSNumber numberWithBool:requireInternet];
    job.parameters = paramString;
    job.queue = self.queue;
    job.job_id = [[NSUUID UUID] UUIDString];
    job.priority = @(priority);
    NSAssert(paramString != nil, @"Error serializing NLJob.parameters to JSON. Check types.");
    NSAssert([self insertJob:job], @"Unable to save job %@", job);
}
- (void)scheduleInternetJob:(NLJob *)job priority:(NSInteger)priority {
    [self scheduleJob:job priority:priority internet:YES];
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
    NLJob *nextJob = nil;
    NSInteger total_processed = 0;
    do {
        nextJob = [self nextJob];
        [self runJob:nextJob];
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

- (BOOL)updateJob:(NLJob *)job {
    if ([job.locked boolValue]) {
        [NLDelayedJobManager lockJob:job];
    } else {
        [NLDelayedJobManager unlockJob:job];
    }
    return [job save];
}

+ (void)reset {
    [[self defaultQueue] reset];
}

- (void)reset {
    [[self class] dropAllRecords];
/*
    NSArray *resetJobClasses = self.allJobs;
    for (Class jobClass in resetJobClasses) {
        [jobClass dropAllRecords];
    } */
}

#pragma mark - Job Invocation

- (BOOL)deleteJob:(NLJob *)job {
    [NLDelayedJobManager unlockJob:job];
    [job dropRecord];
    return YES;
}

- (NSArray *)allJobs {
    return [NLDelayedJobManager registeredJobs];
}

- (NLJob *)nextJob {
    NLJob *lockedJob = nil;
    @synchronized (self) {
        NSMutableArray *jobs = [NSMutableArray array];
        for (Class jobClass in self.allJobs) {
            NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970];
            NSArray *foundJobs = [[[[(jobClass) lazyFetcher] where:@"datetime(run_at,'unixepoch') <= datetime(%@,'unixepoch') and locked = 0 and queue = %@ ", @(seconds), self.queue, nil] orderBy:@"priority" ascending:NO] fetchRecords];
            if ([foundJobs count] > 0)
                [jobs addObjectsFromArray:foundJobs];
        }
        NSArray *sortedArray = // ensures sort by priority across model types
                [jobs sortedArrayUsingSelector:@selector(priorityCompare:)];
        for (NLJob *job in sortedArray) {
            if ([NLDelayedJobManager containsLockedJob:job]) {
                continue;
            }
            if ([job.internet boolValue] && !self.hasInternet) {
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

- (BOOL)runJob:(NLJob *)job {
    bool success = YES;
    if (!job) return NO;
    if (job.is_internet && !self.hasInternet)
        return NO;
    if ([job run]) {
        [job onBeforeDeleteEvent];
        success = [self deleteJob:job];
    } else if (([job.attempts intValue] > self.max_attempts) || (job.descriptor.code == kJobDescriptorCodeLoadFailure)) {
        if ([job shouldRestartJob]) {
            if (([job.attempts intValue] > self.max_attempts))
                job.attempts = [NSNumber numberWithInt:0];
            success = [self updateJob:job];
        } else {
            [job onBeforeDeleteEvent];
            success = [self deleteJob:job];
        }
    } else {
        job.locked = [NSNumber numberWithBool:NO];
        success = [self updateJob:job];
    }
    return success;
}

- (BOOL)insertJob:(NLJob *)job {
    if (job.is_unique) {
        NSArray *priorJobs = [[[[job class] lazyFetcher] where:@"handler = %@ and locked = 0 and queue = %@", job.handler, self.queue, nil] fetchRecords];
        for (NLJob *current_job in priorJobs) {
            [self deleteJob:current_job];
        }
    }
    return [job save];
}

- (NSArray *)findJobWhere:(NSString *)whereSQL {
    NSMutableArray *jobs = [NSMutableArray array];
    NSString *whereQuery = [NSString stringWithFormat:@"%@ and queue = '%@'", whereSQL, self.queue];
    for (Class jobClass in self.allJobs) {
        NSArray *foundJobs = [[[(jobClass) lazyFetcher] where:whereQuery, nil] fetchRecords];
        if ([foundJobs count] > 0)
            [jobs addObjectsFromArray:foundJobs];
    }
    return jobs;
}

#pragma mark - UIApplication Events

- (void)onReachabilityChanged:(NSNotification *)notification {
    Reachability *reach = [notification object];
    NSParameterAssert([reach isKindOfClass:[Reachability class]]);
    switch (reach.currentReachabilityStatus) {
        case ReachableViaWWAN:
        case ReachableViaWiFi:
            self.hasInternet = YES;
            break;
        case NotReachable:
            self.hasInternet = NO;
            break;
        default:
            break;
    } //switch
}

- (void)onAppWillResignActive {
    //  NSLog(@"%@.onAppWillResignActive", self);
    [self pause];
}

- (void)onAppWillTerminate {
    // NSLog(@"%@.onAppWillTerminate", self);
    [self stop];
}

- (void)onAppDidBecomeActive {
    // NSLog(@"%@.onAppDidBecomeActive", self);
    [self resume];
}

- (void)onAppWillEnterForeground {
    // LOG(@"%@.onAppWillEnterForeground", self);
    [self resume];
}

#pragma mark - Deallocation

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.reachability = nil;
    [self.timer invalidate];
    self.timer = nil;
}
@end