//
//  OWOzoneLevel.h
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@interface OWOzoneLevel : NSObject

@property (nonatomic, copy) NSDate *ozoneDate;
@property (nonatomic, assign) CLLocationCoordinate2D ozoneLocation;
@property (nonatomic, assign) CGFloat ozoneLevel;

@end
