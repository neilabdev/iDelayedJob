//
// Created by James Whitfield on 4/8/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NLDelayedJobManager : NSObject

+ (NLDelayedJobManager *)shared;

#pragma mark - Registration Helpers
+ (void)registerJob:(Class)clazz;
+ (void)registerAllJobs:(NSArray *)jobClasses;


+ (void) resetAllJobs;

- (void) shutdown;
- (void) pause;
- (void) resume;

- (void) resetAllJobs;
@end
