//
//  NLAppDelegate.m
//  iDelayedJob
//
//  Created by CocoaPods on 04/08/2015.
//  Copyright (c) 2014 James Whitfield. All rights reserved.
//

#import "NLAppDelegate.h"
#import "DelayedJob.h"

#import "NLFailingJob.h"
#import "NLPrimaryJob.h"
#import "NLSecondaryJob.h"
#import "NLAbilityJob.h"

@implementation NLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    NLDelayedJob *primaryQueue =[[NLDelayedJob configure:^(NLDelayedJobConfiguration *config) {
        config.queue = @"PrimaryQueue";
        config.max_attempts = 3;
    }] start];

    NLDelayedJob *secondaryQueue = [[NLDelayedJob queueWithName:@"SecondaryQueue" interval:10 attemps:4] start];


    [primaryQueue scheduleJob:[NLFailingJob new] priority:NLDelayedJobPriorityMedium];
    [primaryQueue scheduleJob:[NLDelayableJob job:[NLPrimaryJob class] withArguments:@"FOO", @"BAR", nil] priority:NLDelayedJobPriorityMedium];
    [secondaryQueue scheduleJob:[NLSecondaryJob class] priority:NLDelayedJobPriorityNormal];
    //Method 2:
    [primaryQueue scheduleJob:[NLAbilityJob class] priority:NLDelayedJobPriorityNormal];

    /* // Additional menas to create jobs
    DelayedJob_create([NLSecondaryJob class],@"Arg1",@"Arg2");
    [NLSecondaryJob jobWithArguments: @"Arg1",@"Arg2",nil];
    [NLDelayableJob job:[NLAbilityJob class] withArguments:@"Arg1",@"arg2",nil];
    */
    //Method 3:
    //No need to store variable with unique Queue Name. You may schedule using shared Manager.
    [[NLDelayedJob sharedManager] scheduleJob:[NLSecondaryJob new]
                                        queue:@"PrimaryQueue"
                                     priority:NLDelayedJobPriorityMedium
                                     internet:NO];

    //Method 4:
    //Same as above, but in a macro
    DelayedJob_schedule([NLAbilityJob class], @"PrimaryQueue", NLDelayedJobPriorityMedium,@"Arg1",@"Arg2");


    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
