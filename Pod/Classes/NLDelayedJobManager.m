//
// Created by James Whitfield on 4/8/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLJob.h"
#import "NLDelayedJobManager.h"
#import "VinylRecord.h"
#import "class_getSubclasses.h"

@interface NLDelayedJobManager()

@end


@implementation NLDelayedJobManager {
    NSMutableSet * _registeredJobSet;
}


+ (void)initialize {
    [super initialize];
    NSString *className = NSStringFromClass([self class]);
  //  [NLDelayedJobManager registerJob:[self class]];
    NSLog(@"%@ loaded", className);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _registeredJobSet = [NSMutableSet setWithObject:[NLJob class]];
        [_registeredJobSet addObjectsFromArray:class_getSubclasses([NLJob class])];
        //  NSMutableSet *jobClasses = [NSMutableSet setWithArray:class_getSubclasses([NLJob class])] ;
        // [jobClasses addObject:[NLJob class]];
        // return [jobClasses allObjects];

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

- (void) registerJob: (Class) clazz {
    [_registeredJobSet addObject:clazz];
    NSLog(@"Register Job Class %@", clazz);
}

+ (void) registerJob: (Class) clazz {
    [[self shared] registerJob:clazz];
}

- (NSSet *)registeredJobs {
    return _registeredJobSet;
}


+ (void) registerAllJobs: (NSArray*) jobClasses {

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

@end