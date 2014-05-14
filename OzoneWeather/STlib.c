/*
 *  STlib.c
 *  SunTool Library
 *
 *  Created by Suzanne Kiihne on 9/26/10.
 *
 *  Some open source license or another.
 *  Seriously, this stuff is really basic, so hey, just use it, rewirte it, whatever.
 *  I think it works, but there are absolutely NO guarantees.
 *
 */

#include <math.h>
#include "STlib.h"

double degToRad(double angle)
{	
	return (M_PI/180.0)*angle; 
}

double radToDeg(double angle)
{ 
	return (180.0/M_PI)*angle; 
}

double limit_degrees(double degrees) // modulus 360
{
	double limited;
	
	degrees /= 360.0; 
	limited = 360.0*(degrees-floor(degrees)); 
	if (limited < 0) limited += 360.0;
	
	return limited; 
}

double limit_degrees180pm(double degrees)
{	
	double limited;
	degrees /= 360.0; 
	limited = 360.0*(degrees-floor(degrees)); 
	if		(limited < -180.0) limited += 360.0; 
	else if	(limited > 180.0) limited -= 360.0;
	
	return limited;
}

double limit_degrees180(double degrees)
{
	double limited;
	degrees /= 180.0; 
	limited = 180.0*(degrees-floor(degrees)); 
	if (limited < 0) limited += 180.0;
	
	return limited;
}

double limit_zero2one(double value)
{
	double limited; 
	
	limited = value - floor(value);
	if (limited < 0) limited += 1.0; 
	
	return limited;
}

double limit_minutes(double minutes)
{
	double limited=minutes; 
	if		(limited < -20.0)	limited += 1440.0;
	else if	(limited > 20.0)	limited -= 1440.0; 
	
	return limited;
}

double dayfrac_to_local_hr(double dayfrac, double timezone)
{ 
	return 24.0*limit_zero2one(dayfrac + timezone/24.0); 
}


double third_order_polynomial(double a, double b, double c, double d, double x)
{
	return ((a*x + b)*x + c)*x + d;
}

