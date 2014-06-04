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
#import "RACEXTScope.h"

@interface OWManager ()

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
        
        @weakify(self)
        [[[[RACObserve(self, currentLocation) ignore:nil]
          
           flattenMap:^(CLLocation *newLocation) {
               @strongify(self)
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

#pragma mark ============= Location ====================

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

#pragma mark ============= Location ====================

-(RACSignal *)updateOzoneForLocation:(CLLocation *)location {
    // note: replayLazily effectively publishes to an RACSubject, allowing the signal to be shared
    return [[self.client fetchOzoneForecastForLocation:location] replayLazily];
}

-(RACSignal *)updateCurrentWeatherForLocation:(CLLocation *)location andOzoneForecast:(NSArray *)ozone {
    @weakify(self);
    return [[[self.client fetchCurrentConditionsForLocation:location.coordinate]
            map:^(OWCondition *condition){
                @strongify(self);
                return [self updateDataWith:condition andOzone:ozone];
            }]
            // TODO: change architecture so this isn't a side effect.
            doNext:^(OWViewData *data) {
                self.currentWeather = data;
            }];
}

-(RACSignal *)updateHourlyForecastForLocation:(CLLocation *)location andOzoneForecast:(NSArray *)ozone {
    @weakify(self);
    return [[[self.client fetchHourlyForecastForLocation:location.coordinate]
            map:^(NSArray *forecast){
                RACSequence *hourly = forecast.rac_sequence;
                return [[hourly map:^(OWCondition *condition){
                    if (!condition.latitude) { // TODO: fix this with another OWConditions subclass. try here first.
                        condition.latitude = @(location.coordinate.latitude);
                        condition.longitude = @(location.coordinate.longitude);
                    }
                    @strongify(self);
                   return [self updateDataWith:condition andOzone:ozone];
                }] array];
            }]
            doNext:^(NSArray *hourlyData) {
                self.hourlyForecast = hourlyData;
            }];
}

-(RACSignal *)updateDailyForecastForLocation:(CLLocation *)location andOzoneForecast:(NSArray *)ozone {
    @weakify(self);
    return [[[self.client fetchDailyForecastForLocation:location.coordinate]
            map:^(NSArray *forecast){
                RACSequence *daily = forecast.rac_sequence;
                return [[[daily filter:^BOOL(OWCondition *condition) {
                            return condition.description.length > 2;
                }] map:^(OWCondition *condition) {
                            if (!condition.latitude) { // TODO: fix this with another OWConditions subclass. try here first.
                                condition.latitude = @(location.coordinate.latitude);
                                condition.longitude = @(location.coordinate.longitude);
                            }
                            @strongify(self);
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
    
    OWViewData *viewData = [[OWViewData alloc] initWithConditions:conditions andOzone:ozoneLevels[keeper]];  
    
    return viewData;
}


@end
