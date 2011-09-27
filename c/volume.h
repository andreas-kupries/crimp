#ifndef CRIMP_VOLUME_H
#define CRIMP_VOLUME_H
/*
 * CRIMP :: Volume Declarations, and API :: PUBLIC
 * (C) 2010 - 2011
 */

#include "common.h"
#include "image_type.h"

/*
 * Structures describing volumes.
 */

typedef struct crimp_volume {
    Tcl_Obj*               meta;     /* Tcl level client data */
    const crimp_imagetype* itype;    /* Reference to type descriptor */
    int                    w;        /* Volume dimension, width  */
    int                    h;        /* Volume dimension, height */
    int                    d;        /* Volume dimension, depth */
    unsigned char          voxel[4]; /* Integrated voxel storage */
} crimp_volume;

/*
 * Voxel Access Macros.
 */

#define CRIMP_VINDEX(iptr,x,y,z) \
    (((x)*SZ (iptr)) + \
     ((y)*SZ (iptr)*((iptr)->w)) + \
     ((z)*SZ (iptr)*((iptr)->w)*((size_t) (iptr)->h)))

#define VFLOATP(iptr,x,y,z) *((float*) &((iptr)->voxel [CRIMP_VINDEX (iptr,x,y,z)]))

/*
 * Convenience macros for the creation of volumes with predefined image types.
 */

#define crimp_vnew_hsv(w,h,d)       (crimp_vnew (crimp_imagetype_find ("crimp::image::hsv"),     (w), (h), (d)))
#define crimp_vnew_rgba(w,h,d)      (crimp_vnew (crimp_imagetype_find ("crimp::image::rgba"),    (w), (h), (d)))
#define crimp_vnew_rgb(w,h,d)       (crimp_vnew (crimp_imagetype_find ("crimp::image::rgb"),     (w), (h), (d)))
#define crimp_vnew_grey8(w,h,d)     (crimp_vnew (crimp_imagetype_find ("crimp::image::grey8"),   (w), (h), (d)))
#define crimp_vnew_grey16(w,h,d)    (crimp_vnew (crimp_imagetype_find ("crimp::image::grey16"),  (w), (h), (d)))
#define crimp_vnew_grey32(w,h,d)    (crimp_vnew (crimp_imagetype_find ("crimp::image::grey32"),  (w), (h), (d)))
#define crimp_vnew_float(w,h,d)     (crimp_vnew (crimp_imagetype_find ("crimp::image::float"),   (w), (h), (d)))
#define crimp_vnew_fpcomplex(w,h,d) (crimp_vnew (crimp_imagetype_find ("crimp::image::fpcomplex"), (w), (h), (d)))

#define crimp_vnew_like(volume)           (crimp_vnewm ((volume)->itype, (volume)->w, (volume)->h, (volume)->d, (volume)->meta))
#define crimp_vnew_like_transpose(volume) (crimp_vnewm ((volume)->itype, (volume)->h, (volume)->w, (volume)->d, (volume)->meta))

/*
 * Volume calculations macros.
 */

#define CRIMP_RECT_VOLUME(w,h,d) (((size_t) (w)) * (h) * (d))
#define crimp_volume_vol(vptr) (CRIMP_RECT_VOLUME ((vptr)->w, (vptr)->h, (vptr)->d))

/*
 * Convenience macros for input volume handling.
 */

#define crimp_vinput(objvar,volumevar,itype) \
    if (crimp_get_volume_from_obj (interp, (objvar), &(volumevar)) != TCL_OK) { \
	return TCL_ERROR; \
    } \
    CRIMP_ASSERT_IMGTYPE (volumevar, itype)

#define crimp_vinput_any(objvar,volumevar) \
    if (crimp_get_volume_from_obj (interp, (objvar), &(volumevar)) != TCL_OK) { \
	return TCL_ERROR; \
    }


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_VOLUME_H */
