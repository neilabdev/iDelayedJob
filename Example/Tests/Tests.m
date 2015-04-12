//
//  iDelayedJobTests.m
//  iDelayedJobTests
//
//  Created by James Whitfield on 04/08/2015.
//  Copyright (c) 2014 James Whitfield. All rights reserved.
//

#import "DelayedJob.h"
//#import "NLDelayedJob.h"
//#import "NLDelayedJobManager.h"
//#import "NLDelayedJobManager_Private.h"

#import "NLPrimaryJob.h"
#import "NLSecondaryJob.h"
#import "NLFailingJob.h"

SpecBegin(InitialSpecs)

    describe(@"delayed job", ^{

        beforeAll(^{
            // This is run once and only once before all of the examples
            // in this group and before any beforeEach blocks.
        });

        beforeEach(^{
            [NLDelayedJobManager registerAllJobs:@[[NLPrimaryJob class],[NLSecondaryJob class]]];
            [NLDelayedJobManager resetAllJobs];
        });


        pending(@"should prevent duplicate queues");

        pending(@"should purge exhausted failed jobs");

        pending(@"should reschedule jobs requesting restart");

        pending(@"should schdule jobs implementing jobs protocol");


        it(@"should insert scheduled jobs into the database", ^{

            // Uses block initializer for conditional and possibly additional parameters int he future.
            NLDelayedJob * primaryDelayedJob = [NLDelayedJob configure:^(NLDelayedJobConfiguration *config) {
                config.max_attempts = 10;
                config.interval = 10;
                config.queue = @"PrimaryQueue";
            }];

            // This uses the constructor method
            NLDelayedJob *secondaryDelayedJob = [NLDelayedJob queueWithName:@"SecondaryQueue"
                                                                   interval:5
                                                                    attemps:7];

            [secondaryDelayedJob scheduleJob:[NLSecondaryJob new]
                                    priority:NLDelayedJobPriorityMedium]; // runs job regardless of connectivity

            [primaryDelayedJob scheduleInternetJob:[NLPrimaryJob new]
                                          priority:NLDelayedJobPriorityHigh]; // runs job only when internet available


            expect([[NLPrimaryJob allRecords] count]).to.equal(1);
            expect([[NLSecondaryJob allRecords] count]).to.equal(1);

            NLPrimaryJob *foundPrimaryJob = [[NLPrimaryJob allRecords] firstObject];
            NLPrimaryJob *foundSecondaryJob = [[NLSecondaryJob allRecords] firstObject];

            expect(foundPrimaryJob.priority).to.equal(NLDelayedJobPriorityHigh);
            expect(foundSecondaryJob.priority).to.equal(NLDelayedJobPriorityMedium);

            expect(foundPrimaryJob.queue).to.equal(primaryDelayedJob.queue);
            expect(foundSecondaryJob.queue).to.equal(secondaryDelayedJob.queue);

            expect(foundPrimaryJob.attempts).to.equal(0);
            expect(foundSecondaryJob.attempts).to.equal(0);

            expect(foundPrimaryJob.job_id).to.beKindOf([NSString class]);
            expect(foundSecondaryJob.job_id).to.beKindOf([NSString class]);


            [primaryDelayedJob run]; //run all scheduled jobs outside thread

            expect([[NLPrimaryJob allRecords] count]).to.equal(0);

            [secondaryDelayedJob scheduleJob:[NLFailingJob new] priority:8];
            expect([[secondaryDelayedJob activeJobs] count]).to.equal(2);
            [secondaryDelayedJob run];
            expect([[NLFailingJob allRecords] count]).to.equal(1);
            expect([[secondaryDelayedJob activeJobs] count]).to.equal(1);
        });

    });


SpecEnd
