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

extern crimp_image* crimp_mat3x3_invers (crimp_image* matrix);
extern crimp_image* crimp_mat_multiply  (crimp_image* a, crimp_image* b);
extern void         crimp_transform     (crimp_image* matrix, float* x, float* y);

extern crimp_image* crimp_warp_setup (crimp_image* input, crimp_image* forward,
				      int* origx, int* origy);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_GEOMETRY_H */
