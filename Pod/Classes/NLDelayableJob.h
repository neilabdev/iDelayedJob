//
//  NLDelayableJob.h
//  iDelayedJob
//
//  Created by James Whitfield on 04/08/2015.
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//


#import "VinylRecord.h"
#import "NLJob.h""
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
- (id) initWithJob: (NLDelayableJob *) job;
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

+ (NLDelayableJob *) job:(id <NLJob>) jobOrClass withArguments:(id) firstObject,...;
+ (NLDelayableJob *) jobWithClass: (Class <NLDelayableJobAbility>) jobClass;
+ (NLDelayableJob *) jobWithArguments: (id) firstObject, ...;
+ (NLDelayableJob *) jobWithHandler: (NSString *) className arguments: (id) firstObject, ...;

- (NLDelayableJob *) setArguments: (id) firstObject, ...;
- (BOOL) shouldRestartJob;
- (void) onBeforeDeleteEvent; //onBeforeDeleteEvent
- (BOOL) perform;
- (BOOL) run;

- (NSComparisonResult)priorityCompare:(NLDelayableJob *)job;
@end
