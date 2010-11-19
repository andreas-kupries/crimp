/*
 * CRIMP :: Geometry Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <geometry.h>
#include <linearalgebra.h>

/*
 * Definitions :: Core.
 */

void
crimp_geo_warp_point (crimp_image* matrix, double* x, double* y)
{
    double w = 1.0;
    crimp_la_multiply_matrix_3v (matrix, x, y, &w);

    *x = (*x) / w;
    *y = (*y) / w;
}

crimp_image*
crimp_geo_warp_init (crimp_image* input, crimp_image* forward, int* origx, int* origy)
{
    /*
     * Run the four corners of the input through the forward transformation to
     * get their locations, and use the results to determine dimensions of the
     * output image and the location of its origin point.
     *
     * NOTE: The input image may already come with origin point data. We have
     * to and are taking this into account when computing the input corners.
     */

    double xlu, xru, xld, xrd, left, right;
    double ylu, yru, yld, yrd, up, down;
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
    crimp_geo_warp_point (forward, &xlu, &ylu);

    xru = - iorigx + input->w - 1;
    yru = - iorigy;
    crimp_geo_warp_point (forward, &xru, &yru);

    xld = - iorigx;
    yld = - iorigy + input->h - 1;
    crimp_geo_warp_point (forward, &xld, &yld);

    xrd = - iorigx + input->w - 1;
    yrd = - iorigy + input->h - 1;
    crimp_geo_warp_point (forward, &xrd, &yrd);

    left  = MIN (MIN (xlu,xld), MIN (xru,xrd));
    right = MAX (MAX (xlu,xld), MAX (xru,xrd));
    up    = MIN (MIN (ylu,yld), MIN (yru,yrd));
    down  = MAX (MAX (ylu,yld), MAX (yru,yrd));

    ileft  = left;  if (ileft  > left)  ileft --;
    iright = right; if (iright < right) iright ++;
    iup    = up;    if (iup    > up)    iup --;
    idown  = down;  if (idown  < down)  idown ++;

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
