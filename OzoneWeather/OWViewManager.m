//
//  OWViewManager.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 16/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWViewManager.h"

#import "OWManager.h"
#import "OWCondition.h"
#import "OWOzoneLevel.h"

#import "OWSolarWrapper.h"

@interface OWViewManager ()

@property (nonatomic, readwrite) OWViewData *currentData;

@end
@implementation OWViewManager

+(instancetype)sharedManager {
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

#pragma mark    ===============   signals ====================

-(RACSignal *)currentWeather{ return (
                                      [RACSignal combineLatest:@[
                                                          RACObserve([OWManager sharedManager], currentCondition),
                                                          RACObserve([OWManager sharedManager], ozoneForecast)
                                                          ]
                                       // might want to set public property instead of returning?
                                         reduce:^(OWCondition *condition, NSArray *ozoneLevels){
                                             OWOzoneLevel *todayOzone = [ozoneLevels firstObject];
                                             OWViewData *viewData = [self updateWeatherWith:condition andOzone:todayOzone];
                                             self.currentData = viewData;
                                             return viewData;
                                         }]
                );
}

// These aren't working yet. complaining about my references. Doesn't seem to like operating on two NSArrays and returning an NSArray.


/*-(RACSignal *)hourlyWeather{ return (
                                [RACSignal combineLatest:@[
                                  RACObserve([OWManager sharedManager], hourlyForecast),
                                  RACObserve([OWManager sharedManager], ozoneForecast)
                                  ]
                         reduce:^(NSArray *forecast, NSArray *ozoneLevels){
                             OWOzoneLevel *todayOzone = [ozoneLevels firstObject];
                             // should return an NSArray of viewData. Uses hourly data with today's ozone.
                             NSMutableArray *hourly =
                                        [conditions enumerateObjectsUsingBlock:^(OWCondition *condition, NSUInteger idx, BOOL *stop) {
                                            return [self updateWeatherWith:condition andOzone:todayOzone];
                                        }];
                             self.hourlyData = [NSArray arrayWithArray:hourly];
                         }]
                                     );
}

-(RACSignal *)dailyWeather{ [[RACSignal combineLatest:@[
                                 RACObserve([OWManager sharedManager], dailyForecast),
                                 RACObserve([OWManager sharedManager], ozoneForecast)]
                        reduce:^(NSArray *conditions, NSArray *ozoneLevels){
                            // should return an NSArray of viewData. Uses daily conditions with daily ozone.
                            return [conditions enumerateObjectsUsingBlock:^(OWCondition *condition, NSUInteger idx, BOOL *stop) {
                                return [self updateWeatherWith:condition andOzone:ozoneForecast[idx]];
                            }];
                        }]
                              deliverOn:RACScheduler.mainThreadScheduler];
}
*/




-(OWViewData *)updateWeatherWith:(OWCondition *)conditions andOzone:(OWOzoneLevel *)ozone {
    // error checking: compare dates
    if ([conditions.date timeIntervalSinceDate:ozone.ozoneDate] > 24*3600.0) {
        NSLog(@"Error: Ozone Date %@ doesn't match weather date %@", ozone.ozoneDate, conditions.date);
        return Nil;
    };
    
    OWViewData *viewData = [[OWViewData alloc] initWithConditions:conditions andOzone:ozone];   //
    
    return viewData;
}

@end
