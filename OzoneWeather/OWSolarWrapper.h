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

-(NSDictionary *)solarAnglesForDate:(NSDate *)date atLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude;

@end
