# iDelayedJob

[![CI Status](http://img.shields.io/travis/James Whitfield/iDelayedJob.svg?style=flat)](https://travis-ci.org/James Whitfield/iDelayedJob)
[![Version](https://img.shields.io/cocoapods/v/iDelayedJob.svg?style=flat)](http://cocoapods.org/pods/iDelayedJob)
[![License](https://img.shields.io/cocoapods/l/iDelayedJob.svg?style=flat)](http://cocoapods.org/pods/iDelayedJob)
[![Platform](https://img.shields.io/cocoapods/p/iDelayedJob.svg?style=flat)](http://cocoapods.org/pods/iDelayedJob)



iDelayedJob (or iDJ like Jazzy Jeff) encapsulates the common pattern of asynchronously executing longer tasks in the background, as modeled and inspired by the equivalent rails plugin of similar name.

It was extracted from a projected that utilized its abilities to send comments and other activities that needed to connect to a backend service but couldn't at the time for various reasons, such as loss of connectivity or even if the backend at the time was down. Using iDelayedJob you will be able to just schedule a job to say, register a comment or a purchase using internal premium currency, etc, which will be attempted multiple times according the the schedule which may say, only try this job when connectivity is available as determined by *Reachability*, thus not attempting jobs which require internet when internet is nowhere to be found.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

iDelayedJob is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "iDelayedJob"
```

## Queueing Jobs

The first thing you must do before scheduling a job is define it, by either subclassing NLJob or creating a class which implements NLJobsAbility protocol. Either method will execute the *perform method which will return if the job was successfuly completed or not. If it is not successfully completed, the job will periodically for a specified *max_attempts upon which it will be removed from the queue.



Sublcass NLJob

```objective-c
@interface NLPrimaryJob : NLJob
@end

@implementation NLPrimaryJob {}
- (BOOL)perform {
    NSLog(@"job=%@  queue=%@ attempts=%@ nextRun=%@",self.handler,self.queue,self.attempts,self.run_at);
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
    NSInteger add_seconds = ([job.attempts intValue] + 5) * 4;
    NSDate *nextRunTime = [NSDate dateWithTimeIntervalSinceNow:(int) add_seconds];
    return nextRunTime;
}

+ (BOOL)shouldRestartJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    NSLog(@"shouldRestartJob: job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",job.handler,job.job_id,job.queue,job.attempts,job.run_at);
    return NO;
}

+ (void)beforeDeleteJob:(NLJobDescriptor *)descriptor withArguments:(NSArray *)arguments {
    NLJob *job = descriptor.job;
    return;
}
@end
```



## Author

James Whitfield, jwhitfield@neilab.com

## License

iDelayedJob is available under the MIT license. See the LICENSE file for more info.
