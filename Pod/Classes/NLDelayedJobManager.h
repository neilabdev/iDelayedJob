//
//  NLDelayedJobManager.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//
#import <Foundation/Foundation.h>

@class NLDelayableJob;

@interface NLDelayedJobManager : NSObject

+ (NLDelayedJobManager *)shared;

#pragma mark - Registration Helpers

// TODO: may refactor these interfaces
+ (void)registerJob:(Class)clazz;

+ (void)registerAllJobs:(NSArray *)jobClasses;

+ (void)resetAllJobs;

- (void)resetAllJobs;

#pragma mark -

// This methods will likely remain
- (NLDelayableJob *)scheduleJob:(NLDelayableJob *)job queue:(NSString *)name priority:(NSInteger)priority internet:(BOOL)internet;

- (void)shutdown;

- (void)pause;

- (void)resume;

@end
