#ifndef CRIMP_RECT_H
#define CRIMP_RECT_H
/*
 * CRIMP :: Declarations for the functions handling rectangles, aka
 * bounding boxes, aka image geometries.
 * (C) 2012.
 */

/*
 * API :: Core. 
 */

/*
 * Structures describing images.
 *
 * - The geometry (bounding box) of an image.
 */

typedef struct crimp_geometry {
    int x; /* Location of the image in the infinite 2D plane */
    int y; /* s.a. */
    int w; /* Image dimension, width  */
    int h; /* Image dimension, height */
} crimp_geometry;


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_RECT_H */
