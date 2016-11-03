/*
 * CRIMP :: SUN functions Definitions (Implementation).
 * Reference
 *	http://www.fileformat.info/format/sunraster/egff.htm
 *	
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include <string.h>
#include "sun.h"

/*
 * Debugging Help. Mainly the (RLE) decoders.
 */

/* #define SUN_TRACE 1 */
#ifdef SUN_TRACE
#define TRACE(x) { printf x ; fflush (stdout); }
#define DUMP(map,n) dump_palette (map,n)
#else
#define TRACE(x)
#define DUMP(map,n)
#endif

static void
map_color (unsigned char* colorMap, unsigned int size,
	   int index, unsigned char* pix);

#ifdef SUN_TRACE
static void
dump_palette (unsigned char* map, int n);
#endif

static int
decode_2fix (sun_info*      info,
	     unsigned char* pixel,
	     unsigned int   plength,
	     crimp_image*   destination);

static int
decode_2map (sun_info*      info,
	     unsigned char* pixel,
	     unsigned int   plength,
	     crimp_image*   destination);

static int
decode_grey8fix (sun_info*      info,
		 unsigned char* pixel,
		 unsigned int   plength,
		 crimp_image*   destination);

static int
decode_grey8map (sun_info*      info,
		 unsigned char* pixel,
		 unsigned int   plength,
		 crimp_image*   destination);

static int
decode_grey24map (sun_info*      info,
		  unsigned char* pixel,
		  unsigned int   plength,
		  crimp_image*   destination);

static int
decode_rgb (sun_info*      info,
	    unsigned char* pixel,
	    unsigned int   plength,
	    crimp_image*   destination);

static int
decode_bgr (sun_info*      info,
	    unsigned char* pixel,
	    unsigned int   plength,
	    crimp_image*   destination);

static int
decode_grey32map (sun_info*      info,
		  unsigned char* pixel,
		  unsigned int   plength,
		  crimp_image*   destination);

static int
decode_padrgb (sun_info*      info,
	       unsigned char* pixel,
	       unsigned int   plength,
	       crimp_image*   destination);

static int
decode_padbgr (sun_info*      info,
	       unsigned char* pixel,
	       unsigned int   plength,
	       crimp_image*   destination);

/*
 * Definitions :: Core.
 */

int
sun_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 sun_info*       info)
{
    /*
     * Reference
     *	http://www.fileformat.info/format/sunraster/egff.htm
     *
     * WORD and LONG values are stored in big-endian order.
     *
     * HEADER 32 bytes, 8*LONG (4byte)
     *  0.. 3 | 4 : magic == 0x59 0xa6 0x6a 0x95
     *  4.. 7 | 4 : width
     *  8..11 | 4 : height
     * 12..15 | 4 : bits/pixel
     * 16..21 | 4 : #pixel bytes
     * 20..23 | 4 : raster type
     * 24..27 | 4 : color map type
     * 28..31 | 4 : color map length [1]
     *
     * Header is followed by [1] bytes, the color map, if any.
     * Color Map/Header is followed by pixel data.
     */

    unsigned int width, height, bpp, plength, cmlength;
    unsigned char* colorMap = 0;
    sun_raster_type rtype;
    sun_colormap_type cmtype;

    if (!crimp_buf_has   (buf, 32) ||
	!crimp_buf_match (buf, 4, "\131\246\152\225")) {
	Tcl_SetResult (interp, "Not a SUN raster image", TCL_STATIC);
	return 0;
    }

    crimp_buf_read_uint32be (buf, &width);
    crimp_buf_read_uint32be (buf, &height);
    crimp_buf_read_uint32be (buf, &bpp);
    crimp_buf_read_uint32be (buf, &plength);
    crimp_buf_read_uint32be (buf, &rtype);
    crimp_buf_read_uint32be (buf, &cmtype);
    crimp_buf_read_uint32be (buf, &cmlength);

    TRACE (("SUN (WxH):         %dx%d\n", width, height));
    TRACE (("SUN (bits/pix):    %d\n", bpp));
    TRACE (("SUN (raster type): %d\n", rtype));
    TRACE (("SUN (map type):    %d\n", cmtype));
    TRACE (("SUN (map length):  %d\n", cmlength));
    TRACE (("SUN (#PixelBytes): %d\n", plength));

    /*
     * Check the internal consistency of the header.
     * - Valid values of various fields, separately
     * - Field interaction.
     */

    if ((bpp != 1) &&
	(bpp != 8) &&
	(bpp != 24) &&
	(bpp != 32)) {
	Tcl_SetResult (interp, "Bad SUN raster image (bad bits/pixel)", TCL_STATIC);
	return 0;
    }

    if (rtype > sun_raster_rgb) {
	Tcl_SetResult (interp, "Bad SUN raster image (bad raster type)", TCL_STATIC);
	return 0;
    }

    if (cmtype > sun_colormap_raw) {
	Tcl_SetResult (interp, "Bad SUN raster image (bad color map type)", TCL_STATIC);
	return 0;
    }

    if ((cmtype == sun_colormap_none) && cmlength) {
	Tcl_SetResult (interp, "Bad SUN raster image (color map type/length mismatch)", TCL_STATIC);
	return 0;
    }

    if ((cmtype == sun_colormap_rgb) && !cmlength) {
	Tcl_SetResult (interp, "Bad SUN raster image (color map type/length mismatch)", TCL_STATIC);
	return 0;
    }

    if (cmtype == sun_colormap_raw) {
	Tcl_SetResult (interp, "Unable to handle raw color map in SUN raster image", TCL_STATIC);
	return 0;
    }

    if (cmlength && ((cmlength % 3) != 0)) {
	/* Implies sun_colormap_rgb */
	Tcl_SetResult (interp, "Bad SUN raster image (bad color map length)", TCL_STATIC);
	return 0;
    }

    /*
     * Fix missing information.
     */

    if (plength == 0) {
	/* Older Sun raster file, encoding type, fixed as 0
	 */
	plength = (width * height * bpp) / 8;
    }

    /*
     * Save results for caller.
     */

    info->w             = width;
    info->h             = height;
    info->numBits       = bpp;
    info->type          = rtype;
    info->mapType       = cmtype;
    info->input         = buf;
    info->numPixelBytes = plength;

    /*
     * Time to read the color map, if any.
     */

    if (cmlength) {
	info->numColors = cmlength / 3;
	info->colorMap  = crimp_buf_at (buf);
	crimp_buf_skip (buf, cmlength);

	DUMP (info->colorMap, info->numColors);

	/*
	 * TODO: Should validate num colors against max number of colors
	 * implied by the bit depth.
	 */

    } else {
	info->numColors = 0;
	info->colorMap  = NULL;
    }

    TRACE (("SUN (#colors):     %d\n", info->numColors));

    /*
     * And check that the indicated number of bytes for pixel data is actually
     * present.
     */

    if (!crimp_buf_has (buf, plength)) {
	Tcl_SetResult (interp, "Bad SUN raster image (Not enough space for pixel data)", TCL_STATIC);
	return 0;
    }

    return 1;
}

int
sun_read_pixels (sun_info*      info,
		 crimp_image**  destination)
{
    crimp_buffer* buf = info->input;
    crimp_image*  dst = NULL;
    int           result = 0;
    unsigned char* pixel;
    unsigned int   plength;

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     *
     * 'sun_read_header', see above, ensures these conditions.
     *
     * Information influencing the decoding priocess:
     * - bits/pixel
     * - presence of color map
     * - raster_type (RLE or not, RGB or not)
     *
     * The run-length coding scheme (type sun_raster_rle) may be present for
     * ANY type of image data. It is byte based, without a concept of pixels
     * or scanlines. We should consider it as a pre-decode step when present.
     *
     * Note that the pixel data (after decompression) is scan-line oriented,
     * and each scan-line must be of even length, regardless of image width.
     *
     * Note that full-color images (bpp 24/32) which are not of type
     * "sun_raster_rgb" store the color channels of a pixel in BGR order.
     * Note how this means that RLE compressed full-color images are always
     * using BGR order.
     *
     * Note that 32 bpp true-color images only use 24 bits/pixel, i.e.
     * 3byte/pixel, with the first byte in each pixel a pad byte we have to
     * ignore.
     */

    pixel   = crimp_buf_at (buf);
    plength = info->numPixelBytes;

    TRACE (("SUN LEFT %8d INITIAL\n", plength));

    if (info->type == sun_raster_rle) {
	TRACE (("SUN unable to handle RLE, not yet implemented\n"));
	/* TODO: RLE decoder.
	 * Currently none of the examples use RL compression.
	 * pixel   = ...; -- allocated, see (a) for release.
	 * plength = ...;
	 */
	goto done;
    }

    switch (info->numBits) {
    case 32:
	if (info->colorMap) {
	    TRACE (("SUN 32bpp + color map\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_grey32map (info, pixel, plength, dst);
	} else if (info->type == sun_raster_rgb) {
	    TRACE (("SUN 32bpp true color RGB\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_padrgb (info, pixel, plength, dst);
	} else {
	    TRACE (("SUN 32bpp true color BGR\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_padbgr (info, pixel, plength, dst);
	}
	break;
    case 24:
	if (info->colorMap) {
	    TRACE (("SUN 24bpp + color map\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_grey24map (info, pixel, plength, dst);
	} else if (info->type == sun_raster_rgb) {
	    TRACE (("SUN 24bpp true color RGB\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_rgb (info, pixel, plength, dst);
	} else {
	    TRACE (("SUN 24bpp true color BGR\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_bgr (info, pixel, plength, dst);
	}
	break;
    case 8:
	if (info->colorMap) {
	    TRACE (("SUN 8bpp + color map\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_grey8map (info, pixel, plength, dst);
	} else {
	    TRACE (("SUN 8bpp grey scale\n"));
	    dst = crimp_new_grey8 (info->w, info->h);
	    result = decode_grey8fix (info, pixel, plength, dst);
	}
	break;
    case 1:
	if (info->colorMap) {
	    TRACE (("SUN 1bpp + color map\n"));
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_2map (info, pixel, plength, dst);
	} else {
	    TRACE (("SUN 1bpp black/white\n"));
	    dst = crimp_new_grey8 (info->w, info->h);
	    result = decode_2fix (info, pixel, plength, dst);
	}
	break;
    default:
	TRACE (("SUN %d bpp, unknown to decode\n", info->numBits));
	break;
    }

    if (pixel != crimp_buf_at (buf)) {
	/* (a) Release of buffer holding decompresion result */
	ckfree ((char*) pixel);
    }

    /*
     */

 done:
    if (dst) {
	if (result) {
	    *destination = dst;
	} else {
	    crimp_del (dst);
	}
    } 
    return result;
}

/*
 * Pixel decoder functions. Plus helper macros.
 */

#define GET_VALUE(v)			\
    if (plength == 0) { return 0; } ;	\
    (v) = *pixel;			\
    pixel ++;				\
    plength --;

#define NEXTX \
    x++ ; if (info->w <= x) break

#define CHECK_INDEX(v) \
    if (mapSize < (v)) { return 0; }


static int
decode_2fix (sun_info*      info,
	     unsigned char* pixel,
	     unsigned int   plength,
	     crimp_image*   destination)
{
    /*
     * Indexed data at 8 pixel/byte (Each pixel is 1 bit). Left to right is
     * MSB to LSB. Each scan-line is 2-aligned relative to its start. For each
     * octet we make sure that we have not run over the buffer-end. The color
     * mapping is fixed, hardwired: 0 -> black, 1 -> white, grey8 result
     */

    int x, y;
    unsigned int v, va, vb, vc, vd, ve, vf, vg, vh;
    unsigned char* base = pixel;

    CRIMP_ASSERT (info->numBits == 1, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, grey8);

#define MAP(v)					\
    (v) = ((v) ? WHITE : BLACK);		\
    GREY8 (destination, x, y) = (v);		\
    TRACE (("%c", (v) ? '_' : '*'));

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {
	    GET_VALUE (v);

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

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_2map (sun_info*      info,
	     unsigned char* pixel,
	     unsigned int   plength,
	     crimp_image*   destination)
{
    /*
     * Indexed data at 8 pixel/byte (Each pixel is 1 bit). Left to right is
     * MSB to LSB. Each scan-line is 2-aligned relative to its start. For each
     * octet we make sure that we have not run over the buffer-end. The color
     * mapping comes out of info.
     */

    int x, y;
    unsigned int v, va, vb, vc, vd, ve, vf, vg, vh;
    unsigned char* base = pixel;
    unsigned char* map = info->colorMap;
    int mapSize = info->numColors;

    CRIMP_ASSERT (info->numBits == 1, "Bad format");
    CRIMP_ASSERT (info->numColors == 2, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

#define MAP(v)		\
    map_color (map, mapSize, (v), &R(destination, x, y));	\
    TRACE ((" %d", (v)));

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {
	    GET_VALUE (v);

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

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_grey8fix (sun_info*      info,
		 unsigned char* pixel,
		 unsigned int   plength,
		 crimp_image*   destination)
{
    /*
     * Indexed data at 1 pixel/byte (eq 1 byte/pixel). Left to right is
     * MSB to LSB. Each scan-line is 2-aligned relative to its start. For each
     * octet we make sure that we have not run over the buffer-end. The result
     * is a plain grey scale image (fixed color mapping, identity).
     */

    int x, y;
    unsigned int v;
    unsigned char* base = pixel;

    CRIMP_ASSERT (info->numBits == 8, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, grey8);

#define MAP(v)					\
    GREY8 (destination, x, y) = (v);		\
    TRACE ((" %d", (v)));

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {
	    GET_VALUE (v);
	    MAP (v);
	}

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_grey8map (sun_info*      info,
		 unsigned char* pixel,
		 unsigned int   plength,
		 crimp_image*   destination)
{
    /*
     * Indexed data at 1 pixel/byte (eq 1 byte/pixel). Left to right is
     * MSB to LSB. Each scan-line is 2-aligned relative to its start. For each
     * octet we make sure that we have not run over the buffer-end. The result
     * is a rgb image (color mapping out of info).
     */

    int x, y;
    unsigned int v;
    unsigned char* base = pixel;
    unsigned char* map = info->colorMap;
    int mapSize = info->numColors;

    CRIMP_ASSERT (info->numBits == 8, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

#define MAP(v)							\
    map_color (map, mapSize, (v), &R(destination, x, y));	\
    TRACE ((" %d", (v)));

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {
	    GET_VALUE (v);
	    CHECK_INDEX (v);
	    MAP (v);
	}

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_grey24map (sun_info*      info,
		  unsigned char* pixel,
		  unsigned int   plength,
		  crimp_image*   destination)
{
    /*
     * Indexed data at 4 byte/pixel, although only 3 are used. Big-endian long
     * words. Each scan-line is 2-aligned relative to its start. For each
     * octet we make sure that we have not run over the buffer-end. The result
     * is an rgb image (color mapping out of info).
     */

    int x, y;
    unsigned int v, v3, v2, v1, dummy;
    unsigned char* base = pixel;
    unsigned char* map = info->colorMap;
    int mapSize = info->numColors;

    CRIMP_ASSERT (info->numBits == 24, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

#define MAP(v)							\
    map_color (map, mapSize, (v), &R(destination, x, y));	\
    TRACE ((" %d", (v)));

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {

	    GET_VALUE (v3);
	    GET_VALUE (v2);
	    GET_VALUE (v1);
	    GET_VALUE (dummy);

	    v = (v3 << 16) | (v2 << 8) | v1;
	    TRACE ((" %d", v));

	    CHECK_INDEX (v);
	    MAP (v);
	}

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_rgb (sun_info*      info,
	    unsigned char* pixel,
	    unsigned int   plength,
	    crimp_image*   destination)
{
    /*
     * True color with 3 byte/pixel (RGB). Each scan-line is 2-aligned
     * relative to its start. For each octet we make sure that we have not run
     * over the buffer-end. The result is an rgb image.
     */

    int x, y;
    unsigned int r, g, b, dummy;
    unsigned char* base = pixel;

    CRIMP_ASSERT (info->numBits == 24, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {

	    GET_VALUE (r);
	    GET_VALUE (g);
	    GET_VALUE (b);

	    TRACE ((" (%d,%d,%d)", r,g,b));

	    R (destination, x, y) = r;
	    G (destination, x, y) = g;
	    B (destination, x, y) = b;
	}

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_bgr (sun_info*      info,
	    unsigned char* pixel,
	    unsigned int   plength,
	    crimp_image*   destination)
{
    /*
     * True color with 3 byte/pixel (BGR). Each scan-line is 2-aligned
     * relative to its start. For each octet we make sure that we have not run
     * over the buffer-end. The result is an rgb image.
     */

    int x, y;
    unsigned int r, g, b, dummy;
    unsigned char* base = pixel;

    CRIMP_ASSERT (info->numBits == 24, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {

	    GET_VALUE (b);
	    GET_VALUE (g);
	    GET_VALUE (r);

	    TRACE ((" (%d,%d,%d)", r,g,b));

	    R (destination, x, y) = r;
	    G (destination, x, y) = g;
	    B (destination, x, y) = b;
	}

	if ((pixel-base)%2) {
	    TRACE ((" ALIGN % 2"));
	    pixel ++;
	    plength --;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_grey32map (sun_info*      info,
		  unsigned char* pixel,
		  unsigned int   plength,
		  crimp_image*   destination)
{
    /*
     * Indexed data at 4 byte/pixel. Big-endian long words. Each scan-line is
     * 2-aligned relative to its start. For each octet we make sure that we
     * have not run over the buffer-end. The result is an rgb image.
     */

    int x, y;
    unsigned int v, v4, v3, v2, v1;
    unsigned char* base = pixel;
    unsigned char* map = info->colorMap;
    int mapSize = info->numColors;

    CRIMP_ASSERT (info->numBits == 24, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

#define MAP(v)							\
    map_color (map, mapSize, (v), &R(destination, x, y));	\
    TRACE ((" %d", (v)));

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {

	    GET_VALUE (v4);
	    GET_VALUE (v3);
	    GET_VALUE (v2);
	    GET_VALUE (v1);

	    v = (v4 << 24) | (v3 << 16) | (v2 << 8) | v1;
	    TRACE ((" %d", v));

	    CHECK_INDEX (v);
	    MAP (v);
	}

	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_padrgb (sun_info*      info,
	       unsigned char* pixel,
	       unsigned int   plength,
	       crimp_image*   destination)
{
    /*
     * True color with 4 byte/pixel (pad + RGB). Each scan-line is 2-aligned
     * relative to its start. For each octet we make sure that we have not run
     * over the buffer-end. The result is an rgb image
     */

    int x, y;
    unsigned int r, g, b, dummy;
    unsigned char* base = pixel;

    CRIMP_ASSERT (info->numBits == 32, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgb);

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {

	    GET_VALUE (dummy);
	    GET_VALUE (r);
	    GET_VALUE (g);
	    GET_VALUE (b);

	    TRACE ((" (%d,%d,%d)", r,g,b));

	    R (destination, x, y) = r;
	    G (destination, x, y) = g;
	    B (destination, x, y) = b;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

static int
decode_padbgr (sun_info*      info,
	       unsigned char* pixel,
	       unsigned int   plength,
	       crimp_image*   destination)
{
    /*
     * True color with 4 byte/pixel (pad + BGR). Each scan-line is 2-aligned
     * relative to its start. For each octet we make sure that we have not run
     * over the buffer-end. The result is an rgb image
     */

    int x, y;
    unsigned int r, g, b, dummy;
    unsigned char* base = pixel;

    CRIMP_ASSERT (info->numBits == 32, "Bad format");
    CRIMP_ASSERT_IMGTYPE (destination, rgba);

    for (y = 0; y < info->h; y++) {
	TRACE (("SUN LEFT %8d PIX: ", plength));
	for (x = 0; x < info->w; x++) {

	    GET_VALUE (dummy);
	    GET_VALUE (b);
	    GET_VALUE (g);
	    GET_VALUE (r);

	    TRACE ((" (%d,%d,%d)", r,g,b));

	    R (destination, x, y) = r;
	    G (destination, x, y) = g;
	    B (destination, x, y) = b;
	}
	TRACE (("\n"));
    }

#undef MAP
    TRACE (("SUN LEFT %8d DONE\n", plength));
    return 1;
}

#undef NEXTX
#undef GET_VALUE
#undef CHECK_INDEX

/* Run-Length coding of sun raster data.
 * We have 3 types of code "packets":
 *
 * (a) 0x80 0x00                --> Run of 1 times 0x80
 * (b) 0x80 <count> <value> [1] --> Run of count times value
 * (c) <any>                [2] -->  Run of 1 times <any>
 *
 * [1] count in 1..255
 *     value in 0.255
 *     Note how count is > 0, distinguishing (b) packets from (a).
 *
 * [2] To be clear, <any> excludes 0x80, distinguishing (c) from
 *     (a) and (b).
 *
 * Alternate phrasing:
 * - 0x80 is a flag value introducing runs.
 * - Any other bytes are literal.
 * - After the flag comes a count byte.
 * - A count of 0 signals a literal 0x80, escaping the flag value.
 * - Any other count is followed by the byte to repeat.
 */


static void
map_color (unsigned char* colorMap,
	   unsigned size,
	   int index,
	   unsigned char* pix)
{
    /*
     * A color map (we are able to process), consists of 3 planes, each
     * containing the R, G, and B values of an entry. This is different from
     * most other color maps where the RGB bytes of each entry are adjacent to
     * each other. This mainly affects how we index into the map. I.e. the
     * format is, (for 4 colors):
     *
     * RRRR,GGGG,BBBB
     *
     * Whereas the format of most others is RGB,RGB,RGB,RGB
     */

    pix [0] = colorMap [index + 0*size]; /* Red   */
    pix [1] = colorMap [index + 1*size]; /* Green */
    pix [2] = colorMap [index + 2*size]; /* Blue  */
}

#ifdef SUN_TRACE
static void
dump_palette (unsigned char* map, int n)
{
    int i;

    printf ("SUN Color Map [%d]\n", n);
    printf ("SUN ==============\n");

    for (i = 0; i < n; i++) {
	printf ("SUN RGB [%3d] = %3d, %3d, %3d\n",
		i, map[i+0*n], map[i+1*n], map[i+2*n]);
    }

    printf ("SUN ===============\n");
}
#endif

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
