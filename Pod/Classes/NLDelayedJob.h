//
//  NLDelayedJob.h
//  iDelayedJob
//
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NLDelayableJob.h"
#import "NLDelayedJobManager.h"

typedef NS_ENUM(NSInteger, NLDelayedJobPriority) {
    NLDelayedJobPriorityNormal=1,
    NLDelayedJobPriorityMedium=5,
    NLDelayedJobPriorityHigh=10
};

@interface NLDelayedJobConfiguration : NSObject
@property(nonatomic, assign) NSInteger max_attempts;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, retain) NSString *host;
@property(nonatomic, retain) NSString *queue;
@property(nonatomic, assign) BOOL hasInternet;
@end


typedef void (^NLDelayedJobBlock)(NLJobDescriptor* descriptor , NSArray * arguments);
typedef void (^NLDelayedJobConfigurationBlock)(NLDelayedJobConfiguration *config);

@interface NLDelayedJob : NSObject {}
@property(nonatomic, assign) NSInteger max_attempts;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, retain) NSString *host;
@property(nonatomic, readonly) NSString *queue;
#pragma mark - Initialization

+ (instancetype)queueWithName:(NSString *)name interval:(NSTimeInterval)interval
                      attemps:(NSInteger)attempts NS_SWIFT_NAME(with(queue:interval:attempts:));

- (id)initWithQueue:(NSString *)name interval:(NSTimeInterval)interval attemps:(NSInteger)attempts  NS_SWIFT_NAME(init(queue:interval:attempts:));

+ (NLDelayedJob *)configure:(NLDelayedJobConfigurationBlock)config  NS_SWIFT_NAME(configure(jobs:));

#pragma mark - Singleton Helpers

+ (NLDelayedJob *)defaultQueue NS_SWIFT_NAME(defaultQueue());

+ (NLDelayedJobManager *)sharedManager NS_SWIFT_NAME(sharedManager());

#pragma mark - Instance Methods

- (NLDelayedJob *)start NS_SWIFT_NAME(start()); //starts timers and job processing

- (void)pause NS_SWIFT_NAME(pause()); // Prevents now jobs from being processed

- (void)resume NS_SWIFT_NAME(resume()); // Allows new jobs to be pull from queue and executed

- (void)stop NS_SWIFT_NAME(stop()); // shuts down timers

- (NSInteger)run NS_SWIFT_NAME(run());

- (NLDelayableJob *)scheduleInternetJob:(id) jobOrClass priority:(NSInteger)priority  NS_SWIFT_NAME(scheduleInternet(job:priority:));

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority
                       internet:(BOOL)requireInternet  NS_SWIFT_NAME(schedule(job:priority:internet:));

- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority NS_SWIFT_NAME(schedule(job:priority:));
@end