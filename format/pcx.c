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

#include "pcx.h"

/*
 * Debugging Help. Mainly the RLE decoders.
 */

/*#define RLE_TRACE 1*/
#ifdef RLE_TRACE
#define TRACE(x) { printf x ; fflush (stdout); }
#else
#define TRACE(x)
#endif

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
     * [6]  1 : Grey color image
     *      3 : RGB image
     *      4 : RGB image with EGA specific intensity channel.
     *
     * Max Number of Colors = 2 * 'Bits/Pixel/Plane' * 'Number Of Bit Planes'
     *
     * [7] Bytes needed to store a single decoded scan line of a single plane.
     *     A full scan line (all planes) takes
     *
     *         Scan Line Length = 'Bytes/Lines' * 'Number Of Bit Planes'
     *
     * [8] 0 : color/monochrome palette | Can be ignored.
     *     1 : grey-scale palette       |
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
    unsigned int left, right, top, bottom;
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
    crimp_buf_read_uint16le (buf, &right);
    crimp_buf_read_uint16le (buf, &top);
    crimp_buf_read_uint16le (buf, &bottom);
    crimp_buf_skip          (buf, 4);  /* 2x2 h/v DPI. FUTURE: meta data */
    colorMap = crimp_buf_at (buf);     /* EGA palette. */
    crimp_buf_skip          (buf, 48); /* Jump EGA palette */
    crimp_buf_read_uint8    (buf, &reserved);
    crimp_buf_read_uint8    (buf, &numPlanes);
    crimp_buf_read_uint16le (buf, &numBytesLine);
    crimp_buf_skip          (buf, 50); /* Palette type, screen & reserved2 */

    /*
     * Check the internal consistency of the data retrieved so far.
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

    /*
     * Save results for caller, including derivatives.
     */

    info->x             = left;
    info->y             = top;
    info->w             = right - left + 1;
    info->h             = bottom - top + 1;
    info->colorMap      = colorMap;
    //info->numColors     = nColors;
    info->numBits       = numBitsPixelPlane;
    info->numPlanes     = numPlanes;
    info->bytesLine     = numBytesLine;
    info->input         = buf;

    return 1;
}

int
pcx_read_pixels (pcx_info*      info,
		 crimp_image*   destination)
{
    crimp_buffer* buf = info->input;

    CRIMP_ASSERT_IMGTYPE (destination, rgb);
    CRIMP_ASSERT ((info->w == destination->w) &&
		  (info->h == destination->h), "Dimension mismatch");

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     *
     * 'pcx_read_header', see above, ensures these conditions.
     */

    CRIMP_ASSERT(0,"Not reached");
    return 0;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
