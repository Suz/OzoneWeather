//
//  OWViewData.m
//  OzoneWeather
//
//  Created by Suzanne Kiihne on 16/05/2014.
//  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
//

#import "OWViewData.h"
#import "OWSolarWrapper.h"

@interface OWViewData ()

// private properties and methods for transforming data

-(double) uvIndexForOzone:(NSNumber *)ozone ZenithAngle:(NSNumber *)zenith andDistance:(NSNumber *)distance;
-(double) erythIrradianceForUVIndex:(NSNumber *)uvindex;
-(double) vitDToUVIRatioFor:(NSNumber *)zenith andOzone:(NSNumber *)ozone;
-(double) vitDIrradianceForVitaminDRatio:(double)ratio andErythemalIrradiance:(double)irradiance;
-(NSTimeInterval) secondsToVitDForIrradiance:(double)irradiance;

@end

@implementation OWViewData

- (id)initWithConditions:(OWCondition *)conditionsData andOzone:(OWOzoneLevel *)ozoneData {
    self = [self init];
    if (self == nil) return nil;
    
    // is this necessary? should these be copies?
    
    _date           = conditionsData.date;
    _temperature    = conditionsData.temperature;
    
    _hiTemp         = conditionsData.hiTemp;
    _loTemp         = conditionsData.loTemp;
    _locationName   = conditionsData.locationName;
    _conditionDescription = conditionsData.conditionDescription;
    _condition      = conditionsData.condition;
    _icon           = conditionsData.icon;
    
    // Set up astronomy calculations:
    OWSolarWrapper *calculator = [[OWSolarWrapper alloc] init];
    
    //sunset, sunrise:  use ozone date (~local solar noon)
    NSDictionary *sunTimes = [calculator sunTimesFor:ozoneData.ozoneDate
                                          atLatitude:conditionsData.latitude
                                        andLongitude:conditionsData.longitude];
    
    _sunrise = [sunTimes objectForKey:kSunriseKey];
    _sunset = [sunTimes objectForKey:kSunsetKey];
    
    if (abs( [_sunrise timeIntervalSinceDate:conditionsData.sunrise] ) > 600) {
        NSLog(@"Error: calculated sunrise at %@, but openweather sunrise at %@", _sunrise, conditionsData.sunrise);
    }

    // UVI: TEMIS reports max for today. Also want current value.
    double earthSunDistance = [calculator earthSunDistanceFor:ozoneData.ozoneDate].floatValue;
    
    NSDictionary *noonSolarAngles = [calculator solarAnglesForDate:ozoneData.ozoneDate
                                                        atLatitude:conditionsData.latitude
                                                      andLongitude:conditionsData.longitude];
    
    double noonZenithAngle = [[noonSolarAngles objectForKey:kZenithAngleKey] floatValue];
    // Maximum clear sky UV Index (solar noon)
    double maxUVIndex = [self uvIndexForOzone:ozoneData.columnOzone
                                   ZenithAngle:@(noonZenithAngle)
                                   andDistance:@(earthSunDistance)];

    if (abs(maxUVIndex - ozoneData.uvIndex.floatValue) > 0.3) {
        NSLog(@"Error: UV Index values differ. calculate %0.1f vs TEMIS %@", maxUVIndex, ozoneData.uvIndex);
    }

    // UV Index for current time.
    NSDictionary *solarAngles = [calculator solarAnglesForDate:conditionsData.date
                                                    atLatitude:conditionsData.latitude
                                                  andLongitude:conditionsData.longitude];
    
    double zenithAngle = [[solarAngles objectForKey:kZenithAngleKey] floatValue];
    
    
    double calcUVIndex = [self uvIndexForOzone:ozoneData.columnOzone
                                      ZenithAngle:@(zenithAngle)
                                      andDistance:@(earthSunDistance)];
    
    
    // vitamin D irradiance (W / m^2 )
    double vitDIrradiance = ([self vitDToUVIRatioFor:@(zenithAngle) andOzone:ozoneData.columnOzone] * calcUVIndex / 40.0);
    
    // cloud modifications.
    double filteredUVIndex = calcUVIndex * [self cloudFilter:conditionsData.cloudCover];
    double filteredVitDIrradiance = vitDIrradiance * [self cloudFilter:conditionsData.cloudCover];
    
    // TODO: include irradiance changes for reflectance from surrounding environment
    // needs a land usage map, lat lon from manager (not from weather data service) and
    // azimuthal angle of the sun for specular reflection.
    
    // vitamin D time
    double vitDTime;
    if (filteredVitDIrradiance < 10) {
        vitDTime = -99;   // not enough UV to make vitamin D!
    } else {
        // TODO: include calculations for changing angle of the sun
        vitDTime = [self secondsToVitDForIrradiance:filteredVitDIrradiance];
    }
    
    _uvIndex = [NSString stringWithFormat:@"%.1f", filteredUVIndex];
    _vitaminDTime = [self stringForSeconds:vitDTime];
   // _UVADanger;  --  I thought there was a paper by Fioletov on the UVA intensity relative to UVB or UVI over the course of a day, but I haven't been able to find it. Need to sign on to web of science, possibly from university library. 
    
    return self;
}

+ (NSDictionary *)imageMap {
    static NSDictionary *_imageMap = nil;
    if (! _imageMap) {
        _imageMap = @{
                      @"01d"  :  @"weather-clear",
                      @"02d"  :  @"weather-few",
                      @"03d"  :  @"weather-few",
                      @"04d"  :  @"weather-broken",
                      @"09d"  :  @"weather-shower",
                      @"10d"  :  @"weather-rain",
                      @"11d"  :  @"weather-tstorm",
                      @"13d"  :  @"weather-snow",
                      @"50d"  :  @"weather-mist",
                      @"01n"  :  @"weather-moon",
                      @"02n"  :  @"weather-few-night",
                      @"03n"  :  @"weather-few-night",
                      @"04n"  :  @"weather-broken",
                      @"09n"  :  @"weather-shower",
                      @"10n"  :  @"weather-rain-night",
                      @"11n"  :  @"weather-tstorm",
                      @"13n"  :  @"weather-snow",
                      @"50d"  :  @"weather-mist",
                      };
    }
    return _imageMap;
}

- (NSString *)weatherImageName {
    return [OWViewData imageMap][self.icon];
}

- (UIColor *)uvDangerLevel {
    
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

#pragma mark   =====================  adaptor functions =====================
// This should move into a string formatting library.
// TODO: There's a better way to do this with calendar units. 
-(NSString *) stringForSeconds:(double)seconds {
     NSString *result = @"";
     int hrs=0;
     int min=0;
     int sec;
     
     if (isnan(seconds) || !seconds || (seconds < 0)) {
         return (@"no Vitamin D now ");
     }
    
    NSDate *targetDate = [NSDate dateWithTimeInterval:seconds sinceDate:self.date];
    
    // Should finish making vitamin D at least 30 min before sunset.
     if ([self.sunset timeIntervalSinceDate:targetDate] < 60*30) {
         // TODO: how much can be achieved today?
         return @"1000 IU Not reached today ";
     }
    
     //NSLog(@"formatting %f seconds", seconds);
     if (seconds > 3600.0) {
         // hours!
         hrs = floor(seconds/3600);
         seconds -= hrs*3600;
         //NSLog(@"found %d hours. Now have %f seconds left.", hrs, seconds);
     }
     
     if (seconds > 60.0) {
         min = floor(seconds/60);
         seconds -= min*60;
         //NSLog(@"found %d minutes. Now have %f seconds left.", min, seconds);
     }
     
     sec = round(seconds);
     // Don't report seconds in the UI.
     // Modify minutes accordingly:
     if (sec>30) {
         min+=1;
     }
     
     if (hrs) {
         if (!min) {
             min = 0;
         }
         result = [NSString stringWithFormat:@"%i:%02i ", hrs,min];
         //result = [NSString stringWithFormat:@"%i:%02i:%02i ", hrs,min,sec];
     } else if (min) {
         result = [NSString stringWithFormat:@"%i ",min];
         //result = [NSString stringWithFormat:@"%i:%02i ",min];
     } else {
         result = @"< 1 ";
         //result = [NSString stringWithFormat:@":%02i ", sec];
     }
     
     return result;
}


// transmission factor: multiply by uvi to get filtered uvi value.
// Model based on Frederick and Steele (1995)
// as reported in:
//		Forecasting the UV index for UFOS: Model overview and methodology
//		Author: Bertrand Théodore, ACRI-ST August 30th, 2000
//
// uvi_c = uvi * (1-0.56*f)   f = cloud fraction
//
-(CGFloat)cloudFilter:(NSNumber *)cloudCover {
    return (1.0 - 0.56 * cloudCover.floatValue);
}


//Clear sky UV Index
//
// UV index based on KNMI empirical method: M.Allaart, et al.
//				Meterol. Appl. v11, p 59-64, 2004
// inputs:
//      ozone:  total column ozone in Dobsons (cm)
//      zenith: solar zenith angle in degrees (0° at zenith, 90° at horizon)
//      distance:  appropriate earth sun distance for the date in fractions of A.U.
//              (i.e. as a ratio with mean earth-sun distance)
-(double)uvIndexForOzone:(NSNumber *)ozone ZenithAngle:(NSNumber *)zenith andDistance:(NSNumber *)distance {
	
	double uva;
	double uvi;
	
	double r = distance.doubleValue;
	double rFactor = 1.0/(r*r);
	double o3 = ozone.doubleValue;
	double pathLength = cos(zenith.doubleValue);
	double pathEffective = 0.83*pathLength + 0.17;
	
	uva = rFactor * 1.24 * pathEffective * exp(-0.58/pathEffective);
	
	uvi = uva * (1.4 + (280.0/o3) + 2.0*pow(1000.0*pathLength/o3, 1.62));
	
	return uvi;
}

// Erythemal Irradiance in W/m^2
// back-calculate from UV Index based on definition.
-(double) erythIrradianceForUVIndex:(NSNumber *)uvindex {
    
	double erythIrr = uvindex.doubleValue/40.0;
	
	return  erythIrr;
}

// Convert UV Index to vitaminD irradiation in Watts / m^2:
//
// from Fioletov 2009, the vitamin D irradiation can be approximated by:
//
// UV_D = 25mW/m2 * UV_I * (2-exp(0.25-UV_I/2.5))
//
// However, since we are now calculating for each solar zenith angle, it's better
// to use the equation with SZA, Ozone, and UVI (erythremal) to get the vitamin D
// Again from Fioletov 2009:
//		Ratio = 0.323 + 6.93*c - 5.29*c^2 - 0.0123X*c*(1-c)
//			X = total column ozone (Dobson Units, DU)
//			c = cos(SZA)   with SZA = solar zenith angle in degrees
//                          NOTE:  sza is 0 at highest, 90° at horizon.
//
-(double) vitDToUVIRatioFor:(NSNumber *)zenith andOzone:(NSNumber *)ozone {
	
	double sza = zenith.doubleValue;  // in radians
	double X = ozone.doubleValue;
	double c = cos(sza ); //* M_PI/ 180.0
	double ratio = 0.323 + 6.93*c - 5.29*c*c - 0.0123*c*(1.0-c)*X;
	//NSLog(@"zenith angle is %.2f, so vitD/uvi is %.2f", sza*180/M_PI, ratio);
	
	return ratio;
}

// vitamin D irradiance in Watts / m^2
//
// TODO: I don't remember how exact this is.
// is this an approximation that needs improving?
-(double) vitDIrradianceForVitaminDRatio:(double)ratio andErythemalIrradiance:(double)irradiance { // in W/m2
	
	double vitD = ratio * irradiance;
	
	return vitD;
}

/* UV exposure Vitamin D target calculation updated Nov 2011
  based on Terushkin et all,
 J Am Acad Dermatol. 2011 (halpern 2011)
 
 Checked Results vs paper. Values good for all skin types, places shown in paper for noon values. Compared October values in paper to Nov. 7 values (today). Values for Nov generally 1-2 min longer, so good agreement!
 
 Paper lists SDD values 87.6, 109.4, 131.3, 197.0, 262.8, 437.8 J/m2 for skin types I-VI, respectively.
 Fit values for types I-V (approx_reflectance) in Igor:
             fit_SDD_halpern2010= W_coef[0]+W_coef[1]*x
             W_coef={512.06,-503.58}
             V_chisq= 221.641; V_npnts= 5; V_numNaNs= 0; V_numINFs= 0;
             V_q= 1; V_Rab= -0.0133213; V_Pr= -0.994603;
             W_sigma={21.7,30.3}
             Coefficient values ± one standard deviation
             a 	= 512.06 ± 21.7
             b 	= -503.58 ± 30.3
 Final equation: SDD (J/m2) = 512.06 - 503.58 * approx_reflectance
 This is for 1000 IU, with 25% skin surface exposed.
 They further use: target = SDD * (0.25/exposedFrac) * (D_Dose/1000) to adjust it.
 */
-(NSTimeInterval)secondsToVitDForIrradiance:(double)irradiance {
	
	double vitDDose = 1000;         // good value for optimal health, building up stores.
	double skinReflectance = 0.72;  // Default for Type 2, European average.
    
	double skinExposed = 1.0;       // relative to 0.25 as shown above -- short sleeves.
	
	double target = (512.06 - 503.58*skinReflectance) * skinExposed *(vitDDose/1000);
	
	double interval = target / irradiance;  // seconds needed to reach target exposure
    
    return interval;
}



@end
