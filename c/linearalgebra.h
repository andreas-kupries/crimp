#ifndef CRIMP_LINEARALGEBRA_H
#define CRIMP_LINEARALGEBRA_H
/*
 * CRIMP :: Declarations for structures and functions for matrics and vectors.
 * (C) 2010.
 */

/*
 * Requirements. We represent matrices and vectors (which are 1xN, Nx1
 * matrices) as images, of type float. No need to invent additional
 * structures, as these will serve very well.
 */

#include <image.h>

/*
 * API :: Core. 
 */

extern crimp_image* crimp_la_invert_matrix_3x3   (crimp_image* matrix);
extern crimp_image* crimp_la_multiply_matrix     (crimp_image* a, crimp_image* b);
extern crimp_image* crimp_la_multiply_matrix_3x3 (crimp_image* a, crimp_image* b);

/*
 * For convenience, and memory efficiency. Matrix/Vector multiplication
 * without allocating a transient image for the vector.
 */

extern void   crimp_la_multiply_matrix_3v (crimp_image* matrix, double* x, double* y, double* w);
extern double crimp_la_scalar_multiply3   (double* xa, double* ya, double* wa,
					   double* xb, double* yb, double* wb);


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_LINEARALGEBRA_H */
