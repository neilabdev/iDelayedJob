//
// Created by James Whitfield on 4/8/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NLDelayedJobManager : NSObject

+ (NLDelayedJobManager *)shared;
+ (void) resetAllJobs;

- (void) shutdown;
- (void) pause;
- (void) resume;

- (void) resetAllJobs;
@end
