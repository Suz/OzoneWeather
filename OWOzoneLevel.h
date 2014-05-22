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

@property (nonatomic, strong) NSDate *ozoneDate;
@property (nonatomic, strong) NSNumber *uvIndex;
@property (nonatomic, strong) NSNumber *columnOzone;

- (OWOzoneLevel *)initWithDictionary:(NSDictionary *)dict error:(NSError **)error;

@end
