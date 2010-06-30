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
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_COLOR_H */
