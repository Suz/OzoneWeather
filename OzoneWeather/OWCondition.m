//
//  OWCondition.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWCondition.h"

@implementation OWCondition

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"date"            : @"dt",
             @"locationName"    : @"name",
             @"latitude"        : @"coord.lat",
             @"longitude"       : @"coord.lon",
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
             @"windSpeed"       : @"wind.speed",
             @"cloudCover"      : @"clouds.all"
             };
}

# pragma mark ===========   Value Transformations:   =============

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

+(NSValueTransformer *)conditionJSONTransformer {
    return [self conditionDescriptionJSONTransformer];
}

+ (NSValueTransformer *)iconJSONTransformer {
    return [self conditionDescriptionJSONTransformer];
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
