//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NLJobDescriptor;

@protocol NLJobsAbility <NSObject>



@required
+ (BOOL)respondsToSelector:(SEL)aSelector; // Rids us of warnings, why not appart of <NSObject>

+ (BOOL) performJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@optional
+ (NSDate*) scheduleJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (BOOL) shouldRestartJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (BOOL) beforeDeleteJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@end