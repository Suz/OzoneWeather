//
//  OWOzoneLevel.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 09/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWOzoneLevel.h"

@implementation OWOzoneLevel

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
// Wouldn't that be a nice addition to the framework?!
-(instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)error {
    self = [self init];
    if (self == nil) return nil;
    
    // Based on dictionary from TEMIS.nl, processed through filter stages in OWClient.m RACsignal pipeline
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter *temisDateFormatter = [[NSDateFormatter alloc] init];
    
    // The date string from TEMIS contains English month names, based on a Georgian calendar
    // however, the time is solar noon for the location.
    // details at http://www.temis.nl/uvradiation/nrt/uvresol.html
    // TODO:  set time to solar noon for requested lat/lon
    [temisDateFormatter setLocale:enUSPOSIXLocale];
    [temisDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [temisDateFormatter setDateFormat:@"d MMM yyyy"];

    //TODO: improve this by using constant strings for dictionary keys!
    for (NSString *key in dict) {
        if ([key rangeOfString:@"date" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // found the date
            self.ozoneDate = [temisDateFormatter dateFromString:[dict objectForKey:key]];
        } else if ([key rangeOfString:@"ozone" options:NSCaseInsensitiveSearch].location != NSNotFound){
            // found the ozone level
            self.columnOzone = @([[dict objectForKey:key] stringByReplacingOccurrencesOfString:@"DU" withString:@""].floatValue);
        } else if ([key rangeOfString:@"uv" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // must be uvIndex
            self.uvIndex = @([[dict objectForKey:key] floatValue]);
        } else {
             // TODO: proper error handling
            NSLog(@"Error: ozone dictionary key not recognized: %@", key);
        }
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
