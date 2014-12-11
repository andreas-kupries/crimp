#ifndef CRIMP_INTERPOLATE_H
#define CRIMP_INTERPOLATE_H
/*
 * CRIMP :: Interpolation Declarations, and API.
 * (C) 2014.
 */

#include <tcl.h>

/*
 * API :: Linear, Bilinear, Trilinear interpolations.
 */

extern void crimp_interpolate_linear    (double a, double b,
					 double frac);
extern void crimp_interpolate_bilinear  (double a, double b,
					 double c, double d,
					 double xfrac, double yfrac);
extern void crimp_interpolate_trilinear (double a, double b, double c, double d,
					 double e, double f, double g, double g,
					 double xfrac, double yfrac, double zfrac);
/*
 * Notes:
 *
 * - Linear:
 *   a ---- b  xfrac in [0,1] is a point between.
 #   0      1
 *
 * - Bilinear:
 *   0      1
 * 0 a ---- b  xfrac in [0,1] is a point between (a,b)
 *   |      |  yfrac in [0,1] is a point between (a,c)
 *   |      |
 * 1 c ---- d
 *
 * - Trilinear:
 *     e ---- f  xfrac in [0,1] is a point between (a,b)
 *   0/|    1/|  yfrac in [0,1] is a point between (a,c)
 * 0 a ---- b |  zfrac in [0,1] is a point between (a,e)
 *   | g -- | h
 *   |/     |/ 
 * 1 c ---- d
 */


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_INTERPOLATE_H */
