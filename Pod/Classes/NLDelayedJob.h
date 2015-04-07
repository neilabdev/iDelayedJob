//
// Created by ghost on 6/14/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NLJob.h"



#define NLDELAYEDJOB_HANDLER(class_name)   NSStringFromClass([class_name class])

#define kDelayedJobPriorityNormal 1
#define kDelayedJobPriorityHigh 1

@interface NLDelayedJobConfiguration : NSObject

@property (nonatomic, assign) NSInteger max_attempts;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *queue;
@property (nonatomic, assign) BOOL hasInternet;
@end



typedef void (^NLDelayedJobConfigurationBlock)(NLDelayedJobConfiguration *config);

@interface NSDate (NLDelayedJob)
- (NSNumber *) numberWithTimeIntervalSince1970 ;
@end

@interface NSNumber (NLDelayedJob)
- (NSDate *) dateWithTimeIntervalSince1970;
@end

@interface NLDelayedJob : NSObject    {}

@property (nonatomic, assign) NSInteger max_attempts;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) BOOL hasInternet;
@property (nonatomic, readonly) NSString *queue;

- (id)initWithQueue: (NSString *) name interval: (NSInteger) interval attemps:(NSInteger) attempts;

+ (NLDelayedJob *) configure: (NLDelayedJobConfigurationBlock) config;

+ (NLDelayedJob *) start;
- (NLDelayedJob *) start;

+ (void) stop;
- (void) stop;

+ (void) shutdown;

+ (void) destroy;
+ (void) reset;
+ (void) stopAndResetAllJobs;

+ (NLDelayedJob *) defaultQueue;

+ (NSArray*) activeJobs;

+ (void) initializeForTesting;

- (void) scheduleJob: (NLJob*) job priority: (NSInteger) priority;
+ (void) scheduleJob: (NLJob*) job priority: (NSInteger) priority;

+ (void) scheduleInternetJob: (NLJob *) job priority: (NSInteger) priority;
- (void) scheduleInternetJob: (NLJob *) job priority: (NSInteger) priority;

- (void) scheduleJob:(NLJob *)job priority:(NSInteger)priority internet:(BOOL)requireInternet;
+ (void) scheduleJob:(NLJob *)job priority:(NSInteger)priority internet:(BOOL)requireInternet;

@end