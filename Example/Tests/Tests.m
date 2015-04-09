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
    describe(@"sample jobs schould schedule", ^{

        beforeAll(^{
            // This is run once and only once before all of the examples
            // in this group and before any beforeEach blocks.
        });

        beforeEach(^{
            // This is run before each example.=
            // [NLPrimaryJob dropAllRecords];

            //    [NLPrimaryJob new];
            //    [NLDelayedJobManager registerJob:[NLPrimaryJob class]];

            [NLDelayedJobManager registerAllJobs:@[[NLPrimaryJob class]]];
            [NLDelayedJobManager resetAllJobs];

        });


        it(@"can do maths", ^{

            NLDelayedJob * primaryDelayedJob = [NLDelayedJob configure:^(NLDelayedJobConfiguration *config) {
                config.max_attempts = 10;
                config.interval = 10;
                config.queue = @"PrimaryQueue";
            }];



            [primaryDelayedJob scheduleInternetJob:[NLPrimaryJob new] priority:10];

            expect([[NLPrimaryJob allRecords] count]).to.equal(1);
            //expect(1).beLessThan(23);
        });

    });


SpecEnd
