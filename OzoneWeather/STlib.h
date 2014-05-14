/*
 *  STlib.h
 *  SunTool
 *
 *  Created by Suzanne Kiihne on 9/26/10.
 *  Copyright 2010 Independent Research. All rights reserved.
 *
 */

typedef struct {     // generalized holder
	
	// uses:  {lat,long}, {dec,RA}, {sin,cos}.... 
	double a;		
	double b;
	
} datapair;

double degToRad(double);
double radToDeg(double);
double limit_degrees(double);
double limit_degrees(double degrees);
double limit_degrees180pm(double degrees);
double limit_degrees180(double degrees);
double limit_zero2one(double value);
double limit_minutes(double minutes);
double dayfrac_to_local_hr(double dayfrac, double timezone);
double third_order_polynomial(double a, double b, double c, double d, double x);
