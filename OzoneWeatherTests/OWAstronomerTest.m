//
//  OWAstronomerTest.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 27/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OWSolarWrapper.h"
@import CoreLocation;

// category used to test private methods
// based on SO answer: http://stackoverflow.com/a/1099281/962009

@interface OWSolarWrapper (Test)

// private functions from OWSolarWrapper.m
// date functions
-(NSNumber *) julianDateFor:(NSDate *)date;
-(NSNumber *) julianCenturyForJulianDate:(NSNumber *)julianDate;
-(NSNumber *) julianDateRelative2003For:(NSDate *)date;

// basic astronomy calcs
-(NSNumber *) equationOfTimeFor:(NSDate *)date;
-(NSDictionary *) solarParametersForDate:(NSDate *)date;

@end

@interface OWAstronomerTest : XCTestCase

@property OWSolarWrapper *astronomer;
@property NSDateFormatter *dateFormatter;

@end

@implementation OWAstronomerTest

- (void)setUp
{
    [super setUp];

    _astronomer = [[OWSolarWrapper alloc] init];
    
    // Create a date parser so we can hand in calendar dates easily.
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    _dateFormatter = [[NSDateFormatter alloc] init];
    
    [_dateFormatter setLocale:enUSPOSIXLocale];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:(3600*2)]];
    [_dateFormatter setDateFormat:@"yyyy'-'M'-'dd' 'HH':'mm':'ss"];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testJulianDate
{
    // Mac Reference date is Midnight Jan 1 2001;
    // To get to Noon Jan 1 2000:
    //      Subtract 366 days (in seconds) -- Yes, 2000 was a leap year.
    //      add 0.5 days (in seconds) to get from 00:00:00 to 12:00:00.
    // This just tests the 0 value.
    NSDate *Jan_1_2000 = [NSDate dateWithTimeIntervalSinceReferenceDate:(-3600 * 24 * 365.5)];
    NSNumber *result = [_astronomer julianDateFor:Jan_1_2000];
    XCTAssertEqualWithAccuracy(2451545.0, result.doubleValue, .0005, @"JulianDate fails on 2000 reference");

     /* test the calculation with multiple dates:
     //Reference answers from: http://aa.quae.nl/en/index.html (calculations / dates)
     // calendar date    julian date
     2000−02−29         2451604
     2000−03−01         2451605
     2001−02−28         2451969
     2001−03−01         2451970
     2100−02−28         2488128
     2100−03−01         2488129
     */
    
    NSArray *dateStrings = @[@"2011-07-29 14:00:00", @"2000-02-29 14:00:00", @"2000-03-01 14:00:00", @"2001-02-28 14:00:00", @"2001-03-01 14:00:00", @"2100-02-28 14:00:00",@"2100-03-01 14:00:00"];
    NSArray *refJD = @[@(2455772),@(2451604),@(2451605),@(2451969),@(2451970),@(2488128),@(2488129)];
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expected = [refJD[idx] doubleValue];
        double result = [[_astronomer julianDateFor:testDate] doubleValue];
        XCTAssertEqualWithAccuracy(expected, result, 0.0005, @"JulianDate fail for date: %@", testDate);
    }
}

-(void)testjulianDateRelative2003{
    NSArray *dateStrings = @[@"2011-07-29 14:00:00", @"2000-02-29 14:00:00", @"2000-03-01 14:00:00", @"2001-02-28 14:00:00", @"2001-03-01 14:00:00", @"2100-02-28 14:00:00",@"2100-03-01 14:00:00"];
    NSArray *refJD = @[@(2455772),@(2451604),@(2451605),@(2451969),@(2451970),@(2488128),@(2488129)];
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expected = [refJD[idx] doubleValue] - 2452640.0;
        double result = [[_astronomer julianDateRelative2003For:testDate] doubleValue];
        
        XCTAssertEqualWithAccuracy(expected, result, 0.0005, @"JulianDate2003 fail for date: %@", testDate);
    }
}

-(void)testEarthSunDistance{
    // Expect idstance of about  0.98329 AU at 5am
    // January 4, 2001 -- This morning at 5 o'clock Eastern Standard time (0900 UT) Earth made its annual closest approach to the Sun -- an event astronomers call perihelion.
    // http://science.nasa.gov/science-news/science-at-nasa/2001/ast04jan_1/
    
    // other test distances/ dates from http://en.wikipedia.org/wiki/Apsis (accessed 28 May 2014)
    
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSArray *dateStrings = @[@"2001-01-04 09:00:00",
                             @"2010-01-03 00:09:00",
                             @"2010-07-06 11:30:00",
                             @"2020-01-05 07:48:00",
                             @"2020-07-04 11:35:00"];
    NSArray *refDistances = @[@(.98329), @(.98329), @(1.01671),
                              @(.98329), @(1.01671)];
    
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expected = [refDistances[idx] doubleValue];
        double result = [[_astronomer earthSunDistanceFor:testDate] doubleValue];
        
        XCTAssertEqualWithAccuracy(expected, result, 0.00001, @"Earth-SunDistance fail for date: %@", testDate);
    }
}

-(void)testEquationOfTime{
    // reference values calculated online at:
    // http://www.esrl.noaa.gov/gmd/grad/solcalc/azel.html
    // NOTES:
    //      1) the sign is arbitrary.
    //      2) differences are larger than I'd like!
    //              TODO: improve agreement between NOAA, my calculation!
    
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSArray *dateStrings = @[@"2004-03-21 13:00:00",
                             @"2004-10-15 21:00:00",
                             @"2016-01-15 13:00:00",
                             @"2016-06-12 16:00:00",
                             @"2043-01-03 12:00:00",
                             @"2043-06-12 16:00:00",
                             @"2014-03-20 12:00:00"];
    NSArray *refEOT = @[@(-7.04), @(14.39), @(-9.24),
                              @(0.0), @(-4.4), @(0.06), @(-7.38)];
    
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expected = [refEOT[idx] floatValue];
        double result = [[_astronomer equationOfTimeFor:testDate] doubleValue];
        
        XCTAssertEqualWithAccuracy(expected, result, 0.5, @"Equation of time incorrect for date: %@", testDate);
    }
    
}


-(void)testSolarAngles{
    // meaningful dates: solar noon, mid morning, mid evening
    // use sunpose app to get solar noon values
    
    // Berkeley:
    CLLocation *berkeley = [[CLLocation alloc] initWithLatitude:37.8716 longitude:-122.2728];
    NSTimeZone *berkeleyTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"PST"];
    
    [_dateFormatter setTimeZone:berkeleyTimeZone];
    NSDate *noon = [_dateFormatter dateFromString:@"2014-03-20 13:15:30"];
    
    double expectedZenith = 37.7816;    // equinox:  latitude = height of sun at noon.
    double expectedAzimuth = 180.0;      // sun due south
    
    
    NSDictionary *results = [_astronomer solarAnglesForDate:noon
                                                 atLatitude:@(berkeley.coordinate.latitude)
                                               andLongitude:@(berkeley.coordinate.longitude)];
    
    double resultAzi = [[results objectForKey:@"azimuthAngle"] doubleValue];
    double resultZenith = [[results objectForKey:@"zenithAngle"] doubleValue];

    XCTAssertEqualWithAccuracy(expectedZenith, resultZenith, 0.2, @"Solar Zenith fail: berkeley noon equinox");
    XCTAssertEqualWithAccuracy(expectedAzimuth, resultAzi, 0.5, @"Solar Azimuth fail: berkeley noon equinox");
    
    
    NSDate *sunrise = [_dateFormatter dateFromString:@"2014-03-20 07:11:55"];
    expectedZenith = 90.0;
    expectedAzimuth = 90.0;     // East
    
    results = [_astronomer solarAnglesForDate:sunrise
                                   atLatitude:@(berkeley.coordinate.latitude)
                                 andLongitude:@(berkeley.coordinate.longitude)];
    
    resultAzi = [[results objectForKey:@"azimuthAngle"] doubleValue];
    resultZenith = [[results objectForKey:@"zenithAngle"] doubleValue];
    
    XCTAssertEqualWithAccuracy(expectedZenith, resultZenith, 0.1, @"Solar Zenith fail: berkeley sunrise equinox");
    XCTAssertEqualWithAccuracy(expectedAzimuth, resultAzi, 0.5, @"Solar Azimuth fail: berkeley sunrise equinox");
    
}


-(void)testSolarParameters{
    // NOTE:  Grena algorithm is only good to 2023.
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:(2*3600)]];

    // past, present, future. near equinoxes and solstices.
    NSArray *dateStrings = @[@"2015-03-20 22:45:00", @"2015-06-21 16:38:00",  //equinox, solstice
                             @"2023-09-23 06:45:00", @"2023-12-22 08:00:00"];

    // vernal equinox:  RA=0,               Dec=0,
    // summer solstice: RA = 6hrs = 90°,    Dec = max = 23.44°
    // autumn equinox:  RA = 12 hrs = 180°, Dec = 0
    // winter solsticd: RA = 18 hrs = 270°, Dec = min = -23.44°
    NSArray *refDeclination = @[@(0.0), @(23.44), @(0.0), @(-23.44)];
    NSArray *refRightAscension = @[@(0.0), @(90), @(180), @(270)];
    
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expectedDec = [refDeclination[idx] doubleValue];
        double expectedRA = [refRightAscension[idx] doubleValue];
        NSDictionary *results = [_astronomer solarParametersForDate:testDate];
        
        double resultDec = [[results objectForKey:kSolarDeclinationKey] doubleValue];
        double resultRA = [[results objectForKey:kSolarRightAscensionKey] doubleValue];
        
        if ((resultRA < 0) && (abs(resultRA) > 1)) {
            resultRA = 360 + resultRA;
        }
        
        // TODO: This error is 0.1 - 0.22 °, which is larger than it should be for this algorithm.
        XCTAssertEqualWithAccuracy(expectedDec, resultDec, 0.1, @"Solar Declination fail for date: %@", testDate);
        XCTAssertEqualWithAccuracy(expectedRA, resultRA, 0.25, @"Solar RightAscension fail for date: %@", testDate);
    }
}

-(void)testSunTimes{
    // meaningful dates: solar noon, mid morning, mid evening
    // use sunpose app to get solar noon values
    
    // Berkeley:
    CLLocation *berkeley = [[CLLocation alloc] initWithLatitude:37.8716 longitude:-122.2728];
    NSTimeZone *berkeleyTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"PST"];
    
    [_dateFormatter setTimeZone:berkeleyTimeZone];
    NSDate *testDate = [_dateFormatter dateFromString:@"2014-03-20 12:00:00"];
    NSDate *expectedNoon = [_dateFormatter dateFromString:@"2014-03-20 13:15:30"];
    NSDate *expectedSunrise = [_dateFormatter dateFromString:@"2014-03-20 07:11:55"];
    
    NSDictionary *results = [_astronomer sunTimesFor:testDate
                                                 atLatitude:@(berkeley.coordinate.latitude)
                                               andLongitude:@(berkeley.coordinate.longitude)];
    
    NSDate *resultNoon = [results objectForKey:kSolarNoonKey];
    NSDate *resultSunrise = [results objectForKey:kSunriseKey];
    
    XCTAssertTrue(abs([resultNoon timeIntervalSinceDate:expectedNoon]) < 180.0, @"Noon date fail: expected %@, calculated %@.", expectedNoon, resultNoon);
    XCTAssertTrue(abs([resultSunrise timeIntervalSinceDate:expectedSunrise]) < 180.0, @"Sunrise date fail: expected %@, calculated %@.", expectedSunrise, resultSunrise);
    
}

@end
