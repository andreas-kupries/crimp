#ifndef CRIMP_IMAGE_TYPE_H
#define CRIMP_IMAGE_TYPE_H
/*
 * CRIMP :: Image Type Declarations, and API.
 * (C) 2010.
 */

#include <tcl.h>

/*
 * Structures describing crimp image types. They are identified by
 * name. Stored information is the size of a pixel in bytes for all
 * images of that type.
 */

typedef struct crimp_imagetype {
    const char* name;   /* Image type code     */
    int         size;   /* Pixel size in bytes */
} crimp_imagetype;

/*
 * API :: Core. Manage a mapping of types to names.
 */

extern void                   crimp_imagetype_def  (const crimp_imagetype* imagetype);
extern const crimp_imagetype* crimp_imagetype_find (const char* name);

/*
 * API :: Tcl. Manage Tcl_Obj's references to crimp image types.
 */

extern Tcl_Obj* crimp_new_imagetype_obj      (const crimp_imagetype*  imagetype);
extern int      crimp_get_imagetype_from_obj (Tcl_Interp*       interp,
					      Tcl_Obj*          imagetypeObj,
					      crimp_imagetype** imagetype);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_IMAGE_TYPE_H */
