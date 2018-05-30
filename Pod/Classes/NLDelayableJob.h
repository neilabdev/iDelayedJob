//
//  NLDelayableJob.h
//  iDelayedJob
//
//  Created by James Whitfield on 04/08/2015.
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//


#import "NLJob.h"
#import <VinylRecord/VinylRecord.h>
@class NLDelayableJob;
#define kJobDescriptorCodeOk  0
#define kJobDescriptorCodeRunFailure  1
#define kJobDescriptorCodeLoadFailure  2

@interface NLJobDescriptor : NSObject  {
    NSString *_error;
    NSInteger _code;
    NLDelayableJob *_job;
}
@property (nonatomic, assign) NSInteger code;
@property (nonatomic,retain) NSString *error;
@property (nonatomic, readonly) NLDelayableJob *job;
- (id) initWithJob: (NLDelayableJob *) job NS_SWIFT_NAME(with(job:));
@end

@protocol NLDelayableJobAbility;


@interface NLDelayableJob : VinylRecord <NLJob> {}
column_dec(string, handler)
column_dec(string, queue)
column_dec(string, parameters)
column_dec(integer, priority)
column_dec(integer, attempts)
column_dec(string, last_error)
column_dec(date, run_at)
column_dec(date, locked_at)
column_dec(boolean, locked)
column_dec(date, failed_at)
column_dec(boolean, internet)
column_dec(boolean,unique)
column_dec(string, job_id)
@property(nonatomic,retain) NSMutableArray *params;
@property(readonly,retain) NLJobDescriptor *descriptor;

+ (NLDelayableJob *) job:(id) jobOrClass withArgument: (NSArray*)argument  NS_SWIFT_NAME(with(job:argument:));
+ (NLDelayableJob *) job:(id) jobOrClass withArguments:(id) firstObject,... NS_SWIFT_NAME(with(job:arguments:));

+ (NLDelayableJob *) jobWithClass: (Class <NLDelayableJobAbility>) jobClass NS_SWIFT_NAME(with(abilityClass:));

+ (NLDelayableJob *) jobWithArguments: (id) firstObject, ...  NS_SWIFT_NAME(with(arguments:));
+ (NLDelayableJob *) jobWithArgument: (NSArray*) arguments NS_SWIFT_NAME(with(argument:));

+ (NLDelayableJob *) jobWithHandler:(NSString *)className arguments: (id) firstObject, ...  NS_SWIFT_NAME(with(handler:arguments:));
+ (NLDelayableJob *) jobWithHandler:(NSString *)className argument: (NSArray*) arguments   NS_SWIFT_NAME(with(handler:argument:));

- (NLDelayableJob *) setArguments: (id) firstObject, ...  NS_SWIFT_NAME(set(arguments:));
- (NLDelayableJob *) setArgument: (NSArray *) arguments   NS_SWIFT_NAME(set(argument:));

- (BOOL) shouldRestartJob  NS_SWIFT_NAME(shouldRestartJob());
- (void) onBeforeDeleteEvent NS_SWIFT_NAME(onBeforeDeleteEvent());
- (BOOL) perform  NS_SWIFT_NAME(perform());
- (BOOL) run NS_SWIFT_NAME(run());

- (NSComparisonResult)priorityCompare:(NLDelayableJob *)job ;
@end
