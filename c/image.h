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
 * Pixel Access Macros. RGBA / RGB
 */

/*
 * Manually optimized, factored the pixelsize out of the summands. It
 * is not sure if this is faster (easier to optimize), or if we were
 * to precompute the pitch (w*pixelsize), and have the pixel size mult
 * in each x ... As the pixel size is mostly 1, 2, 4, i.e. redundant
 * removed unity, or a power of 2, i.e handled as shift this should be
 * good enough. The only not so sure case is RGB, with pixel size of
 * 3.
 */

#define SZ(iptr) ((iptr)->type->size)

#define RED(iptr,x,y)   (0 + SZ(iptr) * ((x) + (y)*(iptr)->w))
#define GREEN(iptr,x,y) (1 + SZ(iptr) * ((x) + (y)*(iptr)->w))
#define BLUE(iptr,x,y)  (2 + SZ(iptr) * ((x) + (y)*(iptr)->w))
#define ALPHA(iptr,x,y) (3 + SZ(iptr) * ((x) + (y)*(iptr)->w))

#if 0 /* Unoptimized formulas */
#define RED(iptr,x,y)   (0 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*(iptr)->w))
#define GREEN(iptr,x,y) (1 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*(iptr)->w))
#define BLUE(iptr,x,y)  (2 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*(iptr)->w))
#define ALPHA(iptr,x,y) (3 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*(iptr)->w))
#endif

#define R(iptr,x,y) (iptr)->pixel [RED   (iptr,x,y)]
#define G(iptr,x,y) (iptr)->pixel [GREEN (iptr,x,y)]
#define B(iptr,x,y) (iptr)->pixel [BLUE  (iptr,x,y)]
#define A(iptr,x,y) (iptr)->pixel [ALPHA (iptr,x,y)]

/*
 * Pixel Access Macros. GREY8, GREY16, GREY32.
 */

#define INDEX(iptr,x,y) (((x)*SZ (iptr)) + ((y)*SZ (iptr)*(iptr)->w))

#define GREY8(iptr,x,y)                        (iptr)->pixel [INDEX (iptr,x,y)]
#define GREY16(iptr,x,y) *((unsigned short*) &((iptr)->pixel [INDEX (iptr,x,y)]))
#define GREY32(iptr,x,y) *((unsigned long*)  &((iptr)->pixel [INDEX (iptr,x,y)]))

/*
 * Other constants
 */

#define BLACK 0
#define WHITE 255

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
