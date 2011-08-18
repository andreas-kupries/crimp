#ifndef CRIMP_io_bmp_H
#define CRIMP_io_bmp_H

/*
 * CRIMP :: BMP helper dclarations. INTERNAL. Do not export.
 * Copyright (c) 1997-2003 Jan Nijtmans    <nijtmans@users.sourceforge.net>
 * Copyright (c) 2002      Andreas Kupries <andreas_kupries@users.sourceforge.net>
 */

#include <crimp_core/crimp_coreDecls.h>

/* Structure for reading bit masks for compression type BI_BITFIELDS */
typedef struct {
  unsigned int mask;
  unsigned int shiftin;
  unsigned int shiftout;
} BitmapChannel;

/*
 * Compression types
 */
typedef enum {
    bc_rgb,      /* Uncompressed pixels */
    bc_rle8,     /* RLE-encoding for 8 bits/pixel */
    bc_rle4,     /* RLE-encoding for 4 bits/pixel */
    bc_bitfield, /* Packed RGB (or 1d huffman) */
    bc_jpeg,     /* Embedded JPEG, or RLE-24 -- NOT SUPPORTED */
    bc_png,      /* Embedded PNG             -- NOT SUPPORTED */
    bc_alphabit  /* Bitfields with alpha     -- NOT SUPPORTED */
} bmp_compression;

/*
 * bmp decoder information.
 */

typdef struct bmp_info {
    unsigned int    w;             /* Image width */
    unsigned int    h;             /* Image height */
    unsigned char*  colorMap;      /* Palette, NULL if not used */
    unsigned int    numColors;     /* #colors in the palette */
    unsigned int    numBits;       /* bits/pixel */
    bmp_compression mode;          /* Pixel compression method, s.a. */
    int             topdown;       /* Direction of scan-line storage */
    unsigned int    numPixelBytes; /* #bytes of pixel data */
    crimp_buffer*   input;         /* buffer holding the BMP */
} bmp_info;

/*
 * Main functions.
 */

extern int
bmp_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 bmp_info*       info);

extern int
bmp_read_pixels (bmp_info*      info,
		 crimp_image*   destination);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_io_bmp_H */
