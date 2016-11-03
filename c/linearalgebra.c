/*
 * CRIMP :: Linear algebra Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <crimp_core/crimp_coreDecls.h>
#include <linearalgebra.h>

/*
 * Definitions :: Core.
 */

crimp_image*
crimp_la_invert_matrix_3x3 (crimp_image* matrix)
{
    crimp_image* result;
    int x, y;
    double cofactor [3][3];
    double det  = 0;
    double sign = 1;

    CRIMP_ASSERT_IMGTYPE (matrix, float);
    CRIMP_ASSERT (crimp_require_dim(matrix, 3, 3),"Unable to invert matrix, not 3x3");

    result = crimp_new_float (3, 3);

    for (y = 0; y < 3; y++) {
	int y1 = !y;
	int y2 = 2 - !(y - 2);

	for (x = 0; x < 3; x++) {
	    int x1 = !x;
	    int x2 = 2 - !(x - 2);

	    cofactor[y][x] = sign * ((FLOATP (matrix, x1, y1) * FLOATP (matrix, x2, y2)) -
				     (FLOATP (matrix, x2, y1) * FLOATP (matrix, x1, y2)));
	    sign = -sign;
	}

	det += FLOATP (matrix, 0, y) * cofactor[y][0];
    }

    if (det == 0) {
	return NULL;
    }

    for (y = 0; y < 3; y++) {
	for (x = 0; x < 3; x++) {

	    FLOATP (result, x, y) = cofactor[x][y] / det;
	}
    }

    return result;
}

crimp_image*
crimp_la_multiply_matrix (crimp_image* a, crimp_image* b)
{
    crimp_image* result;
    int x, y, w, n, m;

    CRIMP_ASSERT_IMGTYPE (a, float);
    CRIMP_ASSERT_IMGTYPE (b, float);
    CRIMP_ASSERT (crimp_require_height(a, crimp_w(b)),"Unable to multiply matrices, size mismatch");
    CRIMP_ASSERT (crimp_require_height(b, crimp_w(a)),"Unable to multiply matrices, size mismatch");

    n = crimp_h (a);
    m = crimp_w (a);

    result = crimp_new_float (n, n);

    for (y = 0; y < n; y++) {
	for (x = 0; x < n; x++) {

	    FLOATP (result, x, y) = 0;
	    for (w = 0; w < m; w++) {
		FLOATP (result, x, y) += FLOATP (a, w, y) * FLOATP (b, x, w);
	    }
	}
    }

    return result;
}

crimp_image*
crimp_la_multiply_matrix_3x3 (crimp_image* a, crimp_image* b)
{
    crimp_image* result;

    CRIMP_ASSERT_IMGTYPE (a, float);
    CRIMP_ASSERT_IMGTYPE (b, float);
    CRIMP_ASSERT (crimp_require_dim(a, 3, 3),"Unable to multiply matrices, 3x3 expected");
    CRIMP_ASSERT (crimp_require_dim(b, 3, 3),"Unable to multiply matrices, 3x3 expected");

    result = crimp_new_float (3, 3);

    /*
     * Unrolled scalar products, no loops whatsoever. This is possible only
     * because we know the size, and the size is small.
     *
     *             Z            = A            * B
     *             ( .. .. .. )   ( .. .. .. )   ( .. x0 .. )
     * A * B = Z = ( .. xy .. ) = ( 0y 1y 2y ) * ( .. x1 .. )
     *             ( .. .. .. )   ( .. .. .. )   ( .. x2 .. )
     *
     */

#define SP3(r,x,y) FLOATP (r, x, y) = FLOATP (a,0,y) * FLOATP (b,x,0) + FLOATP (a,1,y) * FLOATP (b,x,1) + FLOATP (a,2,y) * FLOATP (b,x,2)

    SP3 (result, 0, 0);
    SP3 (result, 0, 1);
    SP3 (result, 0, 2);
    SP3 (result, 1, 0);
    SP3 (result, 1, 1);
    SP3 (result, 1, 2);
    SP3 (result, 2, 0);
    SP3 (result, 2, 1);
    SP3 (result, 2, 2);

    return result;
}

void
crimp_la_multiply_matrix_3v (crimp_image* matrix, double* x, double* y, double* w)
{
    /*
     * Inlined multiplication of matrix and column! vector (x, y, w).
     * The vector is multiplied from the right
     *
     *  z      = A            * v
     *  ( .. )   ( .. .. .. )   ( .0 )
     *  ( .y ) = ( 0y 1y 2y ) * ( .1 )
     *  ( .. )   ( .. .. .. )   ( .2 )
     */

    double xo = (*x) * FLOATP (matrix, 0, 0) + (*y) * FLOATP (matrix, 1, 0) + (*w) * FLOATP (matrix, 2, 0);
    double yo = (*x) * FLOATP (matrix, 0, 1) + (*y) * FLOATP (matrix, 1, 1) + (*w) * FLOATP (matrix, 2, 1);
    double wo = (*x) * FLOATP (matrix, 0, 2) + (*y) * FLOATP (matrix, 1, 2) + (*w) * FLOATP (matrix, 2, 2);

    *x = xo;
    *y = yo;
    *w = wo;
}

double
crimp_la_scalar_multiply3 (double* xa, double* ya, double* wa,
			   double* xb, double* yb, double* wb)
{
    return (*xa)*(*xb) + (*ya)*(*yb) + (*wa)*(*wb);
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
