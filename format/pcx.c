/*
 * CRIMP :: PCX functions Definitions (Implementation).
 * Reference
 *	http://en.wikipedia.org/wiki/PCX
 *	
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include <string.h>
#include "pcx.h"

/*
 * Debugging Help. Mainly the RLE decoders.
 */

#define PCX_TRACE 1
#ifdef PCX_TRACE
#define TRACE(x) { printf x ; fflush (stdout); }
#else
#define TRACE(x)
#endif

static void
alloc_line (pcx_info* info, int n, int* bytes, unsigned char** scanline);

static int
decode_line (crimp_buffer* buf, int bytes, unsigned char* scanline);

static int
decode_rgb_vga (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_rgb_raw (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_grey8 (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_2c (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_4c (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_16c (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static void
map_color (unsigned char* colorMap, int index, unsigned char* pix);

/*
 * Definitions :: Core.
 */

int
pcx_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 pcx_info*       info)
{
    /*
     * Reference
     *	http://en.wikipedia.org/wiki/PCX
     *  http://fileformat.info/format/pcx
     *
     * WORD and LONG values are storred in little-endian order.
     *
     * HEADER 128 bytes
     *  0..  0 |  1 : magic: 10 (integer 0x0A, ascii "\n").
     *  1..  1 |  1 : [1] Version number (0,2-5)
     *  2..  2 |  1 : [2] Encoding format (always 1, RLE).
     *  3..  3 |  1 : [3] Bits Per Pixel Per Plane
     *  4..  5 |  2 : Xleft   | Geometry, WxH derived as | Geometry in pixels
     *  6..  7 |  2 : Ytop    | Xright - Xleft           | Extra data in scanlines, and
     *  8..  9 |  2 : Xright  | Ybottom - Ytop           | extra scanlines are possible
     * 10.. 11 |  2 : Ybottom |                          | and suppressed.
     * 12.. 13 |  2 : [4] Horizontal resolution
     * 14.. 15 |  2 : [4] Vertical resolution
     * 16.. 63 | 48 : [5] EGA palette
     * 64.. 64 |  1 : RESERVED (always 0)
     * 65.. 65 |  1 : [6] Number of Bit Planes --> Number of Channels
     * 66.. 67 |  2 : [7] Bytes Per Line
     * 68.. 69 |  2 : [8] Palette Type
     * 70.. 71 |  2 : Horizontal screen size | Ignore.
     * 72.. 73 |  2 : Vertical screen size   | Ignore.
     * 74..127 | 54 : RESERVED (always 0)
     *
     * [1]  0 :  PB 2.5, fixed EGA palette
     *      2 :  PB 2.8, modifiable EGA palette
     *      3 :  PB 2.8, no palette
     *      4 :  PB Windows
     *      5 :  PB 3.0, plus
     *
     * [2]  1 : RLE - Only legal value. See [10] for the pixel coding.
     *
     * [3]  1 :   2 colors. | EGA palette.    | Single plane images.
     *      2 :   4 -"-     | EGA palette.    |
     *      4 :  16 -"-     | EGA palette.    |
     *      8 : 256 -"-     | VGA Palette [9] |
     *      
     * [4]  Unit is Dots/Inch, DPI
     *
     * [5]  16  RGB color tuples at 3 byte/tuple.
     *
     * [6]  1 : Grey image, or palette color
     *      3 : RGB image
     *      4 : RGB image with EGA specific intensity channel.
     *
     * Max Number of Colors = 2 ** ('Bits/Pixel/Plane' * 'Number Of Bit Planes')
     *
     * [7] Bytes needed to store a single decoded scan line of a single plane.
     *     A full scan line (all planes) takes
     *
     *         Scan Line Length = 'Bytes/Lines' * 'Number Of Bit Planes'
     *
     * [8] 1 : color/monochrome palette
     *     2 : grey-scale (no palette)
     *
     * [9] Last 769 bytes of the file. Byte 0 is a marker/magic value, 0xC0h.
     *     Restricted to version 5 files, see [1].
     *     Further checks that the first triple is BLACK, i.e 3x 0x00
     *
     * [10] RLE.
     *      11xxxxxx => Start of an encoding run.
     *                  xxxxxx == length of the run, range 1...63
     *                  Next byte is pixel value, range 0..255
     *      00xxxxxx => Single-pixel run, xxxxxx == pixel value, range 0..63
     *
     *      Runs should not cross scan lines. There are images which
     *      ignore this rule however, to gain a few bytes of
     *      compression.
     *
     * After decompression a scanline can be in multiple formats:
     *
     * - pixel oriented : color index stream, or pixel value stream (RGB interleaved).
     * - plane oriented : adjacent, not interleaved planes.
     *
     * Number of planes, see [6], and Bits/Pixel [3] involved
     *
     * 1 / 1 : pixel oriented value stream, 8 pixels per byte.
     * 1 / * : pixel oriented color index stream.
     * 3 / 8 : plane oriented RGB pixel values
     * 3/  1 : plane oriented RGB color indices, EGA palette.
     * 4 / * : plane oriented RGB pixel values, with an additional EGA specific channel.
     *
     */

    unsigned int version, compression, numBitsPixelPlane, numPlanes, numBytesLine, reserved;
    unsigned int left, right, top, bottom, pType;
    unsigned char* colorMap = 0;

    if (!crimp_buf_has   (buf, 128) ||
	!crimp_buf_match (buf, 1, "\n")) {
	Tcl_SetResult (interp, "Not a PCX image", TCL_STATIC);
	return 0;
    }

    crimp_buf_read_uint8    (buf, &version);
    crimp_buf_read_uint8    (buf, &compression);
    crimp_buf_read_uint8    (buf, &numBitsPixelPlane);
    crimp_buf_read_uint16le (buf, &left);
    crimp_buf_read_uint16le (buf, &top);
    crimp_buf_read_uint16le (buf, &right);
    crimp_buf_read_uint16le (buf, &bottom);
    crimp_buf_skip          (buf, 4);  /* 2x2 h/v DPI. FUTURE: meta data */
    colorMap = crimp_buf_at (buf);     /* EGA palette. */
    crimp_buf_skip          (buf, 48); /* Jump EGA palette */
    crimp_buf_read_uint8    (buf, &reserved);
    crimp_buf_read_uint8    (buf, &numPlanes);
    crimp_buf_read_uint16le (buf, &numBytesLine);
    crimp_buf_read_uint16le (buf, &pType);
    crimp_buf_skip          (buf, 58); /* screen size (2x2) & reserved2 (54) */

    TRACE (("PCX (version):   %d\n", version));
    TRACE (("PCX (compress):  %d\n", compression));
    TRACE (("PCX (bits/pix):  %d\n", numBitsPixelPlane));
    TRACE (("PCX (geo):       %d,%d - %d,%d\n", left, top, right, bottom));
    TRACE (("PCX (planes):    %d\n", numPlanes));
    TRACE (("PCX (byte/line): %d\n", numBytesLine));
    TRACE (("PCX (EGA):       %p\n", colorMap));
    TRACE (("PCX (pal.-type): %d\n", pType));

    /*
     * Check the internal consistency of the data retrieved so far.
     * - Valid values of various fields, separately
     * - Field interaction.
     */

    if ((version != 0) &&
	(version != 2) &&
	(version != 3) &&
	(version != 4) &&
	(version != 5)) {
	Tcl_SetResult (interp, "Bad PCX image (bad version)", TCL_STATIC);
	return 0;
    }
    if (compression != 1) {
	Tcl_SetResult (interp, "Bad PCX image (bad encoding)", TCL_STATIC);
	return 0;
    }
    if ((numBitsPixelPlane != 1) &&
	(numBitsPixelPlane != 2) &&
	(numBitsPixelPlane != 4) &&
	(numBitsPixelPlane != 8)) {
	Tcl_SetResult (interp, "Bad PCX image (bad bits/pixel)", TCL_STATIC);
	return 0;
    }
    if ((numPlanes != 1) &&
	(numPlanes != 3) &&
	(numPlanes != 4)) {
	Tcl_SetResult (interp, "Bad PCX image (bad #planes)", TCL_STATIC);
	return 0;
    }

    if (((numBitsPixelPlane == 1) ||
	 (numBitsPixelPlane == 2) ||
	 (numBitsPixelPlane == 4)) &&
	(numPlanes != 1)) {

	/*
	 * When using less than 8 bits/pixel the image MUST have a single
	 * plane of pixel values, a stream of palette indices.
	 */

	Tcl_SetResult (interp, "Bad PCX image (bits/pixel #planes mismatch)", TCL_STATIC);
	return 0;
    }

    if ((numBytesLine % 2) == 1) {
	Tcl_SetResult (interp, "Bad PCX image (odd scanline length)", TCL_STATIC);
	return 0;
    }

    /*
     * Work out the (non-)presence of a VGA palette, for the image formats
     * where this is actually possible. For anything else we keep using the
     * EGA palette from the header.
     */
#if BOGUS
    if ((version == 5) &&
	(numPlanes == 1) &&
	(numBitsPixelPlane == 8) &&
	(crimp_buf_size (buf) > (128+769))) {
	int at = crimp_buf_tell (buf);

	TRACE (("PCX (VGA):       5/1/8/size --> possible\n"));

	crimp_buf_moveto (buf, crimp_buf_size (buf) - 769);

	/*
	 * Check for marker byte (0x0C == 0o14 == \f, and the color black
	 */
	if (crimp_buf_match (buf, 4, "\f\0\0\0")) {
	    colorMap = crimp_buf_at (buf) - 3;

	    TRACE (("PCX (VGA):       %p\n", colorMap));
	} else {
	    TRACE (("PCX (VGA):       not found\n"));
	}

	crimp_buf_moveto (buf, at);
    }
#endif
    /*
     * Save results for caller, including derivatives.
     */

    info->x             = left;
    info->y             = top;
    info->w             = right - left + 1;
    info->h             = bottom - top + 1;
    info->colorMap      = colorMap;
    info->numBits       = numBitsPixelPlane;
    info->numPlanes     = numPlanes;
    info->bytesLine     = numBytesLine;
    info->paletteType   = pType;
    info->input         = buf;

    TRACE (("PCX (WxH): %dx%d\n",info->w, info->h));

    return 1;
}

int
pcx_read_pixels (pcx_info*      info,
		 crimp_image**  destination)
{
    crimp_buffer* buf = info->input;
    crimp_image*  dst = NULL;
    int           result = 0;

#define CODE(bpp,planes) (((bpp)<<4)|(planes))

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     *
     * 'pcx_read_header', see above, ensures these conditions.
     */

    /*
     * Combinations
     * bpp = bits/pixel
     * #pl = #planes
     *
     * bpp | #pl | 
     * ----+-----+--------------------------
     *   1 |   1 | 2-color 1:255 0:0, no palette.
     *   8 |   1 | RGB data via end-saved VGA palette
     *   8 |   1 | Grey scale data
     *   8 |   3 | RGB data, separated by plane
     *   X |   X | unknown, fail.
     * ----+-----+--------------------------
     */

    switch CODE (info->numBits, info->numPlanes) {
    case CODE(8,1):
	if (info->paletteType == 1) {
	    TRACE (("PCX (8/1 RGB, 256 colors VGA palette)\n"));

	    dst    = crimp_new_rgb (info->w, info->h);
	    result = decode_rgb_vga (info, buf, dst);
	} else {
	    TRACE (("PCX (8/1 GREY8)\n"));

	    dst    = crimp_new_grey8 (info->w, info->h);
	    result = decode_grey8 (info, buf, dst);
	}
	break;

    case CODE(8,3):
	TRACE (("PCX (8/3 RGB direct, no palette)\n"));

	dst    = crimp_new_rgb (info->w, info->h);
	result = decode_rgb_raw (info, buf, dst);
	break;

    case CODE(4,1):
	TRACE (("PCX (4/1 16 color, EGA palette)\n"));

	dst    = crimp_new_grey8 (info->w, info->h);
	result = decode_16c (info, buf, dst);
	break;

    case CODE(2,1):
	TRACE (("PCX (2/1 4 color, EGA palette)\n"));

	dst    = crimp_new_grey8 (info->w, info->h);
	result = decode_4c (info, buf, dst);
	break;

    case CODE(1,1):
	TRACE (("PCX (1/1 BW direct, no palette)\n"));

	dst    = crimp_new_grey8 (info->w, info->h);
	result = decode_2c (info, buf, dst);
	break;

    default:
	TRACE (("PCX (%d/%d unknown)\n", info->numBits, info->numPlanes));
	break;
    }

    if (dst) {
	if (result) {
	    *destination = dst;
	} else {
	    crimp_del (dst);
	}
    } 
    return result;
#undef CODE
}

static int
decode_16c (pcx_info*      info,
	   crimp_buffer*  buf,
	   crimp_image*   destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* map;
    int x, y, ok = 1;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    map = info->colorMap;

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into a stream of palette
	 * indices and map them through the palette.
	 */

	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    int pix;
	    pix = (scanline [x/2] & (0xf0 >> (4*(x%2)))) >> (4*(x%2));
	    map_color (map, pix, &R(destination, x, y));
	    TRACE ((" %d", pix));
	    /*
	     * Consider unrolling the above, plus constants for the bitmasks.
	     * See similar code in the BMP reader.
	     */
	}
	TRACE (("\n"));
    }

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_4c (pcx_info*      info,
	   crimp_buffer*  buf,
	   crimp_image*   destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* map;
    int x, y, ok = 1;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    map = info->colorMap;

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into a stream of palette
	 * indices and map them through the palette.
	 */

	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    int pix;
	    pix = (scanline [x/4] & (0xf0 >> (2*(x%4)))) >> (2*(x%4));
	    map_color (map, pix, &R(destination, x, y));
	    TRACE ((" %d", pix));
	    /*
	     * Consider unrolling the above, plus constants for the bitmasks.
	     * See similar code in the BMP reader.
	     */
	}
	TRACE (("\n"));
    }

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_2c (pcx_info*      info,
	   crimp_buffer*  buf,
	   crimp_image*   destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* map;
    int x, y, ok = 1;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into grey8 pixels.
	 */

	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    int pix;
	    pix = scanline [x/8] & (128 >> (x%8))
		? WHITE
		: BLACK
		;
	    GREY8 (destination, x, y) = pix;
	    TRACE (("%c", pix? '_':'*'));
	    /*
	     * Consider unrolling the above, plus constants for the bitmasks.
	     * See similar code in the BMP reader.
	     */
	}
	TRACE (("\n"));
    }

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_grey8 (pcx_info*      info,
	      crimp_buffer*  buf,
	      crimp_image*   destination)
{
    int            scanbytes;
    unsigned char* scanline;
    int x, y, ok = 1;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	memcpy (&GREY8 (destination, 0, y), scanline, info->w);
    }

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_rgb_vga (pcx_info*      info,
		crimp_buffer*  buf,
		crimp_image*   destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* indices;
    unsigned char* map;
    int x, y, ok = 1;

    /*
     * Allocate a buffer for all scanlines. In this mode we read the whole
     * stream of palette indices first, and then we get the VGA palette and
     * convert everything to the final result. The scanbytes we get back is
     * however always the size of a single scan-line.
     */

    alloc_line (info, info->h, &scanbytes, &indices);

    for (y=0, scanline = indices;
	 y < info->h;
	 y++, scanline += scanbytes) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;
    }

    /*
     * Fail without VGA palette after the pixel stream.
     */

    if (!crimp_buf_has (buf, 768) ||
	!crimp_buf_match (buf, 1, "\f"))
	goto error;

    /*
     * Now decode the indices to RGB and save to the final result.
     */

    map = crimp_buf_at (buf);
    for (y=0, scanline = indices;
	 y < info->h;
	 y++, scanline += scanbytes) {

	for (x = 0; x < info->w; x++) {
	    map_color (map, scanline [x], &R(destination, x, y));
	}
    }
    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) indices);
    return ok;
}

static int
decode_rgb_raw (pcx_info*      info,
		crimp_buffer*  buf,
		crimp_image*   destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* red;
    unsigned char* green;
    unsigned char* blue;
    int x, y, ok = 1;

    alloc_line (info, 1, &scanbytes, &scanline);

    red   = scanline;
    green = red   + info->bytesLine;
    blue  = green + info->bytesLine;

    for (y=0; y < info->h; y++) {
	/*
	 * Note that a scanline is all of the RGB data, not a single color
	 * plane. RLE runs can straddle the border between planes.
	 */

	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;
	
	/*
	 * The scanline now holds the RGB values, separated by plane.
	 * Interleave them now for crimp.
	 */

	for (x = 0; x < info->w; x++) {
	    R (destination, x, y) = red   [x];
	    G (destination, x, y) = green [x];
	    B (destination, x, y) = blue  [x];
	}
    }

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static void
map_color (unsigned char* colorMap, int index, unsigned char* pix)
{
    /*
     * Each colorMap entry is 3 bytes. Both map and pixel use RGB order.
     */

    index *= 3; /* index += index << 1 */

    pix [0] = colorMap [index + 0]; /* Red   */
    pix [1] = colorMap [index + 1]; /* Green */
    pix [2] = colorMap [index + 2]; /* Blue  */
}

static void
alloc_line (pcx_info* info, int n, int* bytes, unsigned char** scanline)
{
    *bytes    = info->bytesLine * info->numPlanes;
    *scanline = (unsigned char*) ckalloc (*bytes * n);
}

#define CHECK_SPACE(n)				\
    if (!crimp_buf_has (buf, (n))) { return 0; }

static int
decode_line (crimp_buffer* buf, int bytes, unsigned char* scanline)
{
    unsigned int count, value;

    TRACE (("Scanline (%d)", bytes));

    count = value = 0;
    while (bytes) {
	CHECK_SPACE (1);
	crimp_buf_read_uint8 (buf, &value);
	TRACE (("\n[%02x]", value));

	if ((value & 0xc0) != 0xc0) {
	    count = 1;
	    /* Keep the value */
	    TRACE ((" ONE (%d)", value));
	} else {
	    /*
	     * Extract count and read next byte for the
	     * value to store.
	     */
	    count = value & 0x3f;
	    CHECK_SPACE (1);
	    crimp_buf_read_uint8 (buf, &value);
	    TRACE ((" [%02x] RLE (%dx%d)", value, count, value));
	}

	while (count && bytes) {
	    bytes--;
	    count--;
	    *(scanline++) = value;
	    TRACE (("."));
	}
    }

    TRACE (("\nEOL %d\n", count));
    return 1;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
