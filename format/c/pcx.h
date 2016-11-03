#ifndef CRIMP_io_pcx_H
#define CRIMP_io_pcx_H

/*
 * CRIMP :: PCX helper dclarations. INTERNAL. Do not export.
 */

#include <crimp_core/crimp_coreDecls.h>

/*
 * pcx decoder information.
 */

typedef struct pcx_info {
    unsigned int    x;
    unsigned int    y;
    unsigned int    w;             /* Image width */
    unsigned int    h;             /* Image height */
    unsigned char*  colorMap;      /* Palette */
    unsigned int    numColors;     /* #colors in the palette */
    unsigned int    numBits;       /* bits/pixel/plane */
    unsigned int    numPlanes;     /* number of planes */
    unsigned int    paletteType;   /* palette color/mono/grey */
    unsigned int    bytesLine;     /* Space needed to decode single scanline */
    crimp_buffer*   input;         /* buffer holding the PCX */
} pcx_info;

/*
 * Main functions.
 */

extern int
pcx_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 pcx_info*       info);

extern int
pcx_read_pixels (pcx_info*      info,
		 crimp_image**  destination);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_io_pcx_H */
