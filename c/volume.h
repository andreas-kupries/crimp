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
 *
 * - The geometry (bounding box) of a volume.
 * - The volume itself.
 */

typedef struct crimp_geometry3d {
    int x; /* Location of the volume in the infinite 3D volume */
    int y; /* s.a. */
    int z; /* s.a. */
    int w; /* Volume dimension, width  */
    int h; /* Volume dimension, height */
    int d; /* Volume dimension, depth */
} crimp_geometry3d;

typedef struct crimp_volume {
    Tcl_Obj*               meta;     /* Tcl level client data */
    const crimp_imagetype* itype;    /* Reference to type descriptor */
    crimp_geometry3d       geo;      /* Volume geometry, bounding box */
    unsigned char          voxel[4]; /* Integrated voxel storage */
} crimp_volume;

/*
 * Voxel Access Macros.
 */

#define CRIMP_VINDEX(iptr,x,y,z) \
    (((x)*SZ (iptr)) + \
     ((y)*SZ (iptr)*((iptr)->geo.w)) + \
     ((z)*SZ (iptr)*((iptr)->geo.w)*((size_t) (iptr)->geo.h)))

#define VFLOATP(iptr,x,y,z) *((float*) &((iptr)->voxel [CRIMP_VINDEX (iptr,x,y,z)]))

/*
 * Convenience macros for the creation of volumes with predefined image types.
 */

#define crimp_vnew_atg(type,g)       (crimp_vnew_at  ((type), (g).x, (g).y, (g).z, (g).w, (g).h, (g).d))
#define crimp_vnew(type,w,h,d)       (crimp_vnew_at  ((type), 0, 0, 0, (w), (h), (d)))
#define crimp_vnewm(type,w,h,d,meta) (crimp_vnewm_at ((type), 0, 0, 0, (w), (h), (d), (meta)))

#define crimp_vnew_hsv(w,h,d)       (crimp_vnew (crimp_imagetype_find ("crimp::image::hsv"),     (w), (h), (d)))
#define crimp_vnew_rgba(w,h,d)      (crimp_vnew (crimp_imagetype_find ("crimp::image::rgba"),    (w), (h), (d)))
#define crimp_vnew_rgb(w,h,d)       (crimp_vnew (crimp_imagetype_find ("crimp::image::rgb"),     (w), (h), (d)))
#define crimp_vnew_grey8(w,h,d)     (crimp_vnew (crimp_imagetype_find ("crimp::image::grey8"),   (w), (h), (d)))
#define crimp_vnew_grey16(w,h,d)    (crimp_vnew (crimp_imagetype_find ("crimp::image::grey16"),  (w), (h), (d)))
#define crimp_vnew_grey32(w,h,d)    (crimp_vnew (crimp_imagetype_find ("crimp::image::grey32"),  (w), (h), (d)))
#define crimp_vnew_float(w,h,d)     (crimp_vnew (crimp_imagetype_find ("crimp::image::float"),   (w), (h), (d)))
#define crimp_vnew_fpcomplex(w,h,d) (crimp_vnew (crimp_imagetype_find ("crimp::image::fpcomplex"), (w), (h), (d)))

#define crimp_vnew_like(volume)           (crimp_vnewm ((volume)->itype, (volume)->geo.w, (volume)->geo.h, (volume)->geo.d, (volume)->meta))
#define crimp_vnew_like_transpose(volume) (crimp_vnewm ((volume)->itype, (volume)->geo.h, (volume)->geo.w, (volume)->geo.d, (volume)->meta))

/*
 * Volume calculations macros.
 */

#define CRIMP_RECT_VOLUME(w,h,d) (((size_t) (w)) * (h) * (d))
#define crimp_volume_vol(vptr) (CRIMP_RECT_VOLUME ((vptr)->geo.w, (vptr)->geo.h, (vptr)->geo.d))

#define crimp_vplace(image,ix,iy,iz)			\
    ((image)->geo.x = (ix), (image)->geo.y = (iy), (image)->geo.z = (iz))

#define crimp_vinside(volume,px,py,pz)					\
    (((volume)->geo.x <= (px)) && ((px) < ((volume)->geo.x + (volume)->geo.w)) && \
     ((volume)->geo.y <= (py)) && ((py) < ((volume)->geo.y + (volume)->geo.h)) && \
     ((volume)->geo.z <= (pz)) && ((pz) < ((volume)->geo.z + (volume)->geo.d)))

#define crimp_vx(volume) ((volume)->geo.x)
#define crimp_vy(volume) ((volume)->geo.y)
#define crimp_vz(volume) ((volume)->geo.z)
#define crimp_vw(volume) ((volume)->geo.w)
#define crimp_vh(volume) ((volume)->geo.h)
#define crimp_vd(volume) ((volume)->geo.d)

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
