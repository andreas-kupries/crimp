#ifndef CRIMP_INTERPOLATE_H
#define CRIMP_INTERPOLATE_H
/*
 * CRIMP :: Interpolation Declarations, and API.
 * (C) 2014-2016.
 */

#include <tcl.h>

/*
 * API :: Linear, Bilinear, Trilinear, Cubic, Bicubic interpolations.
 */

extern double crimp_interpolate_linear (double a, double b,
					double frac);

extern double crimp_interpolate_bilinear (double a, double b,
					  double c, double d,
					  double xfrac, double yfrac);

extern double crimp_interpolate_trilinear (double a, double b, double c, double d,
					   double e, double f, double g, double h,
					   double xfrac, double yfrac, double zfrac);

extern double crimp_interpolate_cubic (double a, double b, double c, double d,
				       double frac);

extern double crimp_interpolate_bicubic (double a, double b, double c, double d,
					 double e, double f, double g, double h,
					 double i, double j, double k, double l,
					 double m, double n, double o, double p,
					 double xfrac, double yfrac);

/*
 * Notes:
 *
 * - Linear:
 *   a -- b  xfrac in [0,1] is a point between.
 #   0    1
 *
 * - Bilinear:
 *   0    1
 * 0 a -- b  xfrac in [0,1] is a point between (a,b)
 *   |    |  yfrac in [0,1] is a point between (a,c)
 *   |    |
 * 1 c -- d
 *
 * - Trilinear:
 *   1 e ---- f  xfrac in [0,1] is a point between (a,b)
 *    /|    1/|  yfrac in [0,1] is a point between (a,c)
 * 0 a ---- b |  zfrac in [0,1] is a point between (a,e)
 *   | g -- | h
 *   |/     |/ 
 * 1 c ---- d
 *
 * - Cubic:
 *   a -- b -- c -- d  xfrac in [0,1] is a point between (b,c).
 #   -1   0    1    2
 *
 * - Bicubic:
 *   -1    0    1    2
 * -1 a -- b -- c -- d  xfrac in [0,1] is a point between (f,g)
 *    |    |    |    |	yfrac in [0,1] is a point between (f,j)
 *  0 e -- f -- g -- h
 *    |    |    |    |  The area f-g-k-j is the patch in which
 *  1 i -- j -- k -- l  we interpolate, the points around it
 *    |    |    |    |  provide larger context
 *  2 m -- n -- o -- p
 */

/*
 * API :: Coordinate operation - Find nearest, interval, ...
 */

extern int  crimp_nearest  (double x);
extern void crimp_interval (double x, int* low, int* up, double* frac);


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_INTERPOLATE_H */
