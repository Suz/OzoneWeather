//
//  OWDailyForecast.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWDailyForecast.h"

@implementation OWDailyForecast

+(NSDictionary *)JSONKeyPathsByPropertyKey {
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    
    paths[@"hiTemp"] = @"temp.max";
    paths[@"loTemp"] = @"temp.min";
    paths[@"cloudCover"] = @"clouds";
    return paths;
}
@end
