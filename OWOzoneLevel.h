//
//  OWOzoneLevel.h
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import <Mantle.h>
#import "MTLModel.h"

@interface OWOzoneLevel : MTLModel <MTLJSONSerializing>

extern NSString *const kLocationKey;
extern NSString *const kOzoneDateKey;
extern NSString *const kColumnOzoneKey;
extern NSString *const kUVIndexKey;

@property (nonatomic, strong) NSDate *ozoneDate;  // solar noon at location
@property (nonatomic, strong) NSNumber *uvIndex;  // max UVIndex for data (solar noon, clear sky)
@property (nonatomic, strong) NSNumber *columnOzone;

- (OWOzoneLevel *)initWithDictionary:(NSDictionary *)dict error:(NSError **)error;

@end
