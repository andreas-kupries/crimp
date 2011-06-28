#ifndef CRIMP_IMAGE_H
#define CRIMP_IMAGE_H
/*
 * CRIMP :: Image Declarations, and API :: PUBLIC
 * (C) 2010 - 2011
 */

#include <common.h>
#include <image_type.h>

/*
 * Structures describing images.
 */

typedef unsigned char* crimp_pixel_array;

typedef struct crimp_image {
    Tcl_Obj*               meta;     /* Tcl level client data */
    const crimp_imagetype* itype;    /* Reference to type descriptor */
    int                    w;        /* Image dimension, width  */
    int                    h;        /* Image dimension, height */
    unsigned char          pixel[4]; /* Integrated pixel storage */
} crimp_image;

/*
 * Pixel Access Macros. General access to a 'color' channel.
 */

#define CRIMP_CHAN(iptr,c,x,y) ((c) + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))
#define CH(iptr,c,x,y)   (iptr)->pixel [CRIMP_CHAN (iptr,c,x,y)]

/*
 * Pixel Access Macros. RGBA / RGB
 */

/*
 * Manually optimized, factored the pixelsize out of the summands. It
 * is not sure if this is faster (easier to optimize), or if we should
 * precompute the pitch (w*pixelsize), and have the pixel size mult
 * in each x ... As the pixel size is mostly 1, 2, 4, i.e. redundant
 * removed unity, or a power of 2, i.e handled as shift this should be
 * good enough. The only not so sure case is RGB, with pixel size of 3.
 */

#define SZ(iptr) ((iptr)->itype->size)

#define RED(iptr,x,y)   (0 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))
#define GREEN(iptr,x,y) (1 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))
#define BLUE(iptr,x,y)  (2 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))
#define ALPHA(iptr,x,y) (3 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))

#if 0 /* Unoptimized formulas */
#define RED(iptr,x,y)   (0 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->w)))
#define GREEN(iptr,x,y) (1 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->w)))
#define BLUE(iptr,x,y)  (2 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->w)))
#define ALPHA(iptr,x,y) (3 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->w)))
#endif

#define R(iptr,x,y) (iptr)->pixel [RED   (iptr,x,y)]
#define G(iptr,x,y) (iptr)->pixel [GREEN (iptr,x,y)]
#define B(iptr,x,y) (iptr)->pixel [BLUE  (iptr,x,y)]
#define A(iptr,x,y) (iptr)->pixel [ALPHA (iptr,x,y)]

/*
 * Pixel Access Macros. GREY8, GREY16, GREY32, FLOATP.
 *
 * NOTE: The casts should use standard types where we we know the size in
 *       bytes exactly, by definition.
 */

#define CRIMP_INDEX(iptr,x,y) \
    (((x)*SZ (iptr)) + \
     ((y)*SZ (iptr)*(((size_t) (iptr)->w))))

#define GREY8(iptr,x,y)  *((unsigned char*)  &((iptr)->pixel [CRIMP_INDEX (iptr,x,y)]))
#define GREY16(iptr,x,y) *((unsigned short*) &((iptr)->pixel [CRIMP_INDEX (iptr,x,y)]))
#define GREY32(iptr,x,y) *((unsigned int* )  &((iptr)->pixel [CRIMP_INDEX (iptr,x,y)]))
#define FLOATP(iptr,x,y) *((float*)          &((iptr)->pixel [CRIMP_INDEX (iptr,x,y)]))

/*
 * Pixel as 2-complement numbers (-128..127, instead of unsigned 0..255).
 */

#define SGREY8(iptr,x,y) *((signed char*)  &((iptr)->pixel [CRIMP_INDEX (iptr,x,y)]))

/*
 * Pixel Access Macros. HSV.
 */

#define HUE(iptr,x,y) (0 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))
#define SAT(iptr,x,y) (1 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))
#define VAL(iptr,x,y) (2 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->w)))

#define H(iptr,x,y) (iptr)->pixel [HUE (iptr,x,y)]
#define S(iptr,x,y) (iptr)->pixel [SAT (iptr,x,y)]
#define V(iptr,x,y) (iptr)->pixel [VAL (iptr,x,y)]

/*
 * Other constants
 */

#define BLACK 0
#define WHITE 255

#define OPAQUE      255
#define TRANSPARENT 0

/*
 * Area calculations macros.
 */

#define CRIMP_RECT_AREA(w,h) (((size_t) (w)) * (h))
#define crimp_image_area(iptr) (CRIMP_RECT_AREA ((iptr)->w, (iptr)->h))

/*
 * API :: Core. Image lifecycle management.
 */

extern crimp_image* crimp_new  (const crimp_imagetype* type, int w, int h);
extern crimp_image* crimp_newm (const crimp_imagetype* type, int w, int h, Tcl_Obj* meta);
extern crimp_image* crimp_dup  (crimp_image* image);
extern void         crimp_del  (crimp_image* image);

#define crimp_new_hsv(w,h)    (crimp_new (crimp_imagetype_find ("crimp::image::hsv"),    (w), (h)))
#define crimp_new_rgba(w,h)   (crimp_new (crimp_imagetype_find ("crimp::image::rgba"),   (w), (h)))
#define crimp_new_rgb(w,h)    (crimp_new (crimp_imagetype_find ("crimp::image::rgb"),    (w), (h)))
#define crimp_new_grey8(w,h)  (crimp_new (crimp_imagetype_find ("crimp::image::grey8"),  (w), (h)))
#define crimp_new_grey16(w,h) (crimp_new (crimp_imagetype_find ("crimp::image::grey16"), (w), (h)))
#define crimp_new_grey32(w,h) (crimp_new (crimp_imagetype_find ("crimp::image::grey32"), (w), (h)))
#define crimp_new_float(w,h)  (crimp_new (crimp_imagetype_find ("crimp::image::float"),  (w), (h)))

#define crimp_new_like(image)           (crimp_newm ((image)->itype, (image)->w, (image)->h, (image)->meta))
#define crimp_new_like_transpose(image) (crimp_newm ((image)->itype, (image)->h, (image)->w, (image)->meta))

/*
 * API :: Tcl. Manage Tcl_Obj's of images.
 */

extern Tcl_Obj* crimp_new_image_obj      (crimp_image*  image);
extern int      crimp_get_image_from_obj (Tcl_Interp*   interp,
					  Tcl_Obj*      imageObj,
					  crimp_image** image);

#define crimp_input(objvar,imagevar,itype) \
    if (crimp_get_image_from_obj (interp, (objvar), &(imagevar)) != TCL_OK) { \
	return TCL_ERROR; \
    } \
    CRIMP_ASSERT_IMGTYPE (imagevar, itype)

#define crimp_input_any(objvar,imagevar) \
    if (crimp_get_image_from_obj (interp, (objvar), &(imagevar)) != TCL_OK) { \
	return TCL_ERROR; \
    }

#define crimp_eq_dim(imagea,imageb) \
    (((imagea)->w == (imageb)->w) && ((imagea)->h == (imageb)->h))

#define crimp_eq_height(imagea,imageb) \
    ((imagea)->h == (imageb)->h)

#define crimp_eq_width(imagea,imageb) \
    ((imagea)->w == (imageb)->w)

#define crimp_require_dim(image,rw,rh)					\
    (((image)->w == (rw)) && ((image)->h == (rh)))

#define crimp_require_height(image,rh)					\
    ((image)->h == (rh))

#define crimp_require_width(image,rw)					\
    ((image)->w == (rw))


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_IMAGE_H */
