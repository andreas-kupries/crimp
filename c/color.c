/*
 * CRIMP :: Color Conversions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <color.h>
#include <math.h>
#include <util.h>

/*
 * Definitions :: HSV (Hue, Saturation, Value)
 * References:
 *	http://en.wikipedia.org/wiki/HSL_and_HSV
 *	http://en.literateprograms.org/RGB_to_HSV_color_space_conversion_%28C%29
 *	http://code.activestate.com/recipes/133527-convert-hsv-colorspace-to-rgb/
 */

void
crimp_color_rgb_to_hsv (int r, int g, int b, int* h, int* s, int* v)
{
    int hue, sat, val;
    int max = MAX (r, MAX (g, b));
    int min = MIN (r, MIN (g, b));

    val = max;

    if (max) {
	sat = (255 * (max - min)) / max;
    } else {
	sat = 0;
    }

    if (!sat) {
	/*
	 * This is a grey color, the hue is undefined, we set it to red, for
	 * the sake convenience.
	 */

	hue = 0;
    } else {
	/*
	 * The regular formulas generate a hue in the range 0..360.  We want
	 * one in the range 0..255. Instead of scaling at the end we integrate
	 * it into early calculations, properly slashing common factors. This
	 * keeps rounding errors out of things until the end.
	 */

	int delta = 6 * (max - min);

	if (r == max) {
	    hue =   0 + (255 * (g - b)) / delta;
	} else if (g == max) {
	    hue =  85 + (255 * (b - r)) / delta;
	} else {
	    hue = 170 + (255 * (r - g)) / delta;
	}

	if (hue < 0) {
	    hue += 255;
	}
    }

    *v = val;
    *s = sat;
    *h = hue;
}

void
crimp_color_hsv_to_rgb (int h, int s, int v, int* r, int* g, int* b)
{
    int red, green, blue;
    red = green = blue = 0;

    if (!s) {
	/*
	 * A grey shade. Hue is irrelevant.
	 */

	red = green = blue = v;
    } else {
	int isector, ifrac, p, q, t;

	if (h >= 255) h = 0;
	h *= 10; /* Scale up to have full precision for the 1/6 points */

	isector = h / 425 ; /* <=> *2/850 <=> *6/2550 <=> *(360/2550)/60 */
	ifrac   = h - 425 * isector; /* frac * 425 */

	p = (v * (255       - s))                 / 255;
	q = (v * ((255*425) - s * ifrac))         / (255*425);
	t = (v * ((255*425) - s * (425 - ifrac))) / (255*425);

	switch (isector) {
	case 0: red = v; green = t; blue = p; break;
	case 1: red = q; green = v; blue = p; break;
	case 2: red = p; green = v; blue = t; break;
	case 3: red = p; green = q; blue = v; break;
	case 4: red = t; green = p; blue = v; break;
	case 5: red = v; green = p; blue = q; break;
	}

#if 0 /* Floating calculation with 0..360, 0..1, 0..1 after the initial scaling */
	float fh, fs, fv, fsector;
	int isector, p, q, t;

	fh = h * 360. / 255.;
	fs = s / 255.;
	fv = v / 255.;

	if (fh >= 360) fh = 0;

	fsector = fh / 60. ;
	isector = fsector;
	frac    = fsector - isector;

	p = 256 * fv * (1 - fs);
	q = 256 * fv * (1 - fs * frac);
	t = 256 * fv * (1 - fs * (1 - frac));

	switch (isector) {
	case 0: red = v; green = t; blue = p; break;
	case 1: red = q; green = v; blue = p; break;
	case 2: red = p; green = v; blue = t; break;
	case 3: red = p; green = q; blue = v; break;
	case 4: red = t; green = p; blue = v; break;
	case 5: red = v; green = p; blue = q; break;
	}
#endif
    }

    *r = red;
    *g = green;
    *b = blue;
}

#undef A
#undef B

#define T  (0.00885645167903563081) /* = (6/29)^3 */
#define Ti (0.20689655172413793103) /* = (6/29) = sqrt (T) */
#define A  (7.78703703703703703702) /* = (1/3)(29/6)^2 */
#define B  (0.13793103448275862068) /* = 4/29 */

static double
flabforw (double t)
{
    return ((t > T) ? (pow (t, 1./3.)) : (A*t+B));
}

static double
flabback (double t)
{
    return ((t > Ti) ? (t*t*t) : ((t-B)/A));
}

void
crimp_color_xyz_to_cielab (double x, double y, double z, double* l, double* a, double* b)
{
    /*
     * Whitepoint = (1,1,1). To convert XYZ for any other whitepoint predivide
     * the input values by Xn, Yn, Zn, i.e. before calling this function.
     */

    *l = 116 * flabforw (y) - 16;
    *a = 500 * (flabforw(x) - flabforw(y));
    *b = 200 * (flabforw(y) - flabforw(z));
}

void
crimp_color_cielab_to_xyz (double l, double a, double b, double* x, double* y, double* z)
{
    /*
     * Whitepoint = (1,1,1). To convert CIELAB for any other whitepoint post-multiply
     * the output values by Xn, Yn, Zn, i.e. after calling this function.
     */

    double L = (l+16)/116;

    *x = flabback (L);
    *y = flabback (L + a/500);
    *z = flabback (L + b/200);
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
