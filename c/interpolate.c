/*
 * CRIMP :: Interpolation (Implementation).
 * (C) 2014.
 */

/*
 * Import declarations.
 */

#include <crimp_core/crimp_coreDecls.h>
#include <math.h>
#include <cutil.h>

/*
 * References:
 *      http://en.wikipedia.org/wiki/Bilinear_interpolation
 *      http://en.wikipedia.org/wiki/Trilinear_interpolation
 *      http://en.wikipedia.org/wiki/Bicubic_interpolation
 *      http://www.paulinternet.nl/?page=bicubic
 */


double
crimp_interpolate_linear (double a, double b,
			  double frac)
{
  return
      a            +
      (b-a) * frac;
}

double
crimp_interpolate_bilinear  (double a, double b,
			     double c, double d,
			     double xfrac, double yfrac)
{
  return
      a                         +
      (b-a)     * xfrac         +
      (c-a)     *         yfrac +
      (a-b-c+d) * xfrac * yfrac;

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

double
crimp_interpolate_trilinear (double a, double b, double c, double d,
			     double e, double f, double g, double h,
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

  return
      crimp_interpolate_linear(crimp_interpolate_bilinear(a, b, c, d,
							  xfrac, yfrac),
			       crimp_interpolate_bilinear(e, f, g, h,
							  xfrac, yfrac),
			       zfrac);
}

double
crimp_interpolate_cubic (double a, double b, double c, double d,
			 double frac)
{
    return b + 0.5 * frac * (c - a + frac * (2.0*a - 5.0*b + 4.0*c - d + frac * (3.0*(b - c) + d - a)));
}

double
crimp_interpolate_bicubic (double a, double b, double c, double d,
			   double e, double f, double g, double h,
			   double i, double j, double k, double l,
			   double m, double n, double o, double p,
			   double xfrac, double yfrac)
{
    /* Map arguments to the formula as given by
     *
     *     http://www.paulinternet.nl/?page=bicubic
     *
     * Easier to do this way than doing a text-replace. The compiler should be
     * good enough to optimize out the irrelevant variables.
     *
     * Could also be written as
     *
     *   cubic ( cubic (a,b,c,d,xfrac),
     *           cubic (e,f,g,h,xfrac),
     *           cubic (i,j,k,l,xfrac),
     *           cubic (m,n,o,p,xfrac),
     *           yfrac)
     */

    double p00 = a;    double p01 = b;    double p02 = c;    double p03 = d;
    double p10 = e;    double p11 = f;    double p12 = g;    double p13 = h;
    double p20 = i;    double p21 = j;    double p22 = k;    double p23 = l;
    double p30 = m;    double p31 = n;    double p32 = o;    double p33 = p;

    double a00 =      p11;
    double a01 = -.50*p10 +  .50*p12;
    double a02 =      p10 - 2.50*p11 + 2.00*p12 -  .50*p13;
    double a03 = -.50*p10 + 1.50*p11 - 1.50*p12 +  .50*p13;

    double a10 = -.50*p01 +  .50*p21;
    double a11 =  .25*p00 -  .25*p02 -  .25*p20 +  .25*p22;
    double a12 = -.50*p00 + 1.25*p01 -      p02 +  .25*p03 +  .50*p20 - 1.25*p21 +      p22 -  .25*p23;
    double a13 =  .25*p00 -  .75*p01 +  .75*p02 -  .25*p03 -  .25*p20 +  .75*p21 -  .75*p22 +  .25*p23;

    double a20 =      p01 - 2.50*p11 + 2.00*p21 -  .50*p31;
    double a21 = -.50*p00 +  .50*p02 + 1.25*p10 - 1.25*p12 -      p20 +      p22 +  .25*p30 -  .25*p32;
    double a22 =      p00 - 2.50*p01 + 2.00*p02 -  .50*p03 - 2.50*p10 + 6.25*p11 - 5.00*p12 + 1.25*p13 +
	2.00*p20 - 5.00*p21 + 4.00*p22 -     p23 - .50*p30 + 1.25*p31 -     p32 + .25*p33;
    double a23 = -.50*p00 + 1.50*p01 - 1.50*p02 +  .50*p03 + 1.25*p10 - 3.75*p11 + 3.75*p12 - 1.25*p13 -
	p20 + 3.00*p21 - 3.00*p22 +     p23 + .25*p30 -  .75*p31 + .75*p32 - .25*p33;

    double a30 = -.50*p01 + 1.50*p11 - 1.50*p21 +  .50*p31;
    double a31 =  .25*p00 -  .25*p02 -  .75*p10 +  .75*p12 +  .75*p20 -  .75*p22 -  .25*p30 +  .25*p32;
    double a32 = -.50*p00 + 1.25*p01 -      p02 +  .25*p03 + 1.50*p10 - 3.75*p11 + 3.00*p12 -  .75*p13 -
	1.50*p20 + 3.75*p21 - 3.00*p22 + .75*p23 + .50*p30 - 1.25*p31 +     p32 - .25*p33;
    double a33 =  .25*p00 -  .75*p01 +  .75*p02 -  .25*p03 -  .75*p10 + 2.25*p11 - 2.25*p12 +  .75*p13 +
	.75*p20 - 2.25*p21 + 2.25*p22 - .75*p23 - .25*p30 +  .75*p31 - .75*p32 + .25*p33;

    double x2 = xfrac * xfrac;
    double x3 = x2 * xfrac;
    double y2 = yfrac * yfrac;
    double y3 = y2 * yfrac;

    return
	(a00 + a01 * yfrac + a02 * y2 + a03 * y3)         +
	(a10 + a11 * yfrac + a12 * y2 + a13 * y3) * xfrac +
	(a20 + a21 * yfrac + a22 * y2 + a23 * y3) * x2    +
	(a30 + a31 * yfrac + a32 * y2 + a33 * y3) * x3;	    
}


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
