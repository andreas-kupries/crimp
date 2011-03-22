#ifndef CRIMP_COLOR_H
#define CRIMP_COLOR_H
/*
 * CRIMP :: Color Conversion Declarations, and API.
 * (C) 2010.
 */

#include <tcl.h>

/*
 * API :: Mapping between various color spaces.
 */

extern void crimp_color_rgb_to_hsv (int r, int g, int b, int* h, int* s, int* v);
extern void crimp_color_hsv_to_rgb (int h, int s, int v, int* r, int* g, int* b);

/*
 * Domain of the XZY, and CIE LAB (L*a*b*) colorspaces ?
 * I.e. range of values ?
 *
 * The functions below assume Xn = Yn = Zn = 1 for the whitepoint. For any
 * other white point going to cielab requires pre-division of the input x, y,
 * and z by the whitepoint, and going to XYZ requires post-multiplication of
 * the output x, y, and z.
 */

extern void crimp_color_xyz_to_cielab (double x, double y, double z, double* l, double* a, double* b);
extern void crimp_color_cielab_to_xyz (double l, double a, double b, double* x, double* y, double* z);


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_COLOR_H */
