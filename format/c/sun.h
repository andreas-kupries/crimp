#ifndef CRIMP_io_sun_H
#define CRIMP_io_sun_H

/*
 * CRIMP :: SUN helper dclarations. INTERNAL. Do not export.
 */

#include <crimp_core/crimp_coreDecls.h>

/*
 * sun decoder information.
 */

typedef enum {
    sun_raster_old      = 0, /* Old == Standard --> uncompressed pixel */
    sun_raster_standard = 1, /* information, color mapped */
    sun_raster_rle      = 2, /* RLE compressed pixel information */
    sun_raster_rgb      = 3  /* 24bit RGB information */
} sun_raster_type;

typedef enum {
    sun_colormap_none = 0, /* No color map present ==> length == 0 */
    sun_colormap_rgb  = 1, /* Plane-separated maps, i.e. 3 maps for
			   * R, G, and B, one after each other.
			   */
    sun_colormap_raw  = 2  /* Any colormap not defined by the sun raster
			   * specification. Nothing is known about the format.
			   */
} sun_colormap_type;

typedef struct sun_info {
    unsigned int      w;             /* Image width */
    unsigned int      h;             /* Image height */
    unsigned int      numBits;       /* bits/pixel (1, 8, 24, 32) */
    unsigned int      numPixelBytes; /* #bytes of pixel data */
    sun_raster_type   type;          /* Type of raster */
    sun_colormap_type mapType;       /* Type of palette, if any */
    unsigned char*    colorMap;      /* Palette, if any */
    unsigned int      numColors;     /* #colors in the palette, if any */
    crimp_buffer*     input;         /* buffer holding the image */
} sun_info;

/*
 * Main functions.
 */

extern int
sun_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 sun_info*       info);

extern int
sun_read_pixels (sun_info*      info,
		 crimp_image**  destination);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_io_sun_H */
