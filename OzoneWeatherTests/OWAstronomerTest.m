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
    XCTAssertEqualWithAccuracy(2451545.0, result.floatValue, .0005, @"JulianDate fails on 2000 reference");

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
        double expected = [refJD[idx] floatValue];
        double result = [[_astronomer julianDateFor:testDate] floatValue];
        XCTAssertEqualWithAccuracy(expected, result, 0.0005, @"JulianDate fail for date: %@", testDate);
    }
}

-(void)testjulianDateRelative2003{
    NSArray *dateStrings = @[@"2011-07-29 14:00:00", @"2000-02-29 14:00:00", @"2000-03-01 14:00:00", @"2001-02-28 14:00:00", @"2001-03-01 14:00:00", @"2100-02-28 14:00:00",@"2100-03-01 14:00:00"];
    NSArray *refJD = @[@(2455772),@(2451604),@(2451605),@(2451969),@(2451970),@(2488128),@(2488129)];
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expected = [refJD[idx] floatValue] - 2452640.0;
        double result = [[_astronomer julianDateRelative2003For:testDate] floatValue];
        
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
        double expected = [refDistances[idx] floatValue];
        double result = [[_astronomer earthSunDistanceFor:testDate] floatValue];
        
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
                             @"2043-06-12 16:00:00",];
    NSArray *refEOT = @[@(-7.04), @(14.39), @(-9.24),
                              @(0.0), @(-4.4), @(0.06)];
    
    int idx;
    for (idx = 0; idx < dateStrings.count; idx = idx + 1) {
        NSDate *testDate = [_dateFormatter dateFromString:dateStrings[idx]];
        double expected = [refEOT[idx] floatValue];
        double result = [[_astronomer equationOfTimeFor:testDate] floatValue];
        
        XCTAssertEqualWithAccuracy(expected, -1*result, 0.5, @"Equation of time incorrect for date: %@", testDate);
    }
    
}


-(void)testSolarAngles{
    // meaningful dates: solar noon, mid morning, mid evening
    // use sunpose to get solar noon values
    
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
        double expectedDec = [refDeclination[idx] floatValue];
        double expectedRA = [refRightAscension[idx] floatValue];
        NSDictionary *results = [_astronomer solarParametersForDate:testDate];
        
        double resultDec = [[results objectForKey:kSolarDeclinationKey] floatValue];
        double resultRA = [[results objectForKey:kSolarRightAscensionKey] floatValue];
        
        if ((resultRA < 0) && (abs(resultRA) > 1)) {
            resultRA = 360 + resultRA;
        }
        
        // TODO: This error is 0.1 - 0.22 °, which is larger than it should be for this algorithm.
        XCTAssertEqualWithAccuracy(expectedDec, resultDec, 0.1, @"Solar Declination fail for date: %@", testDate);
        XCTAssertEqualWithAccuracy(expectedRA, resultRA, 0.25, @"Solar RightAscension fail for date: %@", testDate);
    }
}

/* Testing solar angles, but this is too complicated to start with.
 --> move this system to the bottom until I work out where the errors are.
 
 //  Locations: N hemisphere, S hemisphere, wide range of coordinates, time zones.
 // San francisco:   Lat 37.77,      Long -122.45,   TZ -8
 CLLocation *sanFrancisco = [[CLLocation alloc] initWithLatitude:37.77 longitude:-122.45];
 NSTimeZone *sfTZ = [NSTimeZone timeZoneForSecondsFromGMT:(-8*3600)];
 // Helsinki:        Lat 60.17,      Long 24.97,     TZ +2
 CLLocation *helsinki = [[CLLocation alloc] initWithLatitude:60.17 longitude:24.97];
 NSTimeZone *helTZ = [NSTimeZone timeZoneForSecondsFromGMT:(2*3600)];
 // Bangkok:         Lat 13.725,     Long 100.475,   TZ +7
 CLLocation *bangkok = [[CLLocation alloc] initWithLatitude:13.725 longitude:100.475];
 NSTimeZone *bgkTZ = [NSTimeZone timeZoneForSecondsFromGMT:(7*3600)];
 // Aukland:         Lat -36.847,    Long 174.77,    TZ +12
 CLLocation *aukland = [[CLLocation alloc] initWithLatitude:-36.847 longitude:174.77];
 NSTimeZone *akldTZ = [NSTimeZone timeZoneForSecondsFromGMT:(12*3600)];
 // Capetown:        Lat -33.92,     Long 18.37,     TZ +2
 CLLocation *capetown = [[CLLocation alloc] initWithLatitude:-33.92 longitude:18.37];
 NSTimeZone *cptnTZ = [NSTimeZone timeZoneForSecondsFromGMT:(2*3600)];
 // Manaus:          Lat -3.107,     Long -60.025,   TZ -4
 CLLocation *manaus = [[CLLocation alloc] initWithLatitude:-3.107 longitude:-60.025];
 NSTimeZone *mnsTZ = [NSTimeZone timeZoneForSecondsFromGMT:(-4*3600)];
 
 NSArray *testPlacesData = @[sanFrancisco, sfTZ, helsinki, helTZ, bangkok, bgkTZ, aukland, akldTZ, capetown, cptnTZ, manaus, mnsTZ];
 // past, present, future. near equinoxes and solstices.
 NSArray *dateStrings = @[@"2000-03-21 12:00:00", @"2000-06-21 12:00:00",  @"2014-06-21 12:00:00", @"2043-09-21 12:00:00", @"2043-12-21 12:00:00"];
 
 // other dates to add when I get around to it:
 //@"2000-09-21 12:00:00",@"2000-12-21 12:00:00",
 //@"2014-03-21 12:00:00", @"2014-06-21 12:00:00", @"2014-09-21 12:00:00",@"2014-12-21 12:00:00",
 //@"2043-03-21 12:00:00", @"2043-06-21 12:00:00",
 
 //  Results               EQT     Dec     Sunrise     Noon       Sunset   Azi     El
 //  Mar 21 2000:
 //      SanFrancisco    -6.96    0.6°    06:11       12:16:46    18:23   172.37  56.61
 //      Helsinki        -7.09    0.44    06:18       12:27:12    18.38   172.14  30.06
 //      Bangkok         -7.15    0.35    06:22       12.25:12    18.29   154.43  75.24
 //      Aukland         -7.21    0.27    06:25       12.28.08    18.31   11.55   52.33
 //      Capetown        -7.09    0.44    06:51       12.53.36    18.56   22.88   53.42
 //      Manaus          -7.01    0.53    06:04       12.07:07    18:10   26.05   85.95
 
 //  Jun 21 2000:
 //      SanFrancisco    -1.9    23.44    04.48       12:11:42    19:35  169.26   75.45
 //      Helsinki        -1.81   23.44    02:54       12:21:56    21:50  171.61   53.08
 //      Bangkok         -1.76   23.44    05:52       12:19:52    18:48  25.1     79.21
 //      Aukland         -1.72   23.44    07:34       12:22:39    17:12  5.97     29.51
 //      Capetown        -1.81   23.44    07:52       12:48:20    17:45  13.02    31.53
 //      Manaus          -1.86   23.44    06:04       12:01:58    18:00  1.01     63.46
 
 //  Jun 21 2014:
 //      SanFrancisco    -1.85   23.43   04:48       12:11:32    19:35   169.42  75.46
 //      Helsinki        -1.76   23.44   02.54       12:21:53    21:50   171.63  53.08
 //      Bangkok         -1.71   23.43   05:52       12:19:49    18:48   25.05   79.22
 //      Aukland         -1.67   23.43   07:34       12:22:35    17:12   5.95    29.51
 //      Capetown        -1.84   23.43   07:51       12:48:17    17:45   13      31.53
 //      Manaus          -1.81   23.43   06:04       12:01:55    18:00   0.98    63.46
 
 
 //  Sep 21 2023:
 //      SanFrancisco
 //      Helsinki       6.78    0.73    06:01   12:13:20    18:24   176.13  30.53
 //      Bangkok
 //      Aukland
 //      Capetown       6.78    0.73    06:38   12:39:44    18.42   17.12   54.13
 //      Manaus
 
 //  Dec 21 2023:
 //      SanFrancisco
 //      Helsinki       2.09    -23.44  09:24   12:18:04    15:13   175.84  6.45
 //      Bangkok
 //      Aukland
 //      Capetown       2.09    -23.44  05:32   12:44:27    19:57   45.72   75.71
 //      Manaus
 
 
 //  Sep 21 2043:
 //      SanFrancisco    6.97    0.50    05:57        12:02:42    18:08   178.88  52.74
 //      Helsinki        6.82    0.66    06:01        12:13:18    18:24   176.14  30.47
 //      Bangkok         6.75    0.74    06:07        12:11:21    18:15   167.56  76.72
 //      Aukland         6.68    0.83    06:13        12:14:14    18:16   5.81    52.2
 //      Capetown        6.82    0.66    06.38        12:39:41    18:42   17.13   54.19
 //      Manaus          6.91    0.57    05:50        11:53:11    17:56   335.11  85.95
 
 //  Dec 21 2043:
 //      SanFrancisco    1.86    -23.44  07:21       12:07:50    16:54   177.94  28.8
 //      Helsinki        2.06    -23.43  09:24       12:18:04    15.13   175.83  6.45
 //      Bangkok         2.17    -23.43  06:36       12:15:56    17:56   173.97  52.65
 //      Aukland         2.27    -23.43  04:58       12:18:39    19:39   17.95   76
 //      Capetown        2.06    -23.43  05:32       12:44:28    19:57   45.74   75.71
 //      Manaus          1.94    -23.44  05:49       11:58:10    18:07   181.21  69.67
 
 
 NSArray *refElevation = @[@(56.61),@(30.06), @(75.24), @(52.33), @(53.42), @(85.95),
 @(75.45), @(53.08), @(79.21), @(29.51), @(31.53), @(63.46),
 @(75.46), @(53.08), @(79.22), @(29.51), @(31.53), @(63.46),
 @(52.74), @(30.47), @(76.72), @(52.2), @(54.19), @(85.95),
 @(28.8), @(6.45), @(52.65), @(76), @(75.71), @(69.67)];
 
 NSArray *refAzimuth = @[@(172.37), @(172.14), @(154.43), @(11.55), @(22.88), @(26.05),
 @(169.26), @(171.61), @(25.1), @(5.97), @(13.02), @(1.01),
 @(169.42), @(171.63), @(25.05), @(5.95), @(13.0), @(0.98),
 @(178.88), @(176.14), @(167.56), @(5.81), @(17.13), @(335.11),
 @(177.94), @(175.83), @(173.97), @(17.95), @(45.74), @(181.21)];
 
 int place_idx;
 int date_idx;
 for (date_idx = 0; date_idx < dateStrings.count; date_idx = date_idx + 1) {
 for (place_idx = 0; place_idx < testPlacesData.count; place_idx = place_idx + 2) {
 
 CLLocation *testPlace = [testPlacesData objectAtIndex:place_idx];
 NSTimeZone *testTZ = [testPlacesData objectAtIndex:(place_idx +1)];
 NSNumber *latitude = @(testPlace.coordinate.latitude);
 NSNumber *longitude = @(testPlace.coordinate.longitude);
 [_dateFormatter setTimeZone:testTZ];
 NSDate *testDate = [_dateFormatter dateFromString:dateStrings[date_idx]];
 
 
 int ref_idx = (place_idx / 2) + date_idx * testPlacesData.count / 2;
 double expectedAzi = [refAzimuth[ref_idx] floatValue]; // degrees
 double expectedZenith = 90 - [refElevation[ref_idx] floatValue]; // degrees
 
 NSDictionary *results = [_astronomer solarAnglesForDate:testDate
 atLatitude:latitude
 andLongitude:longitude];
 
 double resultAzi = [[results objectForKey:@"azimuthAngle"] floatValue];
 double resultZenith = [[results objectForKey:@"zenithAngle"] floatValue];
 
 XCTAssertEqualWithAccuracy(expectedAzi, resultAzi, 2.0, @"Azimuth angle incorrect for date: %@", testDate);
 XCTAssertEqualWithAccuracy(expectedZenith, resultZenith, 0.5, @"Zenith angle incorrect for date: %@", testDate);
 
 }
 }
 */

@end
