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

void
crimp_geo_warp_box (crimp_geometry* input, crimp_image* forward, crimp_geometry* output)
{
    /*
     * Run the four corners of the input through the forward transformation to
     * get their locations, and use the results to determine geometry of the
     * output image, i.e. dimensions and location of its origin point.
     *
     * NOTE: We have to take the origin of the input image into account when
     * computing the input corners.
     */

    double xlu, xru, xld, xrd, left, right;
    double ylu, yru, yld, yrd, up, down;
    int ileft, iright, iup, idown, w, h, iorigx, iorigy, oc = 0;

    iorigx = input->x;
    iorigy = input->y;

    xlu = - iorigx;
    ylu = - iorigy;

    crimp_geo_warp_point (forward, &xlu, &ylu);

    xru = - iorigx + input->w - 1;
    yru = - iorigy;

    crimp_geo_warp_point (forward, &xru, &yru);

    xld = - iorigx;
    yld = - iorigy + input->h;

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

    output->x = ileft;
    output->y = iup;
    output->w = iright - ileft + 1;
    output->h = idown  - iup   + 1;
}

crimp_image*
crimp_geo_warp_init (crimp_image* input, crimp_image* forward, int* origx, int* origy)
{
    crimp_image* result;
    crimp_geometry warped;

    crimp_geo_warp_box (&input->geo, forward, &warped);

    result = crimp_new_atg (input->itype, warped);
    return result;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
