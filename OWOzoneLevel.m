//
//  OWOzoneLevel.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

@import CoreLocation;
#import "OWOzoneLevel.h"
#import "OWSolarWrapper.h"

@implementation OWOzoneLevel

NSString *const kLocationKey   =   @"kLocationKey";
NSString *const kOzoneDateKey   =   @"kOzoneDateKey";
NSString *const kColumnOzoneKey =   @"kColumnOzoneKey";
NSString *const kUVIndexKey     =   @"kUVIndexKey";


@synthesize ozoneDate;
@synthesize columnOzone;
@synthesize uvIndex;

-(id)init {
    if (self = [super init]){
        
    }
    return self;
}

// replaces initWithDictionary: error: method in MTLModel.m
// There are no methods for using NSTransformers with a dictionary in MTLModel.
-(instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)error {
    self = [self init];
    if (self == nil) return nil;
    
    // Based on dictionary from TEMIS.nl, processed through filter stages in OWClient.m RACsignal pipeline
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter *temisDateFormatter = [[NSDateFormatter alloc] init];
    
    // The date string from TEMIS contains English month names, based on a Georgian calendar
    // however, the time is solar noon for the location.
    // details at http://www.temis.nl/uvradiation/nrt/uvresol.html
    // I'm setting the ozone date to solar noon for the location.
    [temisDateFormatter setLocale:enUSPOSIXLocale];
    [temisDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [temisDateFormatter setDateFormat:@"d MMM yyyy"];
    
    NSDate *nominalDate = [temisDateFormatter dateFromString:[dict objectForKey:kOzoneDateKey]];
    CLLocation *location = [dict objectForKey:kLocationKey];
    OWSolarWrapper *calculator = [[OWSolarWrapper alloc] init];
    NSDictionary *sunTimes = [calculator sunTimesFor:nominalDate
                                          atLatitude:@(location.coordinate.latitude)
                                        andLongitude:@(location.coordinate.longitude)];
    self.ozoneDate = [sunTimes objectForKey:kSolarNoonKey];
    
    NSString *ozoneString = [dict objectForKey:kColumnOzoneKey];
    if ([ozoneString rangeOfString:@"DU"].location == NSNotFound) {
        NSLog(@"Error: Is this really the column ozone? %@",ozoneString);
    }
    self.columnOzone = @([ozoneString stringByReplacingOccurrencesOfString:@"DU" withString:@""].floatValue);
   
    self.uvIndex = @([[dict objectForKey:kUVIndexKey] floatValue]);
    
    if (self.uvIndex.floatValue > 20) {
        NSLog(@"Error: Is this really the UVIndex? %@", self.uvIndex);
    }
    
    return self;
}

// might be useful with a different incoming data format
+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"date"            : @"date",
             @"columnOzone"     : @"columnOzone",
             @"uvIndex"         : @"uvIndex"
             };
}

@end
