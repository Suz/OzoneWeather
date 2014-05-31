
//
//  OWSolarWrapper.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 14/05/2014.
//  Open Source, not sure which license
//
//  This is a basic Obj-C wrapper around GrenaLib and SunToolslib
//  C libraries for calculating solar positions in the sky.
//

#import "OWSolarWrapper.h"

@interface OWSolarWrapper ()

// date functions
-(NSNumber *) julianDateFor:(NSDate *)date;
-(NSNumber *) julianDateRelative2003For:(NSDate *)date;

// basic astronomy calcs
-(NSNumber *) equationOfTimeFor:(NSDate *)date;
-(NSDictionary *) solarParametersForDate:(NSDate *)date;

@end

@implementation OWSolarWrapper

// Constants for passing information around:
// TODO: (too many of these. simplify!)
static NSString *const kJulianDateKey   =   @"kJulianDateKey";
NSString *const kSolarRightAscensionKey  =   @"kSolarRightAscensionKey";
NSString *const kSolarDeclinationKey     =   @"kSolarDeclinationKey";
NSString *const kSolarNoonKey    =   @"kSolarNoonKey";
NSString *const kSunriseKey      =   @"kSunriseKey";
NSString *const kSunsetKey       =   @"kSunsetKey";
static NSString *const kDateKey         =   @"date";
static NSString *const kLatitudeKey     =   @"latitude";
static NSString *const kLongitudeKey    =   @"longitude";
NSString *const kZenithAngleKey  =   @"zenithAngle";
NSString *const kAzimuthAngleKey =   @"azimuthAngle";


// Julian Date:
// J2000 epoch is defined with JD = 2451545.0 for TT Jan 1 2000, noon GMT
// At this date, UTC varied from TT by 64.184s
// Mac standard time is based on UTC Jan 1 2001, 00:00:00. This is
// 365.5 days after the definition of J2000. (it was a leap year)
// Note: Grena's calculations are based on a Julian date referenced to 2003!
-(NSNumber *)julianDateFor:(NSDate *)date {
    
    // absolute reference date of 1 Jan 2001 00:00:00 GMT.
	CFAbsoluteTime dateNum = CFDateGetAbsoluteTime( (CFDateRef) date);
    
	double julianDate = (dateNum/86400.0) + (365.5 + 64.184/86400.0) + 2451545.0;
	
    return @(julianDate);
}

-(NSNumber *)julianDateRelative2003For:(NSDate *)date {
	
	// Start date for Roberto Grena calculations = Jan 1, 2003 12:00:00
    // Paper in: Solar Energy 82 (2008) 462–470
	// See footnote on page 463:
    // JD = JD_t + 2452640
    
    NSNumber *jd2000 = [self julianDateFor:date];
    double grenaJD = jd2000.doubleValue - 2452640.0;
    return [NSNumber numberWithDouble:grenaJD];
}

/* simple algorithm for computing the Sun's angular coordinates to an 
 * accuracy of about 1 arcminute within two centuries of 2000.
 *
 * http://aa.usno.navy.mil/faq/docs/SunApprox.php
 * Julian Date (rel 2000): D = JD – 2451545.0
 * Mean anomaly of the Sun:	g = 357.529 + 0.98560028 D
 * earth-sun distance: R = 1.00014 – 0.01671 cos g – 0.00014 cos 2g
 *
 */
-(NSNumber *)earthSunDistanceFor:(NSDate *)date{
    
    double julianDate = [self julianDateFor:date].doubleValue;
    double jd = julianDate - 2451545.0;
    double meanAnomaly = 357.529 + 0.98560028 * jd;
    double radius = 1.00014 - 0.01671 * cos(degToRad(meanAnomaly)) - 0.00014*cos(degToRad(2*meanAnomaly));
    
    return @(radius);
}



#pragma mark ============== solar calculations (Grena paper) ==============

// heliocentric and geocentric, but not topocentric
-(NSDictionary *) solarParametersForDate:(NSDate *)date {
	// need date relative 2003
    double julianDate = [self julianDateRelative2003For:date].doubleValue;
	//NSLog(@"using julian %.6f", julianDate);
    
	double grenaHelioLong =calcHelioLongGrena(julianDate);
	//NSLog(@"Grena helio Longitude is %.6f",grenaHelioLong*180/M_PI);

	datapair RA_Dec_Grena;
	calcGeocentricGrena(julianDate, grenaHelioLong, &RA_Dec_Grena);
	
	double solarRightAscension = radToDeg(RA_Dec_Grena.a);
	double solarDeclination = radToDeg(RA_Dec_Grena.b);
	//NSLog(@"Right Ascension %.4f ° and Declination %.4f °",solarRightAscension, solarDeclination);

    // ----- packaging:
    NSDictionary *results = @{
                              kJulianDateKey : @(julianDate),
                              kSolarRightAscensionKey : @(solarRightAscension),
                              kSolarDeclinationKey  : @(solarDeclination),
                              };
    
    return results;
}

// topocentric calculations:  depend on observer's position on the planet
-(NSDictionary *) solarAnglesForDate:(NSDate *)date atLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude {
    
    // calculate orbital geometry stuff for this date
    NSDictionary *solarPosition = [self solarParametersForDate:date];

	double earthTime = [[solarPosition objectForKey:kJulianDateKey] doubleValue] + (65.984/86400);
	//NSLog(@"using date %.4f",earthTime);
	double localPressure = 1.00; // in atm
	double localTemperature = 10.0; // in °C
	//NSLog(@"temperature %.1f °C and pressure %.4f atm",localTemperature, localPressure);
	
	datapair RA_Dec;
    double RA = [[solarPosition objectForKey:kSolarRightAscensionKey] doubleValue];
    if (RA < 0) {
        RA = 360 + RA;
    }
    
    RA = degToRad(RA);
	RA_Dec.a = RA; //degToRad([[solarPosition objectForKey:kSolarRightAscensionKey] doubleValue]);
	RA_Dec.b = degToRad([[solarPosition objectForKey:kSolarDeclinationKey] doubleValue]);
	
	datapair obsPT;
	obsPT.a = localPressure;
	obsPT.b = localTemperature;
	
	datapair obsLatLong; // give in degrees, the SunPoseDay method converts  to rads.
	obsLatLong.a = latitude.doubleValue;
	obsLatLong.b = longitude.doubleValue;
	
	datapair zenAzi;
	calcTopocentricGrena(earthTime, &RA_Dec, &obsLatLong, &obsPT, &zenAzi);
	//NSLog(@"The Grena sun is at Zenith angle %.4f, azimuth %.4f.", (180/M_PI)* zenAzi.a, (180/M_PI)* (zenAzi.b));
    
    NSDictionary *results = @{@"date" : date,
                              @"latitude" : latitude,
                              @"longitude" : longitude,
                              @"zenithAngle" : [NSNumber numberWithDouble: radToDeg(zenAzi.a)],
                              @"azimuthAngle" : [NSNumber numberWithDouble: radToDeg(zenAzi.b)]
                              };
	
	return results;
}

#pragma mark =========================   Sunrise, Noon, Sunset Calculations ========================
-(NSDate *)dayFractionToDate:(double)dayFrac onDate:(NSDate *)date
{
    int hour = floor(dayFrac*24);
    int minute = floor( ((dayFrac*24) - hour )*60);
    int second = rint( ((((dayFrac*24) - hour )*60) -minute) *60);
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
	[gregorian setTimeZone:[NSTimeZone systemTimeZone]];
	
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    
    // needs to be reset to get date from view controller.
    comps = [gregorian components:unitFlags fromDate:date];
    [comps setHour:hour];
    [comps setMinute:minute];
    [comps setSecond:second];
    
	return ([gregorian dateFromComponents:comps]);
}


-(NSNumber *)equationOfTimeFor:(NSDate *)date {
    // approximate solution based on AA: http://aa.quae.nl/en/index.html
    // (select 'calculate' on the left menu, 'position of the sun', and section 9
    // accessed May 2014
    
    // We're looking for the difference between acutal solar noon and average solar noon in degrees at our location
    // and date.
    // The equation can be divided into orbital contributions (C) and seasonal contributions (S)
    //   ∆t ≈ C₁ sin M + A₂ sin(2 λSun)
    
    //  equation of center:
    //  C ≈ C₁ sin M + C₂ sin(2 M) + C₃ sin(3 M) + ...  (for earth's orbit, only the first 3 matter)
    //  [C₁, C₂, C₃] = [1.9148,	0.0200,	0.0003]
    //
    // mean anomaly:
    //  M = M₀ + M₁*(J − J2000);   J2000 = 2451545 (or in our case, J - J2003)
    //  [M₀, M₁] = [357.5291	0.98560028] in degree and degrees/day, respectively.
    //
    //  For the Earth, you can also use  M = −3.59° + 0.98560° d
    //  where d is the time since 00:00 UTC at the beginning of the most recent January 1st, measured in (whole and fractional) days.
    //
    //  right ascension:
    //  αsun ≈ λsun + A₂ sin(2 λsun) + A₄ sin(4 λsun) + A₆ sin(6 λsun)
    //  [A₂	A₄	A₆] = [−2.4680	 0.0530	-0.0014]
    //
    //  ecliptical longitude:
    //  λsun = M + Π + C + 180°
    //  with perihelion, Π = 102.9372
    //  λsun = 279.3472° + 0.98560° d + 1.9148 ( −3.59° + 0.98560° d )
    //  λsun = 272.3473° + 2.872827 d
    //
    //  Putting it all together, we get:
    //  ∆t ≈ C₁ sin M + A₂ sin(2 λSun)
    //
    
    // d
    double jd = [self julianDateFor:date].doubleValue - 2451545.0;
    
    // M   --- (AKA meanAnomaly)
    double meanLongitude = degToRad(357.529 + (0.98560028 * jd));

    // C
    double eqOfCenter = degToRad(1.9148) * sin( meanLongitude ) +
                        degToRad(0.0200) * sin( 2*meanLongitude ) +
                        degToRad(0.0003) * sin( 3*meanLongitude );
    
    // lambda_sun
    double eclipLongitude = M_PI + degToRad(102.9372) + meanLongitude + eqOfCenter;
    
    double eqOfTime =  degToRad(1.9148)*sin(meanLongitude) + degToRad(-2.4680)*sin( 2*eclipLongitude); // radians
    
    return @( 4*radToDeg(eqOfTime) );   // return value in minutes:
}

- (NSDictionary *) sunTimesFor:(NSDate *)date atLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude {
    
    // calculate Solar Parameters (geocentric, but not topocentric)
    NSDictionary *solarPosition = [self solarParametersForDate:date];
    
    double geocDeclination = [[solarPosition objectForKey:kSolarDeclinationKey] doubleValue];

    double obsLat = M_PI/180 * latitude.doubleValue;

    NSInteger timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMTForDate:date];
    double offset = timeZoneOffset/3600.0;  // difference from GMT in Hours

    // calculate final values.
    double haRise = radToDeg(acos( 0.99961723/cos(obsLat)*cos(geocDeclination)-tan(obsLat)*tan(geocDeclination) ));
    //NSLog(@"The HA sunrise angle is %.4f.", haRise);
    
    double equationOfTime = [[self equationOfTimeFor:date] doubleValue];

    // dates as day-fractions
    double noonTime = (720 - 4*longitude.doubleValue - equationOfTime + offset*60) / 1440;
    double riseTime = noonTime - haRise*4/1440;
    double setTime = noonTime + haRise*4/1440;
    
    return @{ kSolarNoonKey     :  [self dayFractionToDate:noonTime onDate:date],
              kSunriseKey       :  [self dayFractionToDate:riseTime onDate:date],
              kSunsetKey        :  [self dayFractionToDate:setTime onDate:date]
            };
}

@end
