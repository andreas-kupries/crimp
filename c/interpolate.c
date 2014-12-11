/*
 * CRIMP :: Interpolation (Implementation).
 * (C) 2014.
 */

/*
 * Import declarations.
 */

#include <interpolate.h>
#include <math.h>
#include <util.h>

/*
 * References:
 *      http://en.wikipedia.org/wiki/Bilinear_interpolation
 *      http://en.wikipedia.org/wiki/Trilinear_interpolation
 */


void
crimp_interpolate_linear (double a, double b,
			  double frac)
{
  return a + (b-a) * frac;
}

void
crimp_interpolate_bilinear  (double a, double b,
			     double c, double d,
			     double xfrac, double yfrac)
{
  return a + (b-a) * xfrac + (c-a) * yfrac + (a-b-c+d) * xfrac * yfrac;

  /* A bilinear interpolation is the same as two linear
   * interpolations, first in one axis, then the other.
   *
   * linear (linear (a,b,xfrac),
   *         linear (c,d,xfrac),
   *         yfrac)
   *
   * with all the terms expanded, re-sorted, and aggregated to the
   * xfrac and yfrac multipliers, i.e.:
   *
   * <==> a + (b-a)*xf + ((c+(d-c)*xf)-(a+(b-a)*xf))*yf
   * <==> a + (b-a)*xf + (c+(d-c)*xf-a-(b-a)*xf)*yf
   * <==> a + (b-a)*xf + c*yf + (d-c)*xf*yf - a*yf - (b-a)*xf*yf
   * <==> a + (b-a)*xf + c*yf - a*yf + (d-c)*xf*yf - (b-a)*xf*yf
   * <==> a + (b-a)*xf + (c-a)*yf + ((d-c)-(b-a))*xf*yf
   * <==> a + (b-a)*xf + (c-a)*yf + (d-c-b+a)*xf*yf
   * <==> a + (b-a)*xf + (c-a)*yf + (a-c-b+d)*xf*yf
   */
}

void
crimp_interpolate_trilinear (double a, double b, double c, double d,
			     double e, double f, double g, double g,
			     double xfrac, double yfrac, double zfrac)
{
  /* A trilinear interpolation is the same as three linear
   * interpolations, one per axis, any order. This is further the
   * same as two bilinear interpolations followed by a linear one, i.e.
   *
   * linear (bilinear (a,b,c,d,xfrac,yfrac),
   *         bilinear (e,f,g,h,xfrac,yfrac),
   *         zfrac)
   *
   * with all the terms expanded, re-sorted, and aggregated to the
   * xfrac and yfrac multipliers.
   *
   * Leaving it to the compiler to perform inlining and optimization.
   * For now.
   */

  return crimp_interpolate_linear(crimp_interpolate_bilinear(a,b,c,d,xfrac,yfrac),
				  crimp_interpolate_bilinear(e,f,g,h,xfrac,yfrac),
				  zfrac);
}


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
