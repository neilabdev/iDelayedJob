# iDelayedJob

[![CI Status](http://img.shields.io/travis/James Whitfield/iDelayedJob.svg?style=flat)](https://travis-ci.org/James Whitfield/iDelayedJob)
[![Version](https://img.shields.io/cocoapods/v/iDelayedJob.svg?style=flat)](http://cocoapods.org/pods/iDelayedJob)
[![License](https://img.shields.io/cocoapods/l/iDelayedJob.svg?style=flat)](http://cocoapods.org/pods/iDelayedJob)
[![Platform](https://img.shields.io/cocoapods/p/iDelayedJob.svg?style=flat)](http://cocoapods.org/pods/iDelayedJob)



iDelayedJob (or iDJ like Jazzy Jeff) is a Job scheduler allowing transparent performance and retrying of task until successful or exhausted,  even across application restart, and was modeled and inspired by the equivalent rails plugin of similar name.

It was extracted from a projected that utilized its abilities to send comments and other activities that needed to connect to a backend service but couldn't at the time for various reasons, such as loss of connectivity or even if the backend at the time was down. Using iDelayedJob you will be able to just schedule a job to say, register a comment or make a purchase using internal premium currency, etc, which will be attempted multiple times according the the schedule which may say something like, only try this job when connectivity is available as determined by *Reachability*, thus not attempting jobs which require internet when internet is nowhere to be found.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

NOTE: iDelayedJob was refactored to use VinylRecord (a fork of iActiveRecord by Alex Denisov) as a persistence layer for jobs storage and querying. Wherefore, should you also use VinylRecord be sure for the primary application you configure the database before initializing any jobs, etc, so that your application settings take precedence of the defaults utilized with iDelayedJob.

## Installation

iDelayedJob is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "iDelayedJob"
```

## Scheduling Jobs
### Defining a Job
The first thing you must do before scheduling a job is define it, by either subclassing *NLJob* or creating a class which implements *NLJobsAbility* protocol. Either method will execute the *perform* method which will return if the job was successfully completed or not. If it is not successfully completed, the job will periodically for a specified *max_attempts* upon which it will be removed from the queue.



Sublcass NLJob

```objective-c
#import "DelayedJob.h"
@interface NLPrimaryJob : NLJob
@end

@implementation NLPrimaryJob {}
- (BOOL)perform {
    NSLog(@"job=%@  queue=%@ attempts=%@ nextRun=%@",self.handler,self.queue,self.attempts,self.run_at);
    // Perform work and return YES if work was successful. This can included connecting to backend server, etc.
    return YES;
}
@end
```

or implement protocol:

```objective-c
@protocol NLJobsAbility <NSObject>
@required
+ (BOOL) performJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@optional
+ (NSDate*) scheduleJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (BOOL) shouldRestartJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
+ (void) beforeDeleteJob: (NLJobDescriptor*) descriptor withArguments: (NSArray *)arguments;
@end
```

For Example:

```objective-c
#import "DelayedJob.h"
@interface NLAbilityJob : NSObject <NLJobsAbility>
@end

@implementation NLAbilityJob {}
+ (BOOL)performJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSLog(@"performJob: job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",job.handler,job.job_id,job.queue,job.attempts,job.run_at);
    return NO;
}

+ (NSDate *)scheduleJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSInteger add_seconds = ([job.attempts intValue] + 5) * 4; // Default equation for job scheduling
    NSDate *nextRunTime = [NSDate dateWithTimeIntervalSinceNow:(int) add_seconds];
    return nextRunTime; // Normal job schedule can be changed if you return a different date.
}

+ (BOOL)shouldRestartJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSLog(@"shouldRestartJob: job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",job.handler,job.job_id,job.queue,job.attempts,job.run_at);
    return NO; //Job will be deleted if 'NO' is returned.
}

+ (void)beforeDeleteJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    return;
}
@end
```

### Configuring Queue

*NLDelayedJob* represents the queue which is run at whatever interval specified during its configuration. You may have multiple job queues however each queue name must be unique or otherwise upon starting the job there will be an exception raised. The primary parameters you are most concerned with are *max_attempts* which specifies how many times a failing job will run before giving up, *interval* which determines how often the queue is run seeking pending jobs to run, and the *queue* name which must be unique. 

The definition is as follows:


```objective-c
@interface NLDelayedJob : NSObject {}
@property(nonatomic, assign) NSInteger max_attempts;
@property(nonatomic, assign) NSTimeInterval interval;
@property(nonatomic, readonly) NSString *queue;
#pragma mark - Initialization
+ (instancetype)queueWithName:(NSString *)name interval:(NSTimeInterval)interval attemps:(NSInteger)attempts;
- (id)initWithQueue:(NSString *)name interval:(NSTimeInterval)interval attemps:(NSInteger)attempts;
+ (NLDelayedJob *)configure:(NLDelayedJobConfigurationBlock)config;

#pragma mark - Singleton Helpers

+ (NLDelayedJob *)defaultQueue;
+ (NLDelayedJobManager *)sharedManager;

#pragma mark - Instance Methods

- (NLDelayedJob *)start; //starts timers and job processing
- (void)pause; // Prevents new jobs from being processed
- (void)resume; // Allows new jobs to be pull from queue and executed
- (void)stop; // shuts down timers
- (NLJob *)scheduleInternetJob:(NLJob *)job priority:(NSInteger)priority;
- (NLJob *)scheduleJob:(NLJob *)job priority:(NSInteger)priority internet:(BOOL)requireInternet;
- (NLJob *)scheduleJob:(NLJob *)job priority:(NSInteger)priority;
@end
```

While you may instantiate queues anywhere,  it makes more sense to start and stop queues in the *Application Delegate* and have theme run throughout the duration of the application.

For Example:

```objective-c
#import "DelayedJob.h"

@implementation NLAppDelegate {
    NLDelayedJob *primaryQueue;
    NLDelayedJob *secondaryQueue ;
    NLDelayedJob *thirdQueue ;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Create/Start Method 1: Create Queue Using configure method which may offer more options than designated initializer.
    primaryQueue =[[NLDelayedJob configure:^(NLDelayedJobConfiguration *config) {
        config.queue = @"PrimaryQueue";
        config.max_attempts = 3;
    }] start];

    // Create/Start Method 2: Use initializer to create and subsequently start the queue using the specified options
    secondaryQueue = [[NLDelayedJob queueWithName:@"SecondaryQueue" interval:10 attemps:4] start];
  
    // Create/Start Method 3: // same as above but with macro allowing dropping of NL prefix
    
    thirdQueue = [DelayedJob configure(^(NLDelayedJobConfiguration *config) {
                                               config.queue = @"PrimaryQueue";
                                               config.max_attempts = 3;
                                           }) start];
    
    return YES;
}
```


Should you desire  a queue to only exist within the context of a UIViewController, be sure to stop the queue during the deallocation process otherwise the queue won't be freed as it is also retained by a *NLDelayedJobManager* when running.

### Scheduling A Job

Once A Job has been defined and a queue has been started, it can be scheduled to run. 

For Example:

```objective-c
#import "DelayedJob.h"

@implementation SomeClassWhichLikesQueues

- (void) scheduleQueues
    // Schedule Method 1: Assumes secondaryQueue (defined someplace) contains a running queue
    [secondaryQueue scheduleJob:[NLJob jobWithClass:[NLAbilityJob class]] 
                    priority:NLDelayedJobPriorityNormal];

    // Schedule Method 2: No need to store variable with unique Queue Name. You may schedule using shared Manager.
    [[NLDelayedJob sharedManager] scheduleJob:[NLSecondaryJob new]
                                        queue:@"PrimaryQueue"
                                     priority:NLDelayedJobPriorityMedium
                                     internet:NO]; //Internet not required to attempt processing job
                                     
    // Schedule Method 3: Same as method above, but uses terse macro
    
    DelayedJob_schedule([NLSecondaryJob class], @"PrimaryQueue", NLDelayedJobPriorityMedium,@"Arg1",@"Arg2");

}
end
```



## License

iDelayedJob is available under the MIT license. See the LICENSE file for more info.
