//
//  OWCondition.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWCondition.h"

@implementation OWCondition

+ (NSDictionary *)imageMap {
    static NSDictionary *_imageMap = nil;
    if (! _imageMap) {
        _imageMap = @{
            @"01d"  :  @"weather-clear",
            @"02d"  :  @"weather-few",
            @"03d"  :  @"weather-few",
            @"04d"  :  @"weather-broken",
            @"09d"  :  @"weather-shower",
            @"10d"  :  @"weather-rain",
            @"11d"  :  @"weather-tstorm",
            @"13d"  :  @"weather-snow",
            @"50d"  :  @"weather-mist",
            @"01n"  :  @"weather-moon",
            @"02n"  :  @"weather-few-night",
            @"03n"  :  @"weather-few-night",
            @"04n"  :  @"weather-broken",
            @"09n"  :  @"weather-shower",
            @"10n"  :  @"weather-rain-night",
            @"11n"  :  @"weather-tstorm",
            @"13n"  :  @"weather-snow",
            @"50d"  :  @"weather-mist",
        };
    }
    return _imageMap;
}

- (NSString *)imageName {
    return [OWCondition imageMap][self.icon];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"date"            : @"dt",
             @"locationName"    : @"name",
             @"humidity"        : @"main.humidity",
             @"temperature"     : @"main.temp",
             @"hiTemp"          : @"main.temp_max",
             @"loTemp"          : @"main.temp_min",
             @"sunrise"         : @"sys.sunrise",
             @"sunset"          : @"sys.sunset",
             @"conditionDescription" : @"weather.description",
             @"condition"       : @"weather.main",
             @"icon"            : @"weather.icon",
             @"windBearing"     : @"wind.deg",
             @"windSpeed"       : @"wind.speed"
             };
}

// Value Transformations:

+ (NSValueTransformer *)dateJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str){
        return [NSDate dateWithTimeIntervalSince1970:str.floatValue];
    } reverseBlock:^(NSDate *date) {
        return [NSString stringWithFormat:@"%f", [date timeIntervalSince1970]];
    }];
}

+ (NSValueTransformer *)sunriseJSONTransformer {
    return [self dateJSONTransformer];
}

+ (NSValueTransformer *)sunsetJSONTransformer {
    return [self dateJSONTransformer];
}

+ (NSValueTransformer *)conditionDescriptionJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSArray *arr){
        return [arr firstObject];
    } reverseBlock:^(NSString *str) {
        return @[str];
    }];
}

#define MPS_TO_MPH 2.23694f

+ (NSValueTransformer *)windSpeedJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *speedMPS) {
        return @(speedMPS.floatValue*MPS_TO_MPH);
    } reverseBlock:^(NSNumber *speedMPH) {
        return @(speedMPH.floatValue/MPS_TO_MPH);
    }];
}

@end
