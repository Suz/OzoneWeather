//
//  OWSolarWrapper.h
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 14/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrenaLib.h"

@interface OWSolarWrapper : NSObject

extern NSString *const kZenithAngleKey;
extern NSString *const kAzimuthAngleKey;
extern NSString *const kSunriseKey;
extern NSString *const kSunsetKey;
extern NSString *const kSolarNoonKey;

-(NSDictionary *) solarAnglesForDate:(NSDate *)date atLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude;
-(NSDictionary *) sunTimesFor:(NSDate *)date atLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude;
-(NSNumber *)earthSunDistanceFor:(NSDate *)date;

@end
