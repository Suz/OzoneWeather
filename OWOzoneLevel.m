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

- (UIColor *)dangerLevel {
    
    CGFloat num = self.uvIndex.floatValue;
    if (num < 2) {
        // very low. no chance of sunburn
        return [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
    } else if (num < 4) {
        // low, little chance
        return [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
    } else if (num < 6) {
        // mid, some chance
        return [UIColor colorWithRed:0.3 green:0.7 blue:0 alpha:0.2];
    } else if (num < 8) {
        // low, little chance
        return [UIColor colorWithRed:0.5 green:0.5 blue:0 alpha:0.2];
    } else if (num < 10) {
        // high
        return [UIColor colorWithRed:0.7 green:0.1 blue:0 alpha:0.5];
    }  // will only reach here if extreme!
    return [UIColor colorWithRed:1 green:0 blue:0 alpha:0];
}

@end
