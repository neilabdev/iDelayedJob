//
//  NLAppDelegate.h
//  NLDelayedJob
//
//  Created by CocoaPods on 04/06/2015.
//  Copyright (c) 2014 James Whitfield. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NLDelayedJob;

@interface NLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NLDelayedJob *primaryDelayedJob;
@property (strong, nonatomic) NLDelayedJob *secondaryDelayedJob;
@end
