//
//  NLJob.m
//  infowars
//
//  Created by James Whitfield on 06/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <JSONKit-NoWarning/JSONKit.h>
#import "NLJob.h"


@implementation NLJobDescriptor {}
@synthesize code = _code;
@synthesize error = _error;

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

@implementation NLJob
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
column_imp(integer, job_id)

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

    if ([jobClazz isSubclassOfClass:[self class]]) {
        job = [jobClazz new];
    } else if ([jobClazz conformsToProtocol:@protocol(NLJobsAbility)]) {
        job = [self new];     // will use static protocal method
        job.handler = className;
    } else {
        NSAssert(NO, @"Job class must be either a subclass or NLJob or implement protocol <NLJobsAbility>");
    }

    if (job && firstObject) {
        id finalObject = nil;
        [job.params addObject:(firstObject ? firstObject : [NSNull null])];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while (eachObject = va_arg(argumentList, id)) {
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
    if (firstObject) {                                   // so we'll handle it separately.
        // [self addObject: firstObject];

        [job.params addObject:firstObject ? firstObject : [NSNull null]];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while (eachObject = va_arg(argumentList, id)) {
            [job.params addObject:eachObject];
        } // As many times as we can get an argument of type "id"

        va_end(argumentList);
    }

    return job;
}


+ (id)encodeParam:(id)param {

    id finalObject = nil;
    if ([param isKindOfClass:[NSDate class]]) {
        finalObject = [NSNumber numberWithInteger:(int) [((NSDate *) finalObject) timeIntervalSince1970]];
    } else if ([param isKindOfClass:[NSData class]]) {

    }
    return finalObject;
}

- (NLJob *)setArguments:(id)firstObject, ... {
    id eachObject;
    va_list argumentList;
    if (firstObject) {                                   // so we'll handle it separately.
        // [self addObject: firstObject];
        [self.params addObject:firstObject ? firstObject : [NSNull null]];
        va_start(argumentList, firstObject); // Start scanning for arguments after firstObject.
        while (eachObject = va_arg(argumentList, id)) {
            [self.params addObject:eachObject];
            //[self addObject: eachObject]; // that isn't nil, add it to self's contents.
        } // As many times as we can get an argument of type "id"
        va_end(argumentList);
    }

    return self;
}


- (BOOL)run {
    Class <NLJobsAbility> jobClass = NSClassFromString(self.handler);
    BOOL success = NO;

    if (self.handler && [self.handler isEqualToString:NSStringFromClass([self class])]) {
        success = [self perform];
    } else if ([jobClass conformsToProtocol:@protocol(NLJobsAbility)] && [jobClass respondsToSelector:@selector(performJob:withArguments:)]) {
        success = [jobClass performJob:self.descriptor withArguments:self.params];
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
        self.attempts = [NSNumber numberWithInt:[self.attempts intValue] + 1];
        self.descriptor.code = kJobDescriptorCodeRunFailure;
    }

    return success;
}


- (BOOL)shouldRestartJob {
    return NO;
}

- (void)onBeforeDeleteEvent {

}

- (BOOL)perform {
    self.descriptor.error = @"Unimplemented perform method";
    self.descriptor.code = kJobDescriptorCodeRunFailure;
    return NO;
}


#pragma mark - Equaility

- (BOOL)isEqual:(id)anObject {
    return anObject && [anObject isKindOfClass:[self class]] && [self.job_id isEqualToNumber:((NLJob *) anObject).job_id];
}

- (NSUInteger)hash {
    return [self.job_id hash];
}

#pragma mark - Deallocation

- (void)dealloc {
    self.params = nil;
}

@end


