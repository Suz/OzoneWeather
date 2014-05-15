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
-(NSNumber *) julianCenturyForJulianDate:(NSNumber *)julianDate;
-(NSNumber *) julianDateRelative2003For:(NSDate *)date;

// basic astronomy calcs
-(NSNumber *) equationOfTimeFor:(NSDate *)date;

@end

@implementation OWSolarWrapper

// Constants for passing information around:
static NSString *const kJulianDateKey = @"kJulianDateKey";
static NSString *const kSolarRightAscensionKey = @"kSolarRightAscensionKey";
static NSString *const kSolarDeclinationKey = @"kSolarDeclinationKey";
static NSString *const kSolarNoonKey = @"kSolarNoonKey";
static NSString *const kSunriseKey = @"kSunriseKey";
static NSString *const kSunsetKey = @"kSunsetKey";

// Julian Date:
// J2000 epoch is defined with JD = 2451545.0 for TT Jan 1 2000, noon GMT
// At this date, UTC varied from TT by 64.184s
// Mac standard time is based on UTC Jan 1 2001, 00:00:00. This is
// 364.5 days after the definition of J2000.
// Note: Grena's calculations are based on a Julian date referenced to 2003!
-(NSNumber *) julianDateFor:(NSDate *)date {
    
    // referenced to Jan 1, 2000
	CFAbsoluteTime dateNum = CFDateGetAbsoluteTime( (CFDateRef) date);
    
	double julianDate = (dateNum/86400.0) + (364.5 + 64.184/86400.0) + 2451545.0;
	
    return @(julianDate);
}

-(NSNumber *) julianCenturyForJulianDate:(NSNumber *)julianDate {
    
    // referenced to Jan 1, 2000
    double julianCentury = (julianDate.floatValue-2451545.0) / 36525;
    
    return @(julianCentury);
}

-(NSNumber *) julianDateRelative2003For:(NSDate *)date {
	
    // number of seconds since Jan 1, 2001 00:00:00
	CFAbsoluteTime ThisTime = CFDateGetAbsoluteTime( (CFDateRef) date);
	
	// Start date for Roberto Grena calculations = Jan 1, 2003 12:00:00 !! NOON
	// subtract 365*2 to bring up to midnight Jan1 2003
	// subtract 0.5 and 65.2/86400 to get to Noon and convert to TT.
    double julianDate = (ThisTime/86400.0) - (365.0*2) - (0.5 + 65.2/86400.0); //+ (364.5 + 64.184/86400.0)
		
	return @(julianDate);
	
}


/* ==========  NOAA version ==================
 
 -(NSDictionary *) solarParametersForDate:(NSDate *)date {
	
    // ----- Dates:
	// need date relative 2000
	double julianDate = [self julianDateFor:date].floatValue;
    double julianCentury = [self julianCenturyForJulianDate:@(julianDate)].floatValue;
	
    // ----- Base Calculations:
	double anomaly = MeanAnomalySun(julianCentury);
	//NSLog(@"The anomaly is %.3f",anomaly);
	double meanLong = MeanLongSun(julianCentury);
	//NSLog(@"The Mean Longitude of the sun is %.4f", meanLong);
	double sunCenter = SunEquationOfCenter(julianCentury, anomaly);
	//NSLog(@"The SunCenter is %.4f",sunCenter);
	
	double apparentLong = SunApparentLongtitude(meanLong, sunCenter, julianCentury);
	//NSLog(@"The Apparent Longitude of the sun is %.4f", apparentLong);
    
	double obliquityEclipt = ObliquityEcliptic(julianCentury);
	double earthEccent = EccOrbitEarth(julianCentury);
	
    // ----- Final Result Calculations:
    double earthSunDistance = SunRadialVector(anomaly, sunCenter, earthEccent);
	double solarRightAscension = SunRightAscension(obliquityEclipt, apparentLong);
	double solarDeclination = SunDeclination(obliquityEclipt, apparentLong);
	
	double equationOfTime = EquationOfTime( Var_y(obliquityEclipt), meanLong, anomaly, earthEccent);
	
    // ----- packaging:
    NSDictionary *results = @{@"earthSunDistance" : @(earthSunDistance),
                              @"solarRightAscension" : @(solarRightAscension),
                              @"solarDeclination"  : @(solarDeclination),
                              @"equationOfTime"  : @(equationOfTime),
                              };
    
    return results;
    
	//NSLog(@"The sun is at RA %.4f, Dec %.4f.", solarRightAscension, solarDeclination);
	//NSLog(@"The equation of Time is %.4f.", equationOfTime);
    
}
*/

#pragma mark ============== solar calculations (Grena paper) ==============

// heliocentric and geocentric, but not topocentric
-(NSDictionary *) solarParametersForDate:(NSDate *)date {
	// need date relative 2003
    double julianDate = [self julianDateRelative2003For:date].floatValue;
	//NSLog(@"using julian %.4f",self.julianDate);
    
	double grenaHelioLong =calcHelioLongGrena(julianDate);
	//NSLog(@"Grena helio Longitude is %.4f",grenaHelioLong*180/M_PI);

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
    
    //double grenaJDE = (julianDate-2451545.0) - (365.0*2) + (65.984/86400);
    //TODO:  check calculation WRT terrestrial time:  might be subtracting 65.984/86400 twice.

	double earthTime = [[solarPosition objectForKey:kJulianDateKey] floatValue] + (65.984/86400);
	//NSLog(@"using date %.4f",earthTime);
	double localPressure = 1.00; // in atm
	double localTemperature = 10.0; // in °C
	//NSLog(@"temperature %.1f °C and pressure %.4f atm",localTemperature, localPressure);
	
	datapair RA_Dec;
	RA_Dec.a = degToRad([[solarPosition objectForKey:kSolarRightAscensionKey] floatValue]);
	RA_Dec.b = degToRad([[solarPosition objectForKey:kSolarDeclinationKey] floatValue]);
	
	datapair obsPT;
	obsPT.a = localPressure;
	obsPT.b = localTemperature;
	
	datapair obsLatLong; // give in degrees, the SunPoseDay method converts  to rads.
	obsLatLong.a = latitude.floatValue;
	obsLatLong.b = longitude.floatValue;
	
	datapair zenAzi;
	calcTopocentricGrena(earthTime, &RA_Dec, &obsLatLong, &obsPT, &zenAzi);
	//NSLog(@"The Grena sun is at Zenith angle %.4f, azimuth %.4f.", (180/M_PI)* zenAzi.a, (180/M_PI)* (zenAzi.b));
    
    NSDictionary *results = @{@"date" : date,
                              @"latitude" : latitude,
                              @"longitude" : longitude,
                              @"zenithAngle" : [NSNumber numberWithDouble: zenAzi.a],
                              @"azimuthAngle" : [NSNumber numberWithDouble: zenAzi.b]
                              };
	
	return results;
}

#pragma mark =========================   Sunrise, Noon, Sunset Calculations ========================

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
    // calculation approach checked in equation_of_time.ipynb
    // including graphical comparison with nice graph at: http://aa.usno.navy.mil/faq/docs/eqtime.php
    // (may 2014 srk)
    
    // get day of the year. In this case ordinal day is close enough.
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSInteger dayOfYear = [currentCalendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:date];
    // d
    double jd = 1.0 * dayOfYear;
    
    // M
    double meanLongitude = degToRad( -3.59 + (0.98560 * jd) );
    
    // C
    double eqOfCenter = degToRad(1.9148) * sin( meanLongitude ) +
                        degToRad(0.0200) * sin( 2*meanLongitude ) +
                        degToRad(0.0003) * sin( 3*meanLongitude );
    
    // lambda_sun
    double eclipLongitude = M_PI + degToRad(102.9372) + meanLongitude + eqOfCenter;
    
    double eqOfTime =  degToRad(1.9148)*sin(meanLongitude) + degToRad(-2.4680)*sin( 2*eclipLongitude); // radians
    
    return @( 4*degToRad(eqOfTime) );   // return value in minutes:
}

- (NSDictionary *) sunTimesFor:(NSDate *)date atLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude {
    
    // calculate Solar Parameters (geocentric, but not topocentric)
    NSDictionary *solarPosition = [self solarParametersForDate:date];
    
    double geocDeclination = [[solarPosition objectForKey:kSolarDeclinationKey] floatValue];

    double obsLat = M_PI/180 * latitude.floatValue;

    NSInteger timeZoneOffset = [[NSTimeZone defaultTimeZone] secondsFromGMTForDate:date];
    float offset = timeZoneOffset/3600.0;  // difference from GMT in Hours

    // calculate final values.
    double haRise = radToDeg(acos( 0.99961723/cos(obsLat)*cos(geocDeclination)-tan(obsLat)*tan(geocDeclination) ));
    //NSLog(@"The HA sunrise angle is %.4f.", haRise);
    
    double equationOfTime = [[self equationOfTimeFor:date] floatValue];

    double noonTime = (720 - 4*longitude.floatValue - equationOfTime + offset*60) / 1440;
    double riseTime = noonTime - haRise*4/1440;
    double setTime = noonTime + haRise*4/1440;
    
    return @{ kSolarNoonKey     :   @(noonTime),
              kSunriseKey       :   @(riseTime),
              kSunsetKey        :   @(setTime)
            };
}

@end
