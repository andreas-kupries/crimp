/*
 * CRIMP :: BMP functions Definitions (Implementation).
 * See http://en.wikipedia.org/wiki/BMP_file_format
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include "bmp.h"

static void decode_2   (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static void decode_4   (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static void decode_16  (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static void decode_256 (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static void decode_rgb (bmp_info* info, crimp_buffer* buf, crimp_image* destination);

static void map_color (unsigned char* colorMap, int index, unsigned char* pix);

/*
 * Definitions :: Core.
 */

int
bmp_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 bmp_info*       info)
{
    unsigned int   fsize, pixOffset, c, w;
    unsigned int   nBits, compression, nPix, nColors;
    int            h;
    int            topdown = 0; /* bottom-up storage, default */
    unsigned char* palette = 0;

    /*
     * Reference
     *	http://en.wikipedia.org/wiki/BMP_file_format
     *
     * BITMAPFILEHEADER, 14 bytes
     *  0.. 1 | 2 : magic "BM" (ascii).
     *  2.. 5 | 4 : size of file in bytes
     *  6.. 7 | 2 : reserved (creator-id 1)
     *  8.. 9 | 2 : reserved (creator-id 2)
     * 10..13 | 4 : offset to pixel data, relative to start of file.
     */

    if (!crimp_buf_has   (buf, 14) ||
	!crimp_buf_match (buf, 2, "BM")) {
	Tcl_SetResult(interp, "Not a BMP image", TCL_STATIC);
	return 0;
    }

    crimp_buf_read_uint32le (buf, &fsize);             /* BMP file size */
    crimp_buf_skip          (buf, 4);                  /* reserved */
    crimp_buf_read_uint32le (buf, &pixOffset);         /* offset to pixel data */

    /*
     * Check the internal consistency of the data retrieved so far
     */

    if ((crimp_buf_size (buf) != fsize) ||
	(pixOffset % 4 != 0) ||
	!crimp_buf_check (buf, pixOffset)) {
	Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
	return 0;
    }

    /*
     * BITMAPINFOHEADER, aka DIB Header
     * Note: Multiple variants, distinguishable by size found in first field,
     * common to all variants.
     *
     * 14..17 | 4 : DIB header size, common to all variants.
     */

    if (!crimp_buf_has (buf, 4)) {         /* Space for DIB Header size */
	Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
	return 0;
    }
    crimp_buf_read_uint32le (buf, &c);     /* DIB header size */
    if (!crimp_buf_has      (buf, c-4)) {  /* Space for remaining DIB Header */
	Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
	return 0;
    }

    switch (c) {
    case 40:
	/*
	 * BITMAPINFOHEADER, aka DIB Header
	 * Most common 40-byte variant.
	 *
	 * 18..21 | 4 : Image width
	 * 22..25 | 4 : Image height
	 * 26..27 | 2 : Num Planes
	 * 28..29 | 2 : BitCount
	 * 30..33 | 4 : Compression
	 * 34..37 | 4 : SizePixelData
	 * 38..41 | 4 : XPixels/Meter
	 * 42..45 | 4 : YPixels/Meter
	 * 46..49 | 4 : NumColors
	 * 50..53 | 4 : NumImportantColors
	 */

	crimp_buf_read_uint32le (buf, &w);           /* width */
	crimp_buf_read_int32le  (buf, &h);           /* height */
	crimp_buf_skip          (buf, 2);            /* IGNORE planes */
	crimp_buf_read_uint16le (buf, &nBits);       /* bit count */
	crimp_buf_read_uint32le (buf, &compression); /* compression */
	crimp_buf_read_uint32le (buf, &nPix);        /* pixel data size */
	crimp_buf_skip          (buf, 8);            /* IGNORE pixels/meter */
	crimp_buf_read_uint32le (buf, &nColors);     /* num colors */
	crimp_buf_skip          (buf, 4);            /* IGNORE important colors */

	/*
	 * - BitCount
	 *   1 : 2 Colors.   Bit unset => Color 0, Bit set => color 1.
	 *   2 : 4 Colors.   Compressible
	 *   4 : 8 Colors.   Compressible.
	 *   8 : 256 Colors.
	 *  24 : RGB storage, no color table.
	 *  -- - ----------------------------------------------
	 *  16 : Packed RGB storage, no color table, have channel bitmasks
	 *  32 : instead.
	 *  -- - ----------------------------------------------
	 *
	 * - NumColors != 0 overrides the default number of colors derived
	 *   from the BitCount.
	 */

	switch (nBits) {
	case 1:
	case 2:
	case 4:
	case 8:
	    /*
	     * Paletted pixel formats.
	     */
	    if (!nColors) {
		nColors = 1 << nBits;
	    } else if (nColors > (1 << nBits)) {
		Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
		return 0;
	    }

	    colorMap = crimp_buf_at (buf);
	    break;
	case 16:
	case 32:
	    /*
	     * Packed RGB formats, currently not supported. TODO.
	     */
	    Tcl_SetResult(interp, "Packed RGB BMP image not supported", TCL_STATIC);
	    return 0;
	case 24:
	    /*
	     * RGB formats.
	     */
	    if (nColors) {
		Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
		return 0;
	    }
	    break;
	default:
	    return 0;
	}

	/*
	 * For the pixel-packed formats (bit count < 8) the pixels from left
	 * to right are stored in the MSB bits down.
	 *
	 * - Compression
	 *   0 RGB  : Uncompressed.
	 *   1 RLE4 : Run-length encoded pixel data. Restricted to bit count 4.
	 *   2 RLE8 : As above, restricted to bit count 8.
	 *   3 BITF : Bitfields, for packed RGB formats.
	 *
	 * - SizePixelData
	 *   Set when pixel data is compressed.
	 *   Can be left 0 for uncompressed pixel data, in that case the
	 *   information is derived from width/height/bitcount.
	 */

	if (compression) {
	    if (compression > bc_bitfield) {
		Tcl_SetResult(interp, "Unsupported BMP image compression method", TCL_STATIC);
		return 0;
	    }
	    if (((compression != bc_rel4)     && (nBits == 4)) ||
		((compression != bc_rle8)     && (nBits == 8)) ||
		((compression != bc_bitfield) && ((nBits == 16) || (nBits == 32)))) {
		Tcl_SetResult(interp, "Bad BMP image, bits/compression mismatch", TCL_STATIC);
		return 0;
	    }
	}
	if (!nPix) {
	    if ((compression == bc_rle4) ||
		(compression == bc_rle8)) {
		Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
		return 0;
	    }

	    /*
	     * nPix = height * bytes/line.
	     * where
	     *     bytes/line = (width * 8/nBits), 4-aligned, nBits <= 8.
	     * or
	     *     bytes/line = width * (nBits/8), 4-aligned, nBits > 8.
	     */

#error TODO ...

	}

	/*
	 * Pixel data is normally stored bottom up, i.e. bottom line first. A
	 * negative image height (<0) indicates that the lines are stored
	 * top-down instead.
	 */

	if (h < 0) {
	    h   = -h;
	    top = 1;
	}

	break;

    default:
	Tcl_SetResult(interp, "Unsupported BMP DIB image header", TCL_STATIC);
	return 0;
    }

    /*
     * Jump to the pixel data for the decoder.
     */

    crimp_buf_moveto (buf, pixOffset);
    if (!crimp_buf_has (buf, nPix)) {
	Tcl_SetResult(interp, "Bad BMP image", TCL_STATIC);
	return TCL_ERROR;
    }

    /*
     * Save results for caller.
     */

    info->w             = w;
    info->h             = h;
    info->colorMap      = colorMap;
    info->numBits       = nBits;
    info->numColors     = nColors;
    info->mode          = compression;
    info->topdown       = topdown;
    info->numPixelBytes = nPix;
    info->input         = buf;

    return 1;
}


void
bmp_read_pixels (bmp_info*      info,
		 crimp_image*   destination)
{
    crimp_buffer* buf = info->buf;

    CRIMP_ASSERT_IMGTYPE (destination, rgb);
    CRIMP_ASSERT ((info->w == destination->w) &&
		  (info->h == destination->h), "Dimension mismatch");

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     * - nBits and compression mode match.
     *
     * 'bmp_read_header', see above, ensures these conditions.
     */

    switch (info->numBits) {
    case 1:
	CRIMP_ASSERT (info->colorMap,       "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 2, "Too many colors");

	decode_2 (info, buf, destination);
	break;
    case 2:
	CRIMP_ASSERT (info->colorMap,       "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 4, "Too many colors");

	decode_4 (info, buf, destination);
	break;
    case 4:
	CRIMP_ASSERT (info->colorMap,        "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 16, "Too many colors");

	decode_16 (info, buf, destination);
	break;
    case 8:
	CRIMP_ASSERT (info->colorMap,         "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 256, "Too many colors");

	decode_256 (info, buf, destination);
	break;
    case 24:
	CRIMP_ASSERT (!info->colorMap,"");

	decode_rgb (info, buf, destination);
	break;
    default:
	CRIMP_ASSERT (0,"Unsupported number of bits/pixel");
    }
}

static void
decode_2   (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
}

static void
decode_4   (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
}

static void
decode_16  (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
}

static void
decode_256 (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
}

static void
decode_rgb (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
}

static void
map_color (unsigned char* colorMap, int index, unsigned char* pix)
{
    /*
     * Note how:
     * - Each colorMap entry is 4 bytes, with one byte ignored.
     * - The pixel uses RGB order for the bytes, whereas the colorMap uses BGR
     *   (inverted).
     */

    index <<= 2; /* times 4 */

    pix [0] = colorMap [index + 2]; /* Red */
    pix [1] = colorMap [index + 1]; /* Green */
    pix [2] = colorMap [index + 0]; /* Blue *
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
