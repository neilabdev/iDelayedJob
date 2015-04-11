//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLSecondaryJob.h"


@implementation NLSecondaryJob {}
- (BOOL)perform {
    NSLog(@"job=%@  queue=%@ attempts=%@ nextRun=%@",self.handler,self.queue,self.attempts,self.run_at);
    return YES;
}

@end