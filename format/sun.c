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
    TRACE (("SUN (#PixelBytes): %d\n", plength));
    TRACE (("SUN (raster type): %d\n", rtype));
    TRACE (("SUN (map type):    %d\n", cmtype));
    TRACE (("SUN (map length):  %d\n", cmlength));

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

    /*
     * Time to read the color map, if any.
     */

    if (cmlength) {
	info->numColors = cmlength / 3;
	info->colorMap  = crimp_buf_at (buf);
	crimp_buf_skip (buf, cmlength);
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

#define CODE(bpp,planes) (((bpp)<<4)|(planes))

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     *
     * 'sun_read_header', see above, ensures these conditions.
     */

    /*
     */

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
