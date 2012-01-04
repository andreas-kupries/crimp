#ifndef CRIMP_io_sgi_H
#define CRIMP_io_sgi_H

/*
 * CRIMP :: SGI helper dclarations. INTERNAL. Do not export.
 *
 * References
 *     ftp://ftp.sgi.com/graphics/SGIIMAGESPEC
 *     http://en.wikipedia.org/wiki/Silicon_Graphics_Image
 */

#include <crimp_core/crimp_coreDecls.h>

/*
 * sgi decoder information.
 *
 * All multi-byte values (short, long) are stored in bigendian order.
 * General file structure is
 * - Header
 * - Offset tables (optional).
 * - Pixel data
 *
 * In case of multi-channel images all information about the channels
 * is stored separately, not interleaved. This affects both offset
 * tables and the pixel data.
 *
 * The offset tables are present only for RLE encoded images.  They
 * cannot be ignored as they allow additional compression,
 * i.e. identical rows of pixels sharing the compressed data,
 * including sharing between channels.
 *
 * == Header 512 bytes ==
 *
 *   0..  1 |   2 : Magic (Decimal 474, Hex 0x01da)
 *   2..  2 |   1 : Storage format --> sgi_storage_type
 *   3..  3 |   1 : Bytes per pixel per channel (in [1-2]).
 *   4..  5 |   2 : Number of dimensions (in [1-3]).
 *   6..  7 |   2 : Width  (always)
 *   8..  9 |   2 : Height (for #dimensions >= 2)
 *  10.. 11 |   2 : Depth  (for #dimensions == 3), in [1,3,4] (BW,RGB,RGBA)
 *  12.. 15 |   4 : Min pixel value
 *  16.. 19 |   4 : Max pixel value
 *  20.. 23 |   4 : Reserved1
 *  24..103 |  80 : Image name (C string)
 * 104..107 |   4 : Colormap id --> sgi_colormap_type
 * 108..511 | 404 : Reserved, to fill to 512.
 *
 * == Offset tables ==
 *
 * - Are present if and only if pixels are stored RLE compressed.
 * - We have 2 * 'depth' (#channels) tables. Per channel a table of
 *   start offsets, and a table of lengths.
 * - Each table has 'height' entries, i.e. one per scan-line.
 * - Scan lines may share pixel data, i.e. point to the same block
 *   of RLE data.
 * - Tables are stored in the following order:
 *   - Start Offset Tables
 *   - Length Tables
 * - Within each group of tables above data for the 1st channel
 *   is saved first, followed by the other channels in order.
 * - The offsets are relative to the beginning of the file, i.e. absolute
 *   in the file.
 *
 * == Pixel data ==
 *
 * - When stored direct the data of the first channel is provided first,
 *   followed by the others, in order.
 * - The size of each pixel is determined by Bytes/Pixel/Channel.
 * - When stored RLE the data is stored by scan line using the compression
 *   method below.
 *
 * == RLE compression ==
 *
 * - Depending on bytes/pixel/channel the elements below are treated as either
 *   chars, or shorts.
 * - We have x types of packets:
 * - A: 1nnnnnnn <n elements> -- Literal run, copy the elements as is.
 *   B: 0nnnnnnn <value>      -- Repeat vaue <n> times.
 *   C: x0000000              -- End of scanline/data
 *
 * Note that even when elements are shorts the flag and count information for
 * the various packet types is still in the low-order byte of the value.
 *
 * == Line ordering ==
 *
 * SGI puts the coordinate origin into the lower left corner. This means that
 * the first scanline is the bottom row of the image. IOW the scan lines are
 * stored from bottom to top.
 */

typedef enum {
    sgi_storage_verbatim = 0, /* Direct pixel data */
    sgi_storage_rle      = 1  /* RLE compressed pixel data */
} sgi_storage_type;

typedef enum {
    sgi_colormap_normal   = 0, /* Direct pixel data, no color map */
    sgi_colormap_dithered = 1, /* BGR bit-packed 2:3:3, obsolete */
    sgi_colormap_screen   = 2, /* Color-indexed. [1], obsolete */
    sgi_colormap_map      = 3  /* Color map - Image is color map,
				* not display-able */ 
} sgi_colormap_type;

/* (Ad 1 above): Unclear where to get the color map from. While there are
 * images which are colormaps it is unclear how an image determines which
 * color map to use. Decision: Format not supported.
 */

typedef struct sgi_info {
    unsigned int      w;             /* Image width */
    unsigned int      h;             /* Image height */
    unsigned int      d;             /* Image depth */
    unsigned int      bpp;           /* #Bytes/Pixel/Channel [1..2] */
    unsigned int      min;           /* Min and max pixel values */
    unsigned int      max;           /* s.a. */
    sgi_storage_type  storage;       /* Type of raster storage */
    sgi_colormap_type mapType;       /* Colormap information */
    unsigned long*    ostart;        /* Pointer to scan line offsets (RLE only) */
    unsigned long*    olength;       /* Pointer to scan line lengths (ditto) */
    crimp_buffer*     input;         /* buffer holding the image */
} sgi_info;

/*
 * Main functions.
 */

extern int
sgi_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 sgi_info*       info);

extern int
sgi_read_pixels (sgi_info*      info,
		 crimp_image**  destination);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_io_sgi_H */
