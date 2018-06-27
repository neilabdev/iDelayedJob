//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLJob.h"
@class NLJobDescriptor;
@protocol NLDelayableJobAbility <NSObject,NLJob>
@required
+ (BOOL) performJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@optional
+ (void) cancelJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (NSDate*) scheduleJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (BOOL) shouldRestartJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (void) beforeDeleteJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (void) afterDeleteJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (void) beforePerformJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (void) afterPerformJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (void) afterCompletedJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@end