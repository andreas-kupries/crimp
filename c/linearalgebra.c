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

static crimp_image*
crimp_la_invert_matrix_3x3_float (crimp_image* matrix)
{
    crimp_image* result;
    int x, y;
    double cofactor [3][3];
    double det  = 0;
    double sign = 1;

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

static crimp_image*
crimp_la_invert_matrix_3x3_double (crimp_image* matrix)
{
    crimp_image* result;
    int x, y;
    double cofactor [3][3];
    double det  = 0;
    double sign = 1;

    result = crimp_new_double (3, 3);

    for (y = 0; y < 3; y++) {
	int y1 = !y;
	int y2 = 2 - !(y - 2);

	for (x = 0; x < 3; x++) {
	    int x1 = !x;
	    int x2 = 2 - !(x - 2);

	    cofactor[y][x] = sign * ((DOUBLEP (matrix, x1, y1) * DOUBLEP (matrix, x2, y2)) -
				     (DOUBLEP (matrix, x2, y1) * DOUBLEP (matrix, x1, y2)));
	    sign = -sign;
	}

	det += DOUBLEP (matrix, 0, y) * cofactor[y][0];
    }

    if (det == 0) {
	return NULL;
    }

    for (y = 0; y < 3; y++) {
	for (x = 0; x < 3; x++) {
	    DOUBLEP (result, x, y) = cofactor[x][y] / det;
	}
    }

    return result;
}

crimp_image*
crimp_la_invert_matrix_3x3 (crimp_image* matrix)
{
    CRIMP_ASSERT (crimp_require_dim(matrix, 3, 3),"Unable to invert matrix, not 3x3");

    if (CRIMP_IS_IMGTYPE (matrix, float)) {
	return crimp_la_invert_matrix_3x3_float (matrix);
    } else if (CRIMP_IS_IMGTYPE (matrix, double)) {
	return crimp_la_invert_matrix_3x3_double (matrix);
    } else {
	CRIMP_ASSERT (0, "expected image type " CRIMP_STR(float) ", or " CRIMP_STR(double));
    }
}

static crimp_image*
crimp_la_multiply_matrix_ff (crimp_image* a, crimp_image* b)
{
    crimp_image* result;
    int x, y, w, n, m;

    CRIMP_ASSERT (crimp_require_height(a, crimp_w(b)),"Unable to multiply matrices, size mismatch");
    CRIMP_ASSERT (crimp_require_height(b, crimp_w(a)),"Unable to multiply matrices, size mismatch");

    n = crimp_h (a);
    m = crimp_w (a);

    result = crimp_new_float (n, n);

    for (y = 0; y < n; y++) {
	for (x = 0; x < n; x++) {
	    double dotproduct = 0;

	    for (w = 0; w < m; w++) {
		dotproduct += FLOATP (a, w, y) * FLOATP (b, x, w);
	    }
	    FLOATP (result, x, y) = dotproduct;
	}
    }

    return result;
}

static crimp_image*
crimp_la_multiply_matrix_fd (crimp_image* a, crimp_image* b)
{
    crimp_image* result;
    int x, y, w, n, m;

    CRIMP_ASSERT (crimp_require_height(a, crimp_w(b)),"Unable to multiply matrices, size mismatch");
    CRIMP_ASSERT (crimp_require_height(b, crimp_w(a)),"Unable to multiply matrices, size mismatch");

    n = crimp_h (a);
    m = crimp_w (a);

    result = crimp_new_double (n, n);

    for (y = 0; y < n; y++) {
	for (x = 0; x < n; x++) {
	    double dotproduct = 0;

	    for (w = 0; w < m; w++) {
		dotproduct += FLOATP (a, w, y) * DOUBLEP (b, x, w);
	    }
	    DOUBLEP (result, x, y) = dotproduct;
	}
    }

    return result;
}

static crimp_image*
crimp_la_multiply_matrix_df (crimp_image* a, crimp_image* b)
{
    crimp_image* result;
    int x, y, w, n, m;

    CRIMP_ASSERT (crimp_require_height(a, crimp_w(b)),"Unable to multiply matrices, size mismatch");
    CRIMP_ASSERT (crimp_require_height(b, crimp_w(a)),"Unable to multiply matrices, size mismatch");

    n = crimp_h (a);
    m = crimp_w (a);

    result = crimp_new_double (n, n);

    for (y = 0; y < n; y++) {
	for (x = 0; x < n; x++) {
	    double dotproduct = 0;

	    for (w = 0; w < m; w++) {
		dotproduct += DOUBLEP (a, w, y) * FLOATP (b, x, w);
	    }
	    DOUBLEP (result, x, y) = dotproduct;
	}
    }

    return result;
}

static crimp_image*
crimp_la_multiply_matrix_dd (crimp_image* a, crimp_image* b)
{
    crimp_image* result;
    int x, y, w, n, m;

    CRIMP_ASSERT (crimp_require_height(a, crimp_w(b)),"Unable to multiply matrices, size mismatch");
    CRIMP_ASSERT (crimp_require_height(b, crimp_w(a)),"Unable to multiply matrices, size mismatch");

    n = crimp_h (a);
    m = crimp_w (a);

    result = crimp_new_double (n, n);

    for (y = 0; y < n; y++) {
	for (x = 0; x < n; x++) {
	    double dotproduct = 0;

	    for (w = 0; w < m; w++) {
	       dotproduct += DOUBLEP (a, w, y) * DOUBLEP (b, x, w);
	    }
	    DOUBLEP (result, x, y) = dotproduct;
	}
    }

    return result;
}

crimp_image*
crimp_la_multiply_matrix (crimp_image* a, crimp_image* b)
{
    /* TODO: Structure better, avoid redundant type checks.
     */

    if (CRIMP_IS_IMGTYPE (a, float) &&
	CRIMP_IS_IMGTYPE (b, float)) {
	return crimp_la_multiply_matrix_ff (a, b);
    }
    if (CRIMP_IS_IMGTYPE (a, float) &&
	CRIMP_IS_IMGTYPE (b, double)) {
	return crimp_la_multiply_matrix_fd (a, b);
    }
    if (CRIMP_IS_IMGTYPE (a, double) &&
	CRIMP_IS_IMGTYPE (b, float)) {
	return crimp_la_multiply_matrix_df (a, b);
    }
    if (CRIMP_IS_IMGTYPE (a, double) &&
	CRIMP_IS_IMGTYPE (b, double)) {
	return crimp_la_multiply_matrix_dd (a, b);
    }

    CRIMP_ASSERT (0, "expected image type " CRIMP_STR(float) ", or " CRIMP_STR(double));
    return 0;
}

static crimp_image*
crimp_la_multiply_matrix_3x3_ff (crimp_image* a, crimp_image* b)
{
    crimp_image* result;

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

#define SP3(r,x,y) FLOATP (r, x, y) = \
        (((double) FLOATP (a,0,y)) * ((double) FLOATP (b,x,0)) + \
	 ((double) FLOATP (a,1,y)) * ((double) FLOATP (b,x,1)) + \
	 ((double) FLOATP (a,2,y)) * ((double) FLOATP (b,x,2)))

    SP3 (result, 0, 0);
    SP3 (result, 0, 1);
    SP3 (result, 0, 2);
    SP3 (result, 1, 0);
    SP3 (result, 1, 1);
    SP3 (result, 1, 2);
    SP3 (result, 2, 0);
    SP3 (result, 2, 1);
    SP3 (result, 2, 2);

#undef SP3
    return result;
}

static crimp_image*
crimp_la_multiply_matrix_3x3_fd (crimp_image* a, crimp_image* b)
{
    crimp_image* result;

    result = crimp_new_double (3, 3);

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

#define SP3(r,x,y) DOUBLEP (r, x, y) = FLOATP (a,0,y) * DOUBLEP (b,x,0) + FLOATP (a,1,y) * DOUBLEP (b,x,1) + FLOATP (a,2,y) * DOUBLEP (b,x,2)

    SP3 (result, 0, 0);
    SP3 (result, 0, 1);
    SP3 (result, 0, 2);
    SP3 (result, 1, 0);
    SP3 (result, 1, 1);
    SP3 (result, 1, 2);
    SP3 (result, 2, 0);
    SP3 (result, 2, 1);
    SP3 (result, 2, 2);

#undef SP3
    return result;
}

static crimp_image*
crimp_la_multiply_matrix_3x3_df (crimp_image* a, crimp_image* b)
{
    crimp_image* result;

    result = crimp_new_double (3, 3);

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

#define SP3(r,x,y) DOUBLEP (r, x, y) = DOUBLEP (a,0,y) * FLOATP (b,x,0) + DOUBLEP (a,1,y) * FLOATP (b,x,1) + DOUBLEP (a,2,y) * FLOATP (b,x,2)

    SP3 (result, 0, 0);
    SP3 (result, 0, 1);
    SP3 (result, 0, 2);
    SP3 (result, 1, 0);
    SP3 (result, 1, 1);
    SP3 (result, 1, 2);
    SP3 (result, 2, 0);
    SP3 (result, 2, 1);
    SP3 (result, 2, 2);

#undef SP3
    return result;
}

static crimp_image*
crimp_la_multiply_matrix_3x3_dd (crimp_image* a, crimp_image* b)
{
    crimp_image* result;

    result = crimp_new_double (3, 3);

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

#define SP3(r,x,y) DOUBLEP (r, x, y) = DOUBLEP (a,0,y) * DOUBLEP (b,x,0) + DOUBLEP (a,1,y) * DOUBLEP (b,x,1) + DOUBLEP (a,2,y) * DOUBLEP (b,x,2)

    SP3 (result, 0, 0);
    SP3 (result, 0, 1);
    SP3 (result, 0, 2);
    SP3 (result, 1, 0);
    SP3 (result, 1, 1);
    SP3 (result, 1, 2);
    SP3 (result, 2, 0);
    SP3 (result, 2, 1);
    SP3 (result, 2, 2);

#undef SP3
    return result;
}

crimp_image*
crimp_la_multiply_matrix_3x3 (crimp_image* a, crimp_image* b)
{
    CRIMP_ASSERT (crimp_require_dim(a, 3,3),"Unable to multiply matrices, 3x3 expected");
    CRIMP_ASSERT (crimp_require_dim(b, 3,3),"Unable to multiply matrices, 3x3 expected");

    /* TODO: Structure better, avoid redundant type checks.
     */

    if (CRIMP_IS_IMGTYPE (a, float) &&
	CRIMP_IS_IMGTYPE (b, float)) {
	return crimp_la_multiply_matrix_3x3_ff (a, b);
    }
    if (CRIMP_IS_IMGTYPE (a, float) &&
	CRIMP_IS_IMGTYPE (b, double)) {
	return crimp_la_multiply_matrix_3x3_fd (a, b);
    }
    if (CRIMP_IS_IMGTYPE (a, double) &&
	CRIMP_IS_IMGTYPE (b, float)) {
	return crimp_la_multiply_matrix_3x3_df (a, b);
    }
    if (CRIMP_IS_IMGTYPE (a, double) &&
	CRIMP_IS_IMGTYPE (b, double)) {
	return crimp_la_multiply_matrix_3x3_dd (a, b);
    }

    CRIMP_ASSERT (0, "expected image type " CRIMP_STR(float) ", or " CRIMP_STR(double));
    return 0;
}

static void
crimp_la_multiply_matrix_3v_float (crimp_image* matrix, double* x, double* y, double* w)
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

static void
crimp_la_multiply_matrix_3v_double (crimp_image* matrix, double* x, double* y, double* w)
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

    double xo = (*x) * DOUBLEP (matrix, 0, 0) + (*y) * DOUBLEP (matrix, 1, 0) + (*w) * DOUBLEP (matrix, 2, 0);
    double yo = (*x) * DOUBLEP (matrix, 0, 1) + (*y) * DOUBLEP (matrix, 1, 1) + (*w) * DOUBLEP (matrix, 2, 1);
    double wo = (*x) * DOUBLEP (matrix, 0, 2) + (*y) * DOUBLEP (matrix, 1, 2) + (*w) * DOUBLEP (matrix, 2, 2);

    *x = xo;
    *y = yo;
    *w = wo;
}

void
crimp_la_multiply_matrix_3v (crimp_image* matrix, double* x, double* y, double* w)
{
    CRIMP_ASSERT (crimp_require_height(matrix, 3),"Unable to multiply matrix, not 3xN");

    /*
     * Inlined multiplication of matrix and column! vector (x, y, w).
     * The vector is multiplied from the right
     *
     *  z      = A            * v
     *  ( .. )   ( .. .. .. )   ( .0 )
     *  ( .y ) = ( 0y 1y 2y ) * ( .1 )
     *  ( .. )   ( .. .. .. )   ( .2 )
     */

    if (CRIMP_IS_IMGTYPE (matrix, float)) {
	return crimp_la_multiply_matrix_3v_float (matrix, x, y, w);
    } else if (CRIMP_IS_IMGTYPE (matrix, double)) {
	return crimp_la_multiply_matrix_3v_double (matrix, x, y, w);
    } else {
	CRIMP_ASSERT (0, "expected image type " CRIMP_STR(float) ", or " CRIMP_STR(double));
    }
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
