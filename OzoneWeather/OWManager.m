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

// set properties to 'readwrite' privately
@property (nonatomic, strong, readwrite) OWCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) OWClient *client;

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
              return [RACSignal merge:@[
                                        [self updateCurrentConditions],
                                        [self updateHourlyForecast],
                                        [self updateDailyForecast],
                                        [self updateOzoneForecast]
                                        ]];
          }] deliverOn:RACScheduler.mainThreadScheduler]
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

-(RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(OWCondition *condition) {
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

-(RACSignal *)updateOzoneForecast {
    return [[self.client fetchOzoneForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

@end
