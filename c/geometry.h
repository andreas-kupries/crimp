#ifndef CRIMP_GEOMETRY_H
#define CRIMP_GEOMETRY_H
/*
 * CRIMP :: Declarations for the functions handling points, vectors,
 * and matrices.
 * (C) 2010.
 */

#include <image.h>

/*
 * API :: Core. 
 */

extern void         crimp_geo_warp_point (crimp_image* matrix, double* x, double* y);
extern crimp_image* crimp_geo_warp_init  (crimp_image* input,
					  crimp_image* forward,
					  int* origx, int* origy);

extern void crimp_rect_union (const crimp_geometry* a,
			      const crimp_geometry* b,
			      crimp_geometry* result);


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_GEOMETRY_H */
