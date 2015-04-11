//
// Created by James Whitfield on 4/10/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLFailingJob.h"


@implementation NLFailingJob {}

- (BOOL)perform {
    NSLog(@"job=%@ : %@ queue=%@ attempts=%@ nextRun=%@",self.handler,self.job_id,self.queue,self.attempts,self.run_at);
    return NO;
}

@end