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


typedef void (^NLDelayedJobBlock)(NLJobDescriptor* _Nonnull descriptor , NSArray * _Nonnull arguments);
typedef void (^NLDelayedJobConfigurationBlock)(NLDelayedJobConfiguration * _Nonnull config );

@interface NLDelayedJob : NSObject {}
@property(nonatomic, assign) NSInteger max_attempts;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, retain) NSString *host;
@property(nonatomic, readonly) NSString *queue;
#pragma mark - Initialization

+ (instancetype)queueWithName:(NSString * _Nonnull)name interval:(NSTimeInterval)interval
                      attemps:(NSInteger)attempts NS_SWIFT_NAME(with(queue:interval:attempts:));

- (id)initWithQueue:(NSString *)name interval:(NSTimeInterval)interval attemps:(NSInteger)attempts  NS_SWIFT_NAME(init(queue:interval:attempts:));

+ (NLDelayedJob * _Nonnull)configure:(NLDelayedJobConfigurationBlock  _Nonnull)config  NS_SWIFT_NAME(configure(jobs:));

#pragma mark - Singleton Helpers

+ (NLDelayedJob * _Nonnull)defaultQueue NS_SWIFT_NAME(defaultQueue());

+ (NLDelayedJobManager * _Nonnull)sharedManager NS_SWIFT_NAME(sharedManager());

#pragma mark - Instance Methods

- (NLDelayedJob *)start NS_SWIFT_NAME(start()); //starts timers and job processing

- (void)pause NS_SWIFT_NAME(pause()); // Prevents now jobs from being processed

- (void)resume NS_SWIFT_NAME(resume()); // Allows new jobs to be pull from queue and executed

- (void)stop NS_SWIFT_NAME(stop()); // shuts down timers

- (NSInteger)run NS_SWIFT_NAME(run());
- (NLDelayableJob *)cancelJob: (Class) jobClass id: (NSNumber*) id  NS_SWIFT_NAME(cancel(job:id:));
- (NLDelayableJob * _Nonnull)scheduleInternetJob:(id) jobOrClass priority:(NSInteger)priority  NS_SWIFT_NAME(scheduleInternet(job:priority:));

- (NLDelayableJob * _Nonnull)scheduleJob:(id _Nonnull) jobOrClass priority:(NSInteger)priority
                       internet:(BOOL)requireInternet  NS_SWIFT_NAME(schedule(job:priority:internet:));
- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority
                           wifi:(BOOL)requireInternet   NS_SWIFT_NAME(schedule(job:priority:wifi:));
- (NLDelayableJob *)scheduleJob:(id) jobOrClass priority:(NSInteger)priority  internet:(BOOL)requireInternet
                           wifi:(BOOL)requireWifi   NS_SWIFT_NAME(schedule(job:priority:internet:wifi:));
- (NLDelayableJob * _Nonnull)scheduleJob:(id _Nonnull) jobOrClass priority:(NSInteger)priority NS_SWIFT_NAME(schedule(job:priority:));


@end