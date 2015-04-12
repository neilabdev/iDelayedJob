//
//  NLJob.h
//  iDelayedJob
//
//  Created by James Whitfield on 04/08/2015.
//  Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "VinylRecord.h"
@class  NLJob;
#define kJobDescriptorCodeOk  0
#define kJobDescriptorCodeRunFailure  1
#define kJobDescriptorCodeLoadFailure  2

@interface NLJobDescriptor : NSObject  {
    NSString *_error;
    NSInteger _code;
    NLJob *_job;
}
@property (nonatomic, assign) NSInteger code;
@property (nonatomic,retain) NSString *error;
@property (nonatomic, readonly) NLJob *job;
- (id) initWithJob: (NLJob *) job;
@end

@protocol NLJobsAbility;
@protocol NLJob
@end

@interface NLJob : VinylRecord <NLJob> {}
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

+ (NLJob *) job:(id <NLJob>) jobOrClass withArguments:(id) firstObject,...;
+ (NLJob *) jobWithClass: (Class <NLJobsAbility>) jobClass;
+ (NLJob *) jobWithArguments: (id) firstObject, ...;
+ (NLJob *) jobWithHandler: (NSString *) className arguments: (id) firstObject, ...;

- (NLJob *) setArguments: (id) firstObject, ...;
- (BOOL) shouldRestartJob;
- (void) onBeforeDeleteEvent; //onBeforeDeleteEvent
- (BOOL) perform;
- (BOOL) run;

- (NSComparisonResult)priorityCompare:(NLJob *)job;
@end
