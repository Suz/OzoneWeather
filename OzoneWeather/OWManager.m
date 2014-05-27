//
//  OWManager.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWManager.h"
#import "OWClient.h"
#import <TSMessages/TSMessage.h>

@interface OWManager ()

//@property (nonatomic, strong, readwrite) CLLocation *currentLocation;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) OWClient *client;

@property (nonatomic, strong, readwrite) CLLocation  *currentLocation;
@property (nonatomic, strong, readwrite) OWViewData  *currentWeather;
@property (nonatomic, strong, readwrite) NSArray  *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray  *dailyForecast;

-(OWViewData *)updateDataWith:(OWCondition *)conditions andOzone:(NSArray *)ozone;

@end

@implementation OWManager

+(instancetype)sharedManager {
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

-(id) init {
    if (self = [super init]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _client = [[OWClient alloc] init];
        
        [[[[RACObserve(self, currentLocation) ignore:nil]
          
           flattenMap:^(CLLocation *newLocation) {
               return [[self updateOzoneForLocation:newLocation]
                       flattenMap:^(NSArray *ozoneForecast){
                           return [RACSignal merge:@[
                                     [self updateCurrentWeatherForLocation:newLocation andOzoneForecast:ozoneForecast],
                                     [self updateHourlyForecastForLocation:newLocation andOzoneForecast:ozoneForecast],
                                     [self updateDailyForecastForLocation:newLocation andOzoneForecast:ozoneForecast]
                                     ] ];
                       }];
               
            }]
          deliverOn:RACScheduler.mainThreadScheduler]
        subscribeError:^(NSError *error) {
            // should really pass the error on to the Controller for display in the UI.
            // This would allow a single place for handling multple errors instead of having it scattered through the app.
            [TSMessage showNotificationWithTitle:@"Error" subtitle:@"There was a problem fetching the latest weather." type:TSMessageNotificationTypeError];
        }];
        
    }
    return self;
}

-(void)findCurrentLocation {
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.isFirstUpdate) {
        // first one typically bad.
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    if (location.horizontalAccuracy > 0) {
        // currentLocation is subscribed to:  setting will trigger client!
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
    
}

// Starts a single request, no matter how many subscriptions `connection.signal`
// gets. This is equivalent to the -replay operator, or similar to
// +startEagerlyWithScheduler:block:.

/*  Could try re-writing to publish results, particularly for ozone, but not clear how to do this (at least to me...)
-(RACSignal *)updateWeather {
    // should keep multiple named signals here, then combine them before returning the final signal. See structure of
    // anwer: http://stackoverflow.com/questions/20375835/how-to-combine-two-async-network-calls-with-reactivecocoa on SO.
    
    RACSignal *ozoneForecastSignal = [self.client fetchOzoneForecastForLocation:self.currentLocation.coordinate];
    RACSignal *currentConditionsSignal = [self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate];
    RACSignal *hourlyForecastSignal = [self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate];
    RACSignal *dailyForecastSignal = [self.client fetchDailyForecastForLocation:self.currentLocation.coordinate];
    
    // need to combine the above signals and return an array or arrays or signals of view data objects. To make a viewdata object, I need to combine an OWCondition object, an OWOzoneLevel object, and astronomical data. need to validate on dates.
    
    
    return [RACSignal merge:@[
                              [self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate],
                              [self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate],
                              [self.client fetchDailyForecastForLocation:self.currentLocation.coordinate],
                              [self.client fetchOzoneForecastForLocation:self.currentLocation.coordinate]
                              ]];
}
*/

/*
-(RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(OWCondition *condition) {
        NSLog(@"Received conditions: %@", condition);
        self.currentCondition = condition;
    }];
}

-(RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

-(RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}
*/
-(RACSignal *)updateOzoneForLocation:(CLLocation *)location {
    // note: replayLazily effectively publishes to an RACSubject, allowing the signal to be shared
    return [[self.client fetchOzoneForecastForLocation:location] replayLazily];
}

-(RACSignal *)updateCurrentWeatherForLocation:(CLLocation *)location andOzoneForecast:(NSArray *)ozone {
    return [[[self.client fetchCurrentConditionsForLocation:location.coordinate]
            map:^(OWCondition *condition){
                return [self updateDataWith:condition andOzone:ozone];
            }]
            doNext:^(OWViewData *data) {
                self.currentWeather = data;
            }];
}

-(RACSignal *)updateHourlyForecastForLocation:(CLLocation *)location andOzoneForecast:(NSArray *)ozone {
    return [[[self.client fetchHourlyForecastForLocation:location.coordinate]
            map:^(NSArray *forecast){
                RACSequence *hourly = forecast.rac_sequence;
                return [[hourly map:^(OWCondition *condition){
                    if (!condition.latitude) { // TODO: fix this with another OWConditions subclass. try here first.
                        condition.latitude = @(location.coordinate.latitude);
                        condition.longitude = @(location.coordinate.longitude);
                    }
                   return [self updateDataWith:condition andOzone:ozone];
                }] array];
            }]
            doNext:^(NSArray *hourlyData) {
                self.hourlyForecast = hourlyData;
            }];
}

-(RACSignal *)updateDailyForecastForLocation:(CLLocation *)location andOzoneForecast:(NSArray *)ozone {

    return [[[self.client fetchDailyForecastForLocation:location.coordinate]
            map:^(NSArray *forecast){
                RACSequence *daily = forecast.rac_sequence;
                return [[daily map:^(OWCondition *condition) {
                            if (!condition.latitude) { // TODO: fix this with another OWConditions subclass. try here first.
                                condition.latitude = @(location.coordinate.latitude);
                                condition.longitude = @(location.coordinate.longitude);
                            }
                            return [self updateDataWith:condition andOzone:ozone];
                        }] array];

            }]
            doNext:^(NSArray *dailyData) {
                self.dailyForecast = dailyData;
            }];
}




-(OWViewData *)updateDataWith:(OWCondition *)conditions andOzone:(NSArray *)ozoneLevels {
    // Find ozoneLevel with date closest to conditions:

    double time_diff = 48*3600.0; // initialize at 2 days
    int keeper = -99;
    
    for (int idx=0; idx < ozoneLevels.count; idx = idx + 1) {
        OWOzoneLevel *ozone = [ozoneLevels objectAtIndex:idx];
        
        double temp = [conditions.date timeIntervalSinceDate:ozone.ozoneDate];
        if (abs(temp) < time_diff) {
            // found a ozone level closer in time.
            time_diff = abs(temp);
            keeper = idx;
        }
    }
    if (keeper == -99) {
        NSLog(@"Error: Weather date %@ more than 48 hours from any ozone date. Returning NIL.", conditions.date);
        return Nil;
    };
    
    OWViewData *viewData = [[OWViewData alloc] initWithConditions:conditions andOzone:ozoneLevels[keeper]];   //
    
    return viewData;
}


@end
