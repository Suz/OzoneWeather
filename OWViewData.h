//
//  OWViewData.h
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 16/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OWCondition.h"
#import "OWOzoneLevel.h"

@interface OWViewData : NSObject 

@property (nonatomic, copy, readonly) NSDate *date;
@property (nonatomic, copy, readonly) NSNumber *temperature;
@property (nonatomic, copy, readonly) NSNumber *hiTemp;
@property (nonatomic, copy, readonly) NSNumber *loTemp;
@property (nonatomic, copy, readonly) NSString *locationName;
@property (nonatomic, copy, readonly) NSDate *sunrise;
@property (nonatomic, copy, readonly) NSDate *sunset;
@property (nonatomic, copy, readonly) NSString *conditionDescription;
@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, strong) NSNumber *icon;

@property (nonatomic, copy, readonly) NSString *columnOzone; // Dobson Units
@property (nonatomic, copy, readonly) NSString *uvIndex;    // filtered by weather.
@property (nonatomic, copy, readonly) NSString *maxUVIndex; // noon value, not filtered
@property (nonatomic, copy, readonly) NSString *vitaminDTime;   // minutes

-(id)initWithConditions:(OWCondition *)conditionsData andOzone:(OWOzoneLevel *)ozoneData;

- (NSString *)weatherImageName;
- (UIColor *)uvDangerLevel;
- (UIColor *)maxUVDangerLevel;

@end
