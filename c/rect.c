/*
 * CRIMP :: Rectangle Definitions (Implementation).
 * (C) 2012.
 */

/*
 * Import declarations.
 */

#include <crimp_core/crimp_coreDecls.h>
#include <cutil.h>

/*
 * Definitions :: Core.
 */

extern void
crimp_rect_union (const crimp_geometry* a,
		  const crimp_geometry* b,
		  crimp_geometry* result)
{
    /*
     * Compute the bounding box first, as min and max of the individual
     * boundaries. The max values are one too high, which is canceled
     * when computing the dimensions.
     */

    int minx = MIN (a->x, b->x);
    int miny = MIN (a->y, b->y);
    int maxx = MAX (a->x + a->w, b->x + b->w);
    int maxy = MAX (a->y + a->h, b->y + b->h);

    /*
     * And convert back into a plain geometry with location dimensions.
     */

    result->x = minx;
    result->y = miny;
    result->w = maxx - minx;
    result->h = maxy - miny;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
