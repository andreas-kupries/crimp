#ifndef CRIMP_VOLUME_H
#define CRIMP_VOLUME_H
/*
 * CRIMP :: Volume Declarations, and API.
 * (C) 2010.
 */

#include <image_type.h>
#include <util.h>

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

#define VINDEX(iptr,x,y,z) \
    (((x)*SZ (iptr)) + \
     ((y)*SZ (iptr)*((iptr)->w)) + \
     ((z)*SZ (iptr)*((iptr)->w)*((iptr)->h)))

#define VFLOATP(iptr,x,y,z) *((float*) &((iptr)->voxel [VINDEX (iptr,x,y,z)]))

/*
 * API :: Core. Volume lifecycle management.
 */

extern crimp_volume* crimp_vnew  (const crimp_imagetype* type, int w, int h, int d);
extern crimp_volume* crimp_vnewm (const crimp_imagetype* type, int w, int h, int d, Tcl_Obj* meta);
extern crimp_volume* crimp_vdup  (crimp_volume* volume);
extern void          crimp_vdel  (crimp_volume* volume);

#define crimp_vnew_hsv(w,h,d)    (crimp_vnew (crimp_imagetype_find ("crimp::image::hsv"),    (w), (h), (d)))
#define crimp_vnew_rgba(w,h,d)   (crimp_vnew (crimp_imagetype_find ("crimp::image::rgba"),   (w), (h), (d)))
#define crimp_vnew_rgb(w,h,d)    (crimp_vnew (crimp_imagetype_find ("crimp::image::rgb"),    (w), (h), (d)))
#define crimp_vnew_grey8(w,h,d)  (crimp_vnew (crimp_imagetype_find ("crimp::image::grey8"),  (w), (h), (d)))
#define crimp_vnew_grey16(w,h,d) (crimp_vnew (crimp_imagetype_find ("crimp::image::grey16"), (w), (h), (d)))
#define crimp_vnew_grey32(w,h,d) (crimp_vnew (crimp_imagetype_find ("crimp::image::grey32"), (w), (h), (d)))
#define crimp_vnew_float(w,h,d)  (crimp_vnew (crimp_imagetype_find ("crimp::image::float"),  (w), (h), (d)))

#define crimp_vnew_like(volume)           (crimp_vnewm ((volume)->itype, (volume)->w, (volume)->h, (volume)->d, (volume)->meta))
#define crimp_vnew_like_transpose(volume) (crimp_vnewm ((volume)->itype, (volume)->h, (volume)->w, (volume)->d, (volume)->meta))


/*
 * API :: Tcl. Manage Tcl_Obj's of volumes.
 */

extern Tcl_Obj* crimp_new_volume_obj      (crimp_volume*  volume);
extern int      crimp_get_volume_from_obj (Tcl_Interp*    interp,
					   Tcl_Obj*       volumeObj,
					   crimp_volume** volume);

#define crimp_vinput(objvar,volumevar,itype) \
    if (crimp_get_volume_from_obj (interp, (objvar), &(volumevar)) != TCL_OK) { \
	return TCL_ERROR; \
    } \
    ASSERT_IMGTYPE (volumevar, itype)

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
