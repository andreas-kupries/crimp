#ifndef CRIMP_IMAGE_H
#define CRIMP_IMAGE_H
/*
 * CRIMP :: Image Declarations, and API :: PUBLIC
 * (C) 2010 - 2011
 */

#include "common.h"
#include "image_type.h"
#include "rect.h"

/*
 * Structures describing images.
 *
 * - A convenient name for a memory block of pixel data
 * - The image itself.
 */

typedef unsigned char* crimp_pixel_array;

typedef struct crimp_image {
    Tcl_Obj*               meta;     /* Tcl level client data */
    const crimp_imagetype* itype;    /* Reference to type descriptor */
    crimp_geometry         geo;      /* Image geometry, bounding box */
    unsigned char          pixel[4]; /* Integrated pixel storage */
} crimp_image;

/*
 * Pixel Access Macros. General access to a 'color' channel.
 */

#define CRIMP_CHAN(iptr,c,x,y) ((c) + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
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

#define RED(iptr,x,y)   (0 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define GREEN(iptr,x,y) (1 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define BLUE(iptr,x,y)  (2 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define ALPHA(iptr,x,y) (3 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))

#if 0 /* Unoptimized formulas */
#define RED(iptr,x,y)   (0 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->geo.w)))
#define GREEN(iptr,x,y) (1 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->geo.w)))
#define BLUE(iptr,x,y)  (2 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->geo.w)))
#define ALPHA(iptr,x,y) (3 + ((x)*SZ (iptr)) + ((y)*SZ (iptr)*((size_t) (iptr)->geo.w)))
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
     ((y)*SZ (iptr)*(((size_t) (iptr)->geo.w))))

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

#define HUE(iptr,x,y) (0 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define SAT(iptr,x,y) (1 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define VAL(iptr,x,y) (2 + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))

#define H(iptr,x,y) (iptr)->pixel [HUE (iptr,x,y)]
#define S(iptr,x,y) (iptr)->pixel [SAT (iptr,x,y)]
#define V(iptr,x,y) (iptr)->pixel [VAL (iptr,x,y)]

/*
 * Pixel Access Macros. FPCOMPLEX.
 */

#define REAL(iptr,x,y)             (0              + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define IMAGINARY(iptr,x,y)        (sizeof(float)  + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))
#define CHANF(iptr,c,x,y)   (((c) * sizeof(float)) + SZ(iptr) * ((x) + (y)*((size_t) (iptr)->geo.w)))

#define RE(iptr,x,y)    *((float*) &((iptr)->pixel [REAL      (iptr,x,y)]))
#define IM(iptr,x,y)    *((float*) &((iptr)->pixel [IMAGINARY (iptr,x,y)]))
#define CHF(iptr,c,x,y) *((float*) &((iptr)->pixel [CHANF   (iptr,c,x,y)]))

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
#define crimp_image_area(iptr) (CRIMP_RECT_AREA (crimp_w(iptr), crimp_h(iptr)))

#define crimp_place(image,ix,iy)			\
    ((image)->geo.x = (ix), (image)->geo.y = (iy))

#define crimp_inside(image,px,py) \
    ((crimp_x(image) <= (px)) && ((px) < (crimp_x(image) + crimp_w(image))) && \
     (crimp_y(image) <= (py)) && ((py) < (crimp_y(image) + crimp_h(image))))

#define crimp_x(image) ((image)->geo.x)
#define crimp_y(image) ((image)->geo.y)
#define crimp_w(image) ((image)->geo.w)
#define crimp_h(image) ((image)->geo.h)

/*
 * Convenience macros for the creation of images with predefined image types.
 */

#define crimp_new_atg(type,g)     (crimp_new_at  ((type), (g).x, (g).y, (g).w, (g).h))
#define crimp_new(type,w,h)       (crimp_new_at  ((type), 0, 0, (w), (h)))
#define crimp_newm(type,w,h,meta) (crimp_newm_at ((type), 0, 0, (w), (h), (meta)))

#define crimp_new_hsv(w,h)       (crimp_new (crimp_imagetype_find ("crimp::image::hsv"),     (w), (h)))
#define crimp_new_rgba(w,h)      (crimp_new (crimp_imagetype_find ("crimp::image::rgba"),    (w), (h)))
#define crimp_new_rgb(w,h)       (crimp_new (crimp_imagetype_find ("crimp::image::rgb"),     (w), (h)))
#define crimp_new_grey8(w,h)     (crimp_new (crimp_imagetype_find ("crimp::image::grey8"),   (w), (h)))
#define crimp_new_grey16(w,h)    (crimp_new (crimp_imagetype_find ("crimp::image::grey16"),  (w), (h)))
#define crimp_new_grey32(w,h)    (crimp_new (crimp_imagetype_find ("crimp::image::grey32"),  (w), (h)))
#define crimp_new_float(w,h)     (crimp_new (crimp_imagetype_find ("crimp::image::float"),   (w), (h)))
#define crimp_new_fpcomplex(w,h) (crimp_new (crimp_imagetype_find ("crimp::image::fpcomplex"), (w), (h)))

#define crimp_new_like(image)           (crimp_newm_at ((image)->itype, crimp_x(image), crimp_y(image), crimp_w(image), crimp_h(image), (image)->meta))
#define crimp_new_like_transpose(image) (crimp_newm_at ((image)->itype, crimp_x(image), crimp_y(image), crimp_h(image), crimp_w(image), (image)->meta))

#define crimp_new_hsv_at(x,y,w,h)       (crimp_new_at (crimp_imagetype_find ("crimp::image::hsv"),       (x), (y), (w), (h)))
#define crimp_new_rgba_at(x,y,w,h)      (crimp_new_at (crimp_imagetype_find ("crimp::image::rgba"),      (x), (y), (w), (h)))
#define crimp_new_rgb_at(x,y,w,h)       (crimp_new_at (crimp_imagetype_find ("crimp::image::rgb"),       (x), (y), (w), (h)))
#define crimp_new_grey8_at(x,y,w,h)     (crimp_new_at (crimp_imagetype_find ("crimp::image::grey8"),     (x), (y), (w), (h)))
#define crimp_new_grey16_at(x,y,w,h)    (crimp_new_at (crimp_imagetype_find ("crimp::image::grey16"),    (x), (y), (w), (h)))
#define crimp_new_grey32_at(x,y,w,h)    (crimp_new_at (crimp_imagetype_find ("crimp::image::grey32"),    (x), (y), (w), (h)))
#define crimp_new_float_at(x,y,w,h)     (crimp_new_at (crimp_imagetype_find ("crimp::image::float"),     (x), (y), (w), (h)))
#define crimp_new_fpcomplex_at(x,y,w,h) (crimp_new_at (crimp_imagetype_find ("crimp::image::fpcomplex"), (x), (y), (w), (h)))

/*
 * Convenience macros for input image handling.
 */

#define crimp_input(objvar,imagevar,itype) \
    if (crimp_get_image_from_obj (interp, (objvar), &(imagevar)) != TCL_OK) { \
	return TCL_ERROR; \
    } \
    CRIMP_ASSERT_IMGTYPE (imagevar, itype)

#define crimp_input_any(objvar,imagevar) \
    if (crimp_get_image_from_obj (interp, (objvar), &(imagevar)) != TCL_OK) { \
	return TCL_ERROR; \
    }

#define crimp_eq_geo(imagea,imageb) \
    (crimp_eq_dim(imagea,imageb) && crimp_eq_loc(imagea,imageb))

#define crimp_eq_dim(imagea,imageb) \
    (crimp_eq_width(imagea,imageb) && crimp_eq_height(imagea,imageb))

#define crimp_eq_loc(imagea,imageb) \
    (crimp_eq_x(imagea,imageb) && crimp_eq_y(imagea,imageb))

#define crimp_eq_x(imagea,imageb) \
    (crimp_x(imagea) == crimp_x(imageb))

#define crimp_eq_y(imagea,imageb) \
    (crimp_y(imagea) == crimp_y(imageb))

#define crimp_eq_height(imagea,imageb) \
    (crimp_h(imagea) == crimp_h(imageb))

#define crimp_eq_width(imagea,imageb) \
    (crimp_w(imagea) == crimp_w(imageb))

#define crimp_require_dim(image,rw,rh)					\
    ((crimp_w(image) == (rw)) && (crimp_h(image) == (rh)))

#define crimp_require_height(image,rh)					\
    (crimp_h(image) == (rh))

#define crimp_require_width(image,rw)					\
    (crimp_w(image) == (rw))


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_IMAGE_H */
