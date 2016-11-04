#ifndef CRIMP_IMAGE_TYPE_H
#define CRIMP_IMAGE_TYPE_H
/*
 * CRIMP :: Image Type Declarations, and API :: PUBLIC
 * (C) 2010 - 2011
 */

#include <tcl.h>

/*
 * Structure describing crimp image types. They are identified by name. Stored
 * information is the size of a pixel in bytes for all images of that type,
 * plus the number and names of channels a pixel is split into. The number of
 * bytes per pixel has to be an integral multiple of the number of channels
 * per pixel.
 */

typedef struct crimp_imagetype {
    const char*  name;     /* Image type code     */
    int          size;     /* Pixel size in bytes */
    int          channels; /* Number of 'color' channels */
    const char** cname;  /* Names of the color channels */
} crimp_imagetype;


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_IMAGE_TYPE_H */
