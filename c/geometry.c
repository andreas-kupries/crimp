/*
 * CRIMP :: Geometry Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <crimp_core/crimp_coreDecls.h>
#include <geometry.h>
#include <linearalgebra.h>
#include <util.h>

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
     * get their locations, and use the results to determine geometry of the
     * output image, i.e. dimensions and location of its origin point.
     *
     * NOTE: We have to take the origin of the input image into account when
     * computing the input corners.
     */

    crimp_image* result;
    double xlu, xru, xld, xrd, left, right;
    double ylu, yru, yld, yrd, up, down;
    int ileft, iright, iup, idown, w, h, iorigx, iorigy, oc = 0;

    iorigx = crimp_x (input);
    iorigy = crimp_y (input);

    xlu = - iorigx;
    ylu = - iorigy;
    crimp_geo_warp_point (forward, &xlu, &ylu);

    xru = - iorigx + crimp_w(input) - 1;
    yru = - iorigy;
    crimp_geo_warp_point (forward, &xru, &yru);

    xld = - iorigx;
    yld = - iorigy + crimp_h(input);
    crimp_geo_warp_point (forward, &xld, &yld);

    xrd = - iorigx + crimp_w(input) - 1;
    yrd = - iorigy + crimp_h(input) - 1;
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

    result = crimp_new_at (input->itype, ileft, iup, w, h);
    return result;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
