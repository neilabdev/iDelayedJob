//
// Created by James Whitfield on 4/7/15.
// Copyright (c) 2015 James Whitfield. All rights reserved.
//

#import "NLSecondaryJob.h"


@implementation NLSecondaryJob {}
- (BOOL)perform {
    NSLog(@"%@ attempts= %@",self,self.attempts);
    return NO;
}

@end