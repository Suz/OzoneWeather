//
//  OWManager.h
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

@import Foundation;
@import CoreLocation;
#import <ReactiveCocoa/ReactiveCocoa/ReactiveCocoa.h>

#import "OWCondition.h"

@interface OWManager : NSObject  <CLLocationManagerDelegate>

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) OWCondition *currentCondition;
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;
@property (nonatomic, strong, readonly) NSArray *ozoneForecast;

//- (RACSignal *)currentConditions;
//- (RACSignal *)hourlyConditions;
//- (RACSignal *)dailyConditions;
//- (RACSignal *)ozoneConditions;

-(void)findCurrentLocation;

@end
