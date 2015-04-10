//
// Created by James Whitfield on 4/8/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NLJob;

@interface NLDelayedJobManager : NSObject

+ (NLDelayedJobManager *)shared;

+ (void) registerJob: (Class) clazz;
+ (void) registerAllJobs: (NSArray*) jobClasses;
+ (NSArray*) registeredJobs;
- (NSArray*) registeredJobs;

+ (void) resetAllJobs;
- (void) resetAllJobs;
@end