/*
 *  GrenaLib.h
 *  SunTool
 *
 *  Created by Suzanne Kiihne on 3/8/11.
 *  Copyright 2011 Independent Research. All rights reserved.
 *
 *  This is a c libaray of functions used in calculating the solar position.
 *  The algorithm is fairly general, but the specific iimplementation
 *  is based on a paper by R.Grena:
 *
 *		Roberto Grena, Solar Energy, v.82 (2008), pp 462–470.
 *		"An algorithm for the computation of the solar position"
 *  The algorithm considers the main effects that can affect the sun position by more than 
 *  half a second of arc (Moon perturbation, nutation, difference between topocentric and 
 *  geocentric coordinates), but all the perturbations are adapted to the period 2003–2023, 
 *  strongly reducing the amount of calculations needed, especially the number of trigonometric 
 *  functions. Empirical corrections are also introduced in the calculation of the heliocentric 
 *  longitude, to sum up all the other small perturbations too complex to be considered one by one.
 *
 *	Note:  The equation formatting for this paper is appalling. Be very careful in noticing the letter 'e'
 *  The scientific notation seems to have been printed without superscripting and the negative signs
 *  are printed as subtractions. Compare equations with the C++ implementation at the end if in doubt.
 */



#import "STlib.h"

//	double delta_t;
// Difference between earth rotation time and terrestrial time
// It is derived from observation only and is reported in this bulletin: http://maia.usno.navy.mil/
// (search for earth orientation center)
// where delta_t = 32.184 + (TAI-UTC) + DUT1 // valid range: -8000 to 8000 seconds, error code: 7 
// (TAI - UTC) = 34s   exact. This is the leap second count. 
// DUT1 = (UT1 - UTC) = (observational)  
//		= -0.2s (Jan. 2009) Checked March 3 2011. Updated Weekly. Varies by about 0.15s/year. (maybe)
// delta_t = 65.984 s as of March 2011
// 

// Time calculations:
//	t_G and t used in the computation are the Julian Day and the Ephemeris Julian Day respectively, 
//  shifted to make them start at noon, 1st January 2003. This shift simplifies the calculations
//  considerably, allowing optimization for limited processor power.

double calcHelioLongGrena(double grenaJDE); 
void calcGeocentricGrena(double grenaJDE, double helioLong, datapair *RA_Dec);

// observer latitude and longitude in degreees
// return values in radians
void calcTopocentricGrena(double grenaJDE, datapair *geocRA_Dec, datapair *observerLatLong, datapair *obsPT, datapair *zenAzi);

