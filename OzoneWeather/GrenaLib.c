/*
 *  GrenaLib.c
 *  SunTool
 *
 *  Copyright (c) 2014 Suzanne Kiihne. All rights reserved.
 *
 */

#include <math.h>
#include "GrenaLib.h"
#define PI	3.1415926535897932384626433832795028841971

// Heliocentric calculations
double calcHelioLongGrena(double grenaJDE)  //
{			
	//3.2.1. Linear increasing with annual oscillation
	double summation = (1.72019e-2 * grenaJDE) - 0.0563;
	double Ly = 1.740940 + 1.7202768683e-2*grenaJDE + 
			3.34118e-2*sin(summation) + 3.488e-4 *sin(2*summation);

	// 3.2.2 Moon perturbation
	double Lm = 3.13e-5*sin(0.2127730*grenaJDE - 0.585);

	// 3.2.3 Harmonic correction
	double Lh = 1.26e-5*sin(4.243e-3*grenaJDE + 1.46) + 2.35e-5*sin(1.0727e-2*grenaJDE + 0.72) +
			2.76e-5*sin(1.5799e-2*grenaJDE + 2.35) + 2.75e-5*sin(2.1551e-2*grenaJDE - 1.98) +
			1.26e-5*sin(3.1490e-2*grenaJDE - 0.80);

	// 3.2.4 Polynomial Correction
	double t2 = grenaJDE/1000;
	double Lp = t2*t2*(( (-2.30796e-07*t2 + 3.7976e-06)*t2 -2.0458e-05)*t2 +3.976e-05);
	
	double HelioLong = Ly+Lm+Lh+Lp;
	return (fmod(HelioLong, 2*PI));  // = HeliocentricLongitude in range 0-2pi
}

// Geocentric calculations:
void calcGeocentricGrena(double grenaJDE, double helioLong, datapair *RA_Dec)
{
	// 3.3 Geocentric Longitude, including earth's nutation (delta gamma).
	double nutationCorrection = 8.33e-5*sin(9.252e-4*grenaJDE - 1.173);

	// 3.4 Inclination of earth's axis (epsilon).
	double axisTilt = -6.21e-9*grenaJDE + 0.409086 + 4.46e-5*sin(9.252e-4*grenaJDE + 0.397);

	// 3.5 Geocentric Longitude, gamma
	double geocentricLong = helioLong + PI + nutationCorrection - 9.932e-5;  //

	// right ascension (alpha)
	double geocentricRA = atan2(sin(geocentricLong)*cos(axisTilt), cos(geocentricLong));
	// to report this in hours, use alpha_hr = fmod(alpha, 2*PI)/PI;

	// declination (delta)
	double geocentricDec = asin(sin(axisTilt) * sin(geocentricLong));
	
	RA_Dec->a = geocentricRA;
	RA_Dec->b = geocentricDec;
}

// topocentric calculations: results in radians
void calcTopocentricGrena(double grenaJDE, datapair *geocRA_Dec, datapair *observerLatLong, datapair *obsPT, datapair *zenAzi)
{
	double nutationCorrection = 8.33e-5*sin(9.252e-4*grenaJDE - 1.173);
	double t_G = grenaJDE;
	
	double obsLat = (PI/180) * (observerLatLong->a);
	double obsLong = (PI/180) * (observerLatLong->b);
	double geocRightAscension = geocRA_Dec->a;
	double geocDeclination = geocRA_Dec->b;
	
	double s_lat = sin(obsLat);
	double c_lat = cos(obsLat);

	// 3.6 Hour angle of the sun
	double localHourAngle = 6.30038809903*t_G + 4.8824623 + 0.9174*nutationCorrection + obsLong - geocRightAscension;
	localHourAngle = fmod(localHourAngle, 2*PI);  //restrict to 0-2pi
    
	double s_HA = sin(localHourAngle);
	double c_HA = cos(localHourAngle);
	
	//3.7 Parallax correction (delta_alpha)
	double parallax = -4.26e-5*c_lat*s_HA;  //d_alpha

	double topocentricDec = geocDeclination - 4.26e-5*(s_lat - geocDeclination*c_lat);
	
	double s_topocHA = s_HA - parallax*c_HA;
	double c_topocHA = c_HA + parallax*s_HA;
	
	// 3.9 solar elevation angle: no refraction correction
	double elevationAngle = asin(s_lat*sin(topocentricDec) + 
								 c_lat*cos(topocentricDec)*c_topocHA);

	//3.10 correction for atmospheric refraction (pressure in ATM, temp in °C)
	double obsPressure = obsPT->a;
	double obsTemp = obsPT->b;
    
	double refracCorr = 0.084217*obsPressure/( (273+obsTemp)*tan(elevationAngle+0.0031376/(elevationAngle + 0.089186)));

	//3.11 zenith angle
	// add PI to azimuth to convert from 0 at S to 0 at N. Counting clockwise.
	double zenithAngle = (PI/2) - elevationAngle - refracCorr;
	double azimuthAngle = PI + atan2(s_topocHA, c_topocHA*s_lat - 
								sin(topocentricDec)/cos(topocentricDec)*c_lat);
												
	zenAzi->a = zenithAngle;
	zenAzi->b = azimuthAngle;
	
}
