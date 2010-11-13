/*
 * CRIMP :: Geometry Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <geometry.h>

/*
 * Definitions :: Core.
 */

crimp_image*
crimp_mat3x3_invers (crimp_image* matrix)
{
    crimp_image* result;
    int x, y;
    double cofactor [3][3];
    double det  = 0;
    double sign = 1;

    ASSERT_IMGTYPE (matrix, float);
    ASSERT (crimp_require_dim(matrix, 3, 3),"Unable to invert matrix, not 3x3");

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
crimp_mat_multiply (crimp_image* a, crimp_image* b)
{
    crimp_image* result;
    int x, y, w;

    ASSERT_IMGTYPE (a, float);
    ASSERT_IMGTYPE (b, float);
    ASSERT (crimp_require_height(a, b->w),"Unable to multiply matrices, size mismatch");
    ASSERT (crimp_require_height(b, a->w),"Unable to multiply matrices, size mismatch");

    result = crimp_new_float (a->h, a->h);

    for (y = 0; y < a->h; y++) {
	for (x = 0; x < a->h; x++) {

	    FLOATP (result, x, y) = 0;
	    for (w = 0; w < a->w; w++) {
		FLOATP (result, x, y) += FLOATP (a, w, y) * FLOATP (b, x, w);
	    }
	}
    }

    return result;
}

void
crimp_transform (crimp_image* matrix, float* x, float* y)
{
    /*
     * Inlined multiplication of matrix and vector
     */

    float xout   = (*x) * FLOATP (matrix, 0, 0) + (*y) * FLOATP (matrix, 1, 0) + FLOATP (matrix, 2, 0);
    float yout   = (*x) * FLOATP (matrix, 0, 1) + (*y) * FLOATP (matrix, 1, 1) + FLOATP (matrix, 2, 1);
    float weight = (*x) * FLOATP (matrix, 0, 2) + (*y) * FLOATP (matrix, 1, 2) + FLOATP (matrix, 2, 2);

    *x = xout/weight;
    *y = yout/weight;
}

crimp_image*
crimp_warp_setup (crimp_image* input, crimp_image* forward, int* origx, int* origy)
{
    /*
     * Run the four corners of the input through the forward transformation to
     * get their locations, and use the results to determine dimensions of the
     * output image and the location of its origin point.
     *
     * NOTE: The input image may already come with origin point data. We have
     * to and are taking this into account when computing the input corners.
     */

    float xlu, xru, xld, xrd, left, right;
    float ylu, yru, yld, yrd, up, down;
    int ileft, iright, iup, idown, w, h, iorigx, iorigy, oc;
    Tcl_Obj* meta;
    Tcl_Obj* key1 = Tcl_NewStringObj ("crimp", -1);
    Tcl_Obj* key2 = Tcl_NewStringObj ("origin", -1);
    Tcl_Obj* cmeta;
    Tcl_Obj* corig;
    Tcl_Obj* orig [2];

    if (!input->meta ||
	(Tcl_DictObjGet(NULL, input->meta, key1, &cmeta) != TCL_OK) ||
	(Tcl_DictObjGet(NULL, cmeta, key2, &corig) != TCL_OK) ||
	(Tcl_ListObjGetElements(NULL, corig, &oc, &orig) != TCL_OK) ||
	(Tcl_GetIntFromObj(NULL,orig[0], &iorigx) != TCL_OK) ||
	(Tcl_GetIntFromObj(NULL,orig[1], &iorigy) != TCL_OK)) {
	iorigx = iorigy = 0;
    }

    xlu = - iorigx;
    ylu = - iorigy;
    crimp_transform (forward, &xlu, &ylu);

    xru = - iorigx + input->w - 1;
    yru = - iorigy;
    crimp_transform (forward, &xru, &yru);

    xld = - iorigx;
    yld = - iorigy + input->h - 1;
    crimp_transform (forward, &xld, &yld);

    xrd = - iorigx + input->w - 1;
    yrd = - iorigy + input->h - 1;
    crimp_transform (forward, &xrd, &yrd);

    left  = MIN (MIN (xlu,xld), MIN (xru,xrd));
    right = MAX (MAX (xlu,xld), MAX (xru,xrd));
    up    = MIN (MIN (ylu,yld), MIN (yru,yrd));
    down  = MAX (MAX (ylu,yld), MAX (yru,yrd));

    ileft  = left;  if (ileft  >= left)  ileft --;
    iright = right; if (iright <= right) iright ++;
    iup    = up;    if (iup    >= up)    iup --;
    idown  = down;  if (idown  <= down)  idown ++;

    w = iright - ileft + 1;
    h = idown  - iup   + 1;

    *origx = ileft;
    *origy = iup;

    orig [0] = Tcl_NewIntObj (ileft);
    orig [1] = Tcl_NewIntObj (iup);

    corig = Tcl_NewListObj (2, orig);
    cmeta = Tcl_NewDictObj (); Tcl_DictObjPut (NULL, cmeta, key2, corig);
    meta  = Tcl_NewDictObj (); Tcl_DictObjPut (NULL, meta,  key1, cmeta);

    return crimp_newm (input->itype, w, h, meta);
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
