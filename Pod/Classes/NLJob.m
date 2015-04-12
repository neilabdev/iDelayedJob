//
//  NLJob.m
//  infowars
//
//  Created by James Whitfield on 06/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JSONKit.h"
#import "NLJob.h"
#import "NLDelayedJobManager.h"
#import "NLDelayedJobManager_Private.h"

@implementation NLJobDescriptor {}
@synthesize code = _code;
@synthesize error = _error;
@synthesize job = _job;

- (id)initWithJob:(NLJob *)job {
    if (self = [super init]) {
        _job = job;
    }
    return self;
}

- (void)setError:(NSString *)message {
    _job.last_error = message;
}

@end

@interface  NLJob ()
- (NSComparisonResult)priorityCompare:(NLJob *)job;
@end

@implementation NLJob {
    NSMutableArray *_params;
    NLJobDescriptor *_descriptor;
}
+ (void)initialize {
    [super initialize];
    NSString *className = NSStringFromClass([self class]); //forDebugging
    [NLDelayedJobManager registerJob:[self class]];
}

column_imp(string, handler)
column_imp(string, queue)
column_imp(string, parameters)
column_imp(integer, priority)
column_imp(integer, attempts)
column_imp(string, last_error)
column_imp(date, run_at)
column_imp(date, locked_at)
column_imp(boolean, locked)
column_imp(date, failed_at)
column_imp(boolean, internet)
column_imp(boolean, unique)
column_imp(string, job_id)

validation_do(
        validate_presence_of(handler)
        validate_presence_of(queue)
        validate_presence_of(attempts)
        validate_presence_of(job_id)
        validate_presence_of(priority)
)

@synthesize params = _params;
@synthesize descriptor = _descriptor;

- (id)init {
    if (self = [super init]) {
        self.handler = NSStringFromClass([self class]);
        self.locked = [NSNumber numberWithBool:NO];
        self.run_at = [NSDate date];
        self.attempts = [NSNumber numberWithInt:0];
        self.priority = [NSNumber numberWithInt:1];
        self.internet = [NSNumber numberWithBool:NO];
        self.unique = [NSNumber numberWithBool:NO];
        _descriptor = [[NLJobDescriptor alloc] initWithJob:self];
    }

    return self;
}


- (void)setParams:(NSMutableArray *)params {
    _params = params;
}

- (NSMutableArray *)params {
    if (!_params) {
        _params = [NSMutableArray arrayWithCapacity:1];
        if (self.parameters) {
            NSArray *array = [self.parameters objectFromJSONString];
            [_params addObjectsFromArray:array];
        }
    }

    return _params;
}

+ (id)jobWithClass:(Class <NLJobsAbility>)jobClass {
    return [self jobWithHandler:NSStringFromClass(jobClass) arguments:nil];;
}

+ (NLJob *)jobWithHandler:(NSString *)className {
    return [self jobWithHandler:className arguments:nil];
}

+ (NLJob *)jobWithHandler:(NSString *)className arguments:(id)firstObject, ... {
    Class jobClazz = NSClassFromString(className);
    NLJob *job = nil;
    va_list argumentList;
    id eachObject;

    NSAssert(className != nil, @"A job cannot be created with a null class name.");
    NSAssert(jobClazz != nil, @"Cannot find class %@ to create job", className);

    if ([jobClazz isSubclassOfClass:[NLJob class]]) {
        job = [jobClazz new];
    } else if ([jobClazz conformsToProtocol:@protocol(NLJobsAbility)]) {
        job = [self new];     // will use static protocal method
        job.handler = className;
    } else {
        NSAssert(NO, @"Job class must be either a subclass or NLJob or implement protocol <NLJobsAbility>");
    }

    if (job && firstObject) {
        [job.params addObject:(firstObject ? firstObject : [NSNull null])];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [job.params addObject:eachObject];
        } // As many times as we can get an argument of type "id"

        va_end(argumentList);
    }

    return job;
}


+ (NLJob *)jobWithArguments:(id)firstObject, ... {

    NLJob *job = [[self alloc] init];
    va_list argumentList;
    id eachObject;
    if (firstObject) {
        [job.params addObject:firstObject ? firstObject : [NSNull null]];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [job.params addObject:eachObject];
        }
        va_end(argumentList);
    }

    return job;
}

- (NLJob *)setArguments:(id)firstObject, ... {
    id eachObject;
    va_list argumentList;
    if (firstObject) {                                   // so we'll handle it separately.
        // [self addObject: firstObject];
        [self.params addObject:firstObject ? firstObject : [NSNull null]];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while ((eachObject = va_arg(argumentList, id))) {
            [self.params addObject:eachObject];
        } // As many times as we can get an argument of type "id"
        va_end(argumentList);
    }
    return self;
}


- (BOOL)run {
    NLJob *jobSubclass = [self __ifJobSubclass]; //returns self
    Class <NLJobsAbility> jobsAbilityClass = !jobSubclass ? [self __ifAbilityJob] : nil;
    BOOL success = NO;
    BOOL isAbility = NO;

    if (jobSubclass) {
        success = [self perform];
    } else if ([jobsAbilityClass respondsToSelector:@selector(performJob:withArguments:)]) {
        isAbility = YES;
        success = [jobsAbilityClass performJob:self.descriptor withArguments:self.params];
    } else {
        self.descriptor.code = kJobDescriptorCodeLoadFailure;
        self.descriptor.error = [NSString stringWithFormat:@"Unable to load job handler %@", self.handler];
        return NO;
    }

    if (!success) {
        self.failed_at = [NSDate date];
        NSInteger add_seconds = ([self.attempts intValue] + 5) * 4;
        NSDate *nextRunTime = [NSDate dateWithTimeIntervalSinceNow:(int) add_seconds];
        self.run_at = nextRunTime;

        if (isAbility &&
                [jobsAbilityClass respondsToSelector:@selector(scheduleJob:withArguments:)]) {
            nextRunTime = [jobsAbilityClass scheduleJob:self.descriptor withArguments:self.params];
            if (nextRunTime)
                self.run_at = nextRunTime;
        }

        self.attempts = [NSNumber numberWithInt:[self.attempts intValue] + 1];
        self.descriptor.code = kJobDescriptorCodeRunFailure;
    }

    return success;
}


#pragma mark - Job Helpers

- (NLJob *) __ifJobSubclass { // determines if job is a subclass of NLJob which handles itself for processing
     if (self.handler &&
             [self.handler isEqualToString:NSStringFromClass([self class])]) {
        return self;
    }
    return nil;
}

- (Class <NLJobsAbility>) __ifAbilityJob { //determines if Job is handled by NLJobsAbility class
    Class jobClass = NSClassFromString(self.handler);
    Class <NLJobsAbility> jobsAbilityClass = [jobClass conformsToProtocol:@protocol(NLJobsAbility)] ? jobClass : nil;
    if ([self __ifJobSubclass]) {
        return nil;
    } else if (jobsAbilityClass && [jobClass respondsToSelector:@selector(performJob:withArguments:)]) {
        return jobsAbilityClass;
    }
    return nil;
}

#pragma mark -

- (BOOL)shouldRestartJob { // No Need to call super if subclassed
    Class <NLJobsAbility> jobsAbilityClass = [self __ifAbilityJob];

    if(jobsAbilityClass &&
            [jobsAbilityClass respondsToSelector:@selector(shouldRestartJob:withArguments:)]) {
        return [jobsAbilityClass shouldRestartJob:self.descriptor withArguments:self.params];
    }

    return NO;
}

- (void)onBeforeDeleteEvent {  // No Need to call super if subclassed
    Class <NLJobsAbility> jobsAbilityClass = [self __ifAbilityJob];
    if(jobsAbilityClass &&
            [jobsAbilityClass respondsToSelector:@selector(shouldRestartJob:withArguments:)]) {
         [jobsAbilityClass beforeDeleteJob:self.descriptor withArguments:self.params];
    }
}

- (BOOL)perform {
    self.descriptor.error = @"Unimplemented perform method";
    self.descriptor.code = kJobDescriptorCodeRunFailure;
    return NO;
}

#pragma mark - Equality & Sorting

- (BOOL)isEqual:(id)anObject {
    return anObject && [anObject isKindOfClass:[self class]] && [self.job_id isEqualToString:((NLJob *) anObject).job_id];
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + [self.queue hash];
    result = prime * result + [self.job_id hash];
    return result;
}

- (NSComparisonResult)priorityCompare:(NLJob *)job {
    if (job == nil) {
        return NSOrderedAscending;
    }

    return [job.priority compare:self.priority];
}


#pragma mark - Deallocation

- (void)dealloc {
    self.params = nil;
}

@end


