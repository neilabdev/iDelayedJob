//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NLJobDescriptor;

@protocol NLJobsAbility <NSObject>
@required
+ (BOOL) performJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@optional
+ (NSDate*) scheduleJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@end