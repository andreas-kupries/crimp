/*
 * CRIMP :: Image Declarations, and API.
 * (C) 2010.
 */

#include <image_type.h>

/*
 * Structures describing images.
 */

typedef unsigned char* crimp_pixel_array;

typedef struct crimp_image {
    const crimp_imagetype* type;     /* Reference to type descriptor */
    int                    w;        /* Image dimension, width  */
    int                    h;        /* Image dimension, height */
    unsigned char          pixel[4]; /* Integrated pixel storage */
} crimp_image;

/*
 * API :: Core. Image lifecycle management,
 */

extern crimp_image* crimp_new (crimp_imagetype* type, int w, int h);
extern crimp_image* crimp_dup (crimp_image* image);
extern void         crimp_del (crimp_image* image);

/*
 * API :: Tcl. Manage Tcl_Obj's of images.
 */

extern Tcl_Obj* crimp_new_image_obj      (crimp_image*  image);
extern int      crimp_get_image_from_obj (Tcl_Interp*   interp,
					  Tcl_Obj*      imageObj,
					  crimp_image** image);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
