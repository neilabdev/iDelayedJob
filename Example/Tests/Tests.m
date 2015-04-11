//
//  iDelayedJobTests.m
//  iDelayedJobTests
//
//  Created by James Whitfield on 04/08/2015.
//  Copyright (c) 2014 James Whitfield. All rights reserved.
//
#import "NLDelayedJob.h"
#import "NLPrimaryJob.h"
#import "NLDelayedJobManager.h"
#import "NLSecondaryJob.h"
#import "NLFailingJob.h"
#import "NLDelayedJobManager_Private.h"

SpecBegin(InitialSpecs)
    /*
   describe(@"these will fail", ^{

       it(@"can do maths", ^{
           expect(1).to.equal(2);
       });

       it(@"can read", ^{
           expect(@"number").to.equal(@"string");
       });

       it(@"will wait for 10 seconds and fail", ^{
           waitUntil(^(DoneCallback done) {

           });
       });
   });

   describe(@"these will pass", ^{

       it(@"can do maths", ^{
           expect(1).beLessThan(23);
       });

       it(@"can read", ^{
           expect(@"team").toNot.contain(@"I");
       });

       it(@"will wait and succeed", ^AsyncBlock {
           waitUntil(^(DoneCallback done) {
               done();
           });
       });
}); */

    describe(@"delayed job", ^{

        beforeAll(^{
            // This is run once and only once before all of the examples
            // in this group and before any beforeEach blocks.
        });

        beforeEach(^{
            [NLDelayedJobManager registerAllJobs:@[[NLPrimaryJob class],[NLSecondaryJob class]]];
            [[NLDelayedJobManager shared] resetAllJobs];
        });


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

            [secondaryDelayedJob scheduleJob:[NLSecondaryJob new] priority:7]; // runs job regardless of connectivity
            [primaryDelayedJob scheduleInternetJob:[NLPrimaryJob new] priority:10]; // runs job only when internet available

            expect([[NLPrimaryJob allRecords] count]).to.equal(1);
            expect([[NLSecondaryJob allRecords] count]).to.equal(1);

            NLPrimaryJob *foundPrimaryJob = [[NLPrimaryJob allRecords] firstObject];
            NLPrimaryJob *foundSecondaryJob = [[NLSecondaryJob allRecords] firstObject];

            expect(foundPrimaryJob.priority).to.equal(10);
            expect(foundSecondaryJob.priority).to.equal(7);

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
