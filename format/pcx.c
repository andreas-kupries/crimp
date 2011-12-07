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

/* #define PCX_TRACE 1 */
#ifdef PCX_TRACE
#define TRACE(x) { printf x ; fflush (stdout); }
#define DUMP(map,n) dump_palette (map,n)
#else
#define TRACE(x)
#define DUMP(map,n)
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

static int
decode_striped4c (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_striped8c (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static int
decode_striped16c (pcx_info* info, crimp_buffer* buf, crimp_image* destination);

static void
map_color (unsigned char* colorMap, int index, unsigned char* pix);

#ifdef PCX_TRACE
static void
dump_palette (unsigned char* map, int n);
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
	(numPlanes != 2) &&
	(numPlanes != 3) &&
	(numPlanes != 4)) {
	Tcl_SetResult (interp, "Bad PCX image (bad #planes)", TCL_STATIC);
	return 0;
    }
    if (!(((numPlanes == 1) && ((numBitsPixelPlane == 1) ||
				(numBitsPixelPlane == 2) ||
				(numBitsPixelPlane == 4))) ||
	  ((numBitsPixelPlane == 1) && ((numPlanes == 1) ||
					(numPlanes == 2) ||
					(numPlanes == 3) ||
					(numPlanes == 4))) ||
	  ((numBitsPixelPlane == 8) && ((numPlanes == 1) ||
					(numPlanes == 3) ||
					(numPlanes == 4))))) {
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
     *   1 |   1 | 2-color,  1:255 0:0, no palette.
     *   4 |   1 | 4-color,  EGA palette
     *   2 |   1 | 16-color, EGA palette
     * ----+-----+--------------------------
     *   1 |   2 | 4-color,  bit-striped, EGA palette.
     *   1 |   3 | 8-color,  bit-striped, EGA palette.
     *   1 |   4 | 16-color, bit-striped, EGA palette.
     * ----+-----+--------------------------
     *   8 |   1 | RGB data via end-saved VGA palette
     *   8 |   1 | Grey scale data, no palette
     * ----+-----+--------------------------
     *   8 |   3 | RGB data, separated by plane
     * ----+-----+--------------------------
     *   X |   X | unknown, fail.
     * ----+-----+--------------------------
     */

    switch CODE (info->numBits, info->numPlanes) {
    case CODE(8,1):
	if (info->paletteType == 1) {
	    TRACE (("PCX (8/1 RGB, 256 colors VGA palette)\n"));

	    dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	    result = decode_rgb_vga (info, buf, dst);
	} else {
	    TRACE (("PCX (8/1 GREY8)\n"));

	    dst    = crimp_new_grey8_at (info->x, info->y, info->w, info->h);
	    result = decode_grey8 (info, buf, dst);
	}
	break;

    case CODE(8,3):
	TRACE (("PCX (8/3 RGB direct, no palette)\n"));

	dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	result = decode_rgb_raw (info, buf, dst);
	break;

    case CODE(4,1):
	TRACE (("PCX (4/1 16 color, EGA palette)\n"));

	dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	result = decode_16c (info, buf, dst);
	break;

    case CODE(2,1):
	TRACE (("PCX (2/1 4 color, EGA palette)\n"));

	dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	result = decode_4c (info, buf, dst);
	break;

    case CODE(1,1):
	TRACE (("PCX (1/1 BW direct, no palette)\n"));

	dst    = crimp_new_grey8_at (info->x, info->y, info->w, info->h);
	result = decode_2c (info, buf, dst);
	break;

    case CODE(1,4):
	TRACE (("PCX (1/4 16 color striped, EGA palette)\n"));

	dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	result = decode_striped16c (info, buf, dst);
	break;

    case CODE(1,3):
	TRACE (("PCX (1/3 8 color striped, EGA palette)\n"));

	dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	result = decode_striped8c (info, buf, dst);
	break;

    case CODE(1,2):
	TRACE (("PCX (1/2 4 color striped, EGA palette)\n"));

	dst    = crimp_new_rgb_at (info->x, info->y, info->w, info->h);
	result = decode_striped4c (info, buf, dst);
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
decode_striped4c (pcx_info*     info,
		  crimp_buffer* buf,
		  crimp_image*  destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* msb;
    unsigned char* lsb;
    unsigned char* map;
    int x, y, ok = 1;
    unsigned int l, la, lb, lc, ld, le, lf, lg, lh;
    unsigned int m, ma, mb, mc, md, me, mf, mg, mh;
    unsigned int    va, vb, vc, vd, ve, vf, vg, vh;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    lsb = scanline;
    msb = lsb + info->bytesLine;

    map = info->colorMap;
    DUMP (map, 4);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into grey8 pixels.
	 */

#define GET_INDEX	\
	l = lsb[x/8];	\
	m = msb[x/8]

#define NEXTX		\
	x++ ; if (info->w <= x) break

#define MAKE_INDEX(v,l,m)		\
	(v) = ((l) | ((m) << 1))

#define MAP(v)		\
	map_color (map, (v), &R(destination, x, y));	\
	TRACE ((" %d", (v)));


	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    GET_INDEX;

	    la  = (l & 0x80) >> 7;
	    ma  = (m & 0x80) >> 7;
	    MAKE_INDEX (va,la,ma);
	    MAP  (va);
	    NEXTX;

	    lb  = (l & 0x40) >> 6;
	    mb  = (m & 0x40) >> 6;
	    MAKE_INDEX (vb,lb,mb);
	    MAP  (vb);
	    NEXTX;

	    lc  = (l & 0x20) >> 5;
	    mc  = (m & 0x20) >> 5;
	    MAKE_INDEX (vc,lc,mc);
	    MAP  (vc);
	    NEXTX;

	    ld  = (l & 0x10) >> 4;
	    md  = (m & 0x10) >> 4;
	    MAKE_INDEX (vd,ld,md);
	    MAP  (vd);
	    NEXTX;

	    le  = (l & 0x08) >> 3;
	    me  = (m & 0x08) >> 3;
	    MAKE_INDEX (ve,le,me);
	    MAP  (ve);
	    NEXTX;

	    lf  = (l & 0x04) >> 2;
	    mf  = (m & 0x04) >> 2;
	    MAKE_INDEX (vf,lf,mf);
	    MAP  (vf);
	    NEXTX;

	    lg  = (l & 0x02) >> 1;
	    mg  = (m & 0x02) >> 1;
	    MAKE_INDEX (vg,lg,mg);
	    MAP  (vg);
	    NEXTX;

	    lh  = (l & 0x01);
	    mh  = (m & 0x01);
	    MAKE_INDEX (vh,lh,mh);
	    MAP  (vh);
	}
	TRACE (("\n"));
    }

#undef MAP
#undef MAKE_INDEX
#undef NEXTX
#undef GET_INDEX

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_striped8c (pcx_info*     info,
		  crimp_buffer* buf,
		  crimp_image*  destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* msb;
    unsigned char* usb;
    unsigned char* lsb;
    unsigned char* map;
    int x, y, ok = 1;
    unsigned int l, la, lb, lc, ld, le, lf, lg, lh;
    unsigned int m, ma, mb, mc, md, me, mf, mg, mh;
    unsigned int u, ua, ub, uc, ud, ue, uf, ug, uh;
    unsigned int    va, vb, vc, vd, ve, vf, vg, vh;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    lsb = scanline;
    usb = lsb + info->bytesLine;
    msb = usb + info->bytesLine;

    map = info->colorMap;
    DUMP (map, 8);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into grey8 pixels.
	 */

#define GET_INDEX	\
	l = lsb[x/8];	\
	u = usb[x/8];	\
	m = msb[x/8]

#define NEXTX		\
	x++ ; if (info->w <= x) break

#define MAKE_INDEX(v,l,u,m)			\
	(v) = ((l) | ((u) << 1) | ((m) << 2))

#define MAP(v)		\
	map_color (map, (v), &R(destination, x, y));	\
	TRACE ((" %d", (v)));


	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    GET_INDEX;

	    la  = (l & 0x80) >> 7;
	    ua  = (u & 0x80) >> 7;
	    ma  = (m & 0x80) >> 7;
	    MAKE_INDEX (va,la,ua,ma);
	    MAP  (va);
	    NEXTX;

	    lb  = (l & 0x40) >> 6;
	    ub  = (u & 0x40) >> 6;
	    mb  = (m & 0x40) >> 6;
	    MAKE_INDEX (vb,lb,ub,mb);
	    MAP  (vb);
	    NEXTX;

	    lc  = (l & 0x20) >> 5;
	    uc  = (u & 0x20) >> 5;
	    mc  = (m & 0x20) >> 5;
	    MAKE_INDEX (vc,lc,uc,mc);
	    MAP  (vc);
	    NEXTX;

	    ld  = (l & 0x10) >> 4;
	    ud  = (u & 0x10) >> 4;
	    md  = (m & 0x10) >> 4;
	    MAKE_INDEX (vd,ld,ud,md);
	    MAP  (vd);
	    NEXTX;

	    le  = (l & 0x08) >> 3;
	    ue  = (u & 0x08) >> 3;
	    me  = (m & 0x08) >> 3;
	    MAKE_INDEX (ve,le,ue,me);
	    MAP  (ve);
	    NEXTX;

	    lf  = (l & 0x04) >> 2;
	    uf  = (u & 0x04) >> 2;
	    mf  = (m & 0x04) >> 2;
	    MAKE_INDEX (vf,lf,uf,mf);
	    MAP  (vf);
	    NEXTX;

	    lg  = (l & 0x02) >> 1;
	    ug  = (u & 0x02) >> 1;
	    mg  = (m & 0x02) >> 1;
	    MAKE_INDEX (vg,lg,ug,mg);
	    MAP  (vg);
	    NEXTX;

	    lh  = (l & 0x01);
	    uh  = (u & 0x01);
	    mh  = (m & 0x01);
	    MAKE_INDEX (vh,lh,uh,mh);
	    MAP  (vh);
	}
	TRACE (("\n"));
    }

#undef MAP
#undef MAKE_INDEX
#undef NEXTX
#undef GET_INDEX

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_striped16c (pcx_info*     info,
		   crimp_buffer* buf,
		   crimp_image*  destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* msb;
    unsigned char* wsb;
    unsigned char* usb;
    unsigned char* lsb;
    unsigned char* map;
    int x, y, ok = 1;
    unsigned int l, la, lb, lc, ld, le, lf, lg, lh;
    unsigned int m, ma, mb, mc, md, me, mf, mg, mh;
    unsigned int u, ua, ub, uc, ud, ue, uf, ug, uh;
    unsigned int w, wa, wb, wc, wd, we, wf, wg, wh;
    unsigned int    va, vb, vc, vd, ve, vf, vg, vh;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    lsb = scanline;
    usb = lsb + info->bytesLine;
    wsb = usb + info->bytesLine;
    msb = wsb + info->bytesLine;

    map = info->colorMap;
    DUMP (map, 16);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into grey8 pixels.
	 */

#define GET_INDEX	\
	l = lsb[x/8];	\
	u = usb[x/8];	\
	w = wsb[x/8];	\
	m = msb[x/8]

#define NEXTX		\
	x++ ; if (info->w <= x) break

#define MAKE_INDEX(v,l,u,w,m)					\
	(v) = ((l) | ((u) << 1) | ((w) << 2) | ((m) << 3))

#define MAP(v)		\
	map_color (map, (v), &R(destination, x, y));	\
	TRACE ((" %d", (v)));


	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    GET_INDEX;

	    la  = (l & 0x80) >> 7;
	    ua  = (u & 0x80) >> 7;
	    wa  = (w & 0x80) >> 7;
	    ma  = (m & 0x80) >> 7;
	    MAKE_INDEX (va,la,ua,wa,ma);
	    MAP  (va);
	    NEXTX;

	    lb  = (l & 0x40) >> 6;
	    ub  = (u & 0x40) >> 6;
	    wb  = (w & 0x40) >> 6;
	    mb  = (m & 0x40) >> 6;
	    MAKE_INDEX (vb,lb,ub,wb,mb);
	    MAP  (vb);
	    NEXTX;

	    lc  = (l & 0x20) >> 5;
	    uc  = (u & 0x20) >> 5;
	    wc  = (w & 0x20) >> 5;
	    mc  = (m & 0x20) >> 5;
	    MAKE_INDEX (vc,lc,uc,wc,mc);
	    MAP  (vc);
	    NEXTX;

	    ld  = (l & 0x10) >> 4;
	    ud  = (u & 0x10) >> 4;
	    wd  = (w & 0x10) >> 4;
	    md  = (m & 0x10) >> 4;
	    MAKE_INDEX (vd,ld,ud,wd,md);
	    MAP  (vd);
	    NEXTX;

	    le  = (l & 0x08) >> 3;
	    ue  = (u & 0x08) >> 3;
	    we  = (w & 0x08) >> 3;
	    me  = (m & 0x08) >> 3;
	    MAKE_INDEX (ve,le,ue,we,me);
	    MAP  (ve);
	    NEXTX;

	    lf  = (l & 0x04) >> 2;
	    uf  = (u & 0x04) >> 2;
	    wf  = (w & 0x04) >> 2;
	    mf  = (m & 0x04) >> 2;
	    MAKE_INDEX (vf,lf,uf,wf,mf);
	    MAP  (vf);
	    NEXTX;

	    lg  = (l & 0x02) >> 1;
	    ug  = (u & 0x02) >> 1;
	    wg  = (w & 0x02) >> 1;
	    mg  = (m & 0x02) >> 1;
	    MAKE_INDEX (vg,lg,ug,wg,mg);
	    MAP  (vg);
	    NEXTX;

	    lh  = (l & 0x01);
	    uh  = (u & 0x01);
	    wh  = (w & 0x01);
	    mh  = (m & 0x01);
	    MAKE_INDEX (vh,lh,uh,wh,mh);
	    MAP  (vh);
	}
	TRACE (("\n"));
    }

#undef MAP
#undef MAKE_INDEX
#undef NEXTX
#undef GET_INDEX

    goto cleanup;

 error:
    ok = 0;
 cleanup:
    ckfree ((char*) scanline);
    return ok;
}

static int
decode_16c (pcx_info*     info,
	    crimp_buffer* buf,
	    crimp_image*  destination)
{
    int   scanbytes;
    unsigned char* scanline;
    unsigned char* map;
    int x, y, ok = 1;
    unsigned int v, va, vb;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    map = info->colorMap;
    DUMP (map, 16);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into a stream of palette
	 * indices and map them through the palette.
	 */

#define GET_INDEX(v)	\
	(v) = scanline[x/2]

#define NEXTX		\
	x++ ; if (info->w <= x) break

#define MAP(v)		\
	map_color (map, (v), &R(destination, x, y));	\
	TRACE ((" %d", (v)));


	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    GET_INDEX (v);

	    va  = (v & 0xF0) >> 4;
	    MAP (va);
	    NEXTX;

	    vb = (v & 0x0F);
	    MAP (vb);
	}
	TRACE (("\n"));
    }

#undef MAP
#undef NEXTX
#undef GET_INDEX

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
    unsigned int v, va, vb, vc, vd;

    /*
     * Allocate a buffer for the scanline. Decompress each line and then copy
     * it over to the destination, unchanged.
     */

    alloc_line (info, 1, &scanbytes, &scanline);

    map = info->colorMap;
    DUMP (map, 4);

    for (y=0; y < info->h; y++) {
	TRACE (("PCX DATA %d ", y));
	if (!decode_line (buf, scanbytes, scanline))
	    goto error;

	/*
	 * Now expanding the bits/bytes we got into a stream of palette
	 * indices and map them through the palette.
	 */

#define GET_INDEX(v)	\
	(v) = scanline[x/4]

#define NEXTX		\
	x++ ; if (info->w <= x) break

#define MAP(v)		\
	map_color (map, (v), &R(destination, x, y));	\
	TRACE ((" %d", (v)));


	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    GET_INDEX (v);

	    va  = (v & 0xC0) >> 6;
	    MAP (va);
	    NEXTX;

	    vb  = (v & 0x30) >> 4;
	    MAP (vb);
	    NEXTX;

	    vc  = (v & 0x0C) >> 2;
	    MAP (vc);
	    NEXTX;

	    vd  = (v & 0x03);
	    MAP (vd);
	}
	TRACE (("\n"));
    }

#undef MAP
#undef NEXTX
#undef GET_INDEX

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
    unsigned int v, va, vb, vc, vd, ve, vf, vg, vh;

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

#define GET_INDEX(v)	\
	(v) = scanline[x/8]

#define NEXTX		\
	x++ ; if (info->w <= x) break

#define MAP(v)		\
	(v) = ((v) ? WHITE : BLACK);		\
	GREY8 (destination, x, y) = (v);	\
	TRACE (("%c", (v) ? '_' : '*'));


	TRACE (("PIX: "));
        for (x = 0; x < info->w; x++) {
	    GET_INDEX (v);

	    va  = (v & 0x80) >> 7;
	    MAP (va);
	    NEXTX;

	    vb  = (v & 0x40) >> 6;
	    MAP (vb);
	    NEXTX;

	    vc  = (v & 0x20) >> 5;
	    MAP (vc);
	    NEXTX;

	    vd  = (v & 0x10) >> 4;
	    MAP (vd);
	    NEXTX;

	    ve  = (v & 0x08) >> 3;
	    MAP (ve);
	    NEXTX;

	    vf  = (v & 0x04) >> 2;
	    MAP (vf);
	    NEXTX;

	    vg  = (v & 0x02) >> 1;
	    MAP (vg);
	    NEXTX;

	    vh  = (v & 0x01);
	    MAP (vh);
	}
	TRACE (("\n"));
    }

#undef MAP
#undef NEXTX
#undef GET_INDEX

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
    DUMP (map, 256);

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

#ifdef PCX_TRACE
static void
dump_palette (unsigned char* map, int n)
{
    int i;

    printf ("PCX Palette [%d]\n", n);
    printf ("PCX ===============\n");

    for (i = 0; i < n; i++) {
	printf ("PCX RGB [%3d] = %3d, %3d, %3d\n", i, map[i*3+0], map[i*3+1], map[i*3+2]);
    }

    printf ("PCX ===============\n");
}
#endif

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
