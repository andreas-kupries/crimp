/*
 * CRIMP :: SGI functions Definitions (Implementation).
 *
 * References
 *     ftp://ftp.sgi.com/graphics/SGIIMAGESPEC
 *     http://en.wikipedia.org/wiki/Silicon_Graphics_Image
 *	
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include <string.h>
#include "sgi.h"

/*
 * Debugging Help. Mainly the (RLE) decoders.
 */

/* #define SGI_TRACE 1 */
#ifdef SGI_TRACE
#define TRACE(x) { printf x ; fflush (stdout); }
#define DUMP(start,length,h,d) dump_offsets (start,length,h,d)
#else
#define TRACE(x)
#define DUMP(start,length,h,d)
#endif

#ifdef SGI_TRACE
static void
dump_offsets (unsigned long* start, unsigned long* length, int h, int d);
#endif

/*
 * Definitions :: Core.
 */

int
sgi_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 sgi_info*       info)
{
    /*
     * See sgi.h for details.
     */

    unsigned int width, height, depth, bpp, rank, minvalue, maxvalue;
    sgi_storage_type storage;
    sgi_colormap_type cmtype;
#ifdef SGI_TRACE
    /* Maps to enhance readability of enum values in trace output */
    const char* st_string [2] = { "verbatim", "rle" };
    const char* cm_string [4] = { "normal", "dithered", "screen", "colormap" };
#endif

    if (!crimp_buf_has   (buf, 512) ||
	!crimp_buf_match (buf, 2, "\1\332")) {
	Tcl_SetResult (interp, "Not a SGI raster image", TCL_STATIC);
	return 0;
    }

    crimp_buf_read_uint8    (buf, &storage);
    crimp_buf_read_uint8    (buf, &bpp);
    crimp_buf_read_uint16be (buf, &rank);
    crimp_buf_read_uint16be (buf, &width);
    crimp_buf_read_uint16be (buf, &height);
    crimp_buf_read_uint16be (buf, &depth);
    crimp_buf_read_uint32be (buf, &minvalue);
    crimp_buf_read_uint32be (buf, &maxvalue);
    crimp_buf_skip          (buf, 84); /* Ignore reserved and name/comment following */
    crimp_buf_read_uint32be (buf, &cmtype);
    crimp_buf_skip          (buf, 404); /* Ignore reserved2 */

    TRACE (("SGI (WxHxD)         %d (%dx%dx%d)\n", rank, width, height, depth));
    TRACE (("SGI (bytes/pix):    %d\n",       bpp));
    TRACE (("SGI (storage type): %d [%s]\n",  storage, st_string [storage]));
    TRACE (("SGI (color map id): %d [%s]\n",  cmtype,  cm_string [cmtype]));
    TRACE (("SGI (min/max):      %d-%d\n",    minvalue, maxvalue));

    /*
     * Check the internal consistency of the header.
     * - Valid values of various fields, separately
     * - Field interaction.
     */

    if (storage > sgi_storage_rle) {
	Tcl_SetResult (interp, "Bad SGI raster image (bad storage type)", TCL_STATIC);
	return 0;
    }
    if ((bpp != 1) &&
	(bpp != 2)) {
	Tcl_SetResult (interp,
		       "Bad SGI raster image (bad bytes/pixel/channel)",
		       TCL_STATIC);
	return 0;
    }
    if (rank > 3) {
	Tcl_SetResult (interp,
		       "Bad SGI raster image (too many dimensions)",
		       TCL_STATIC);
	return 0;
    }
    if ((rank == 1) &&
	((height != 1) ||
	 (depth != 1))) {
	Tcl_SetResult (interp,
		       "Bad SGI raster image (bad height/depth for 1D)",
		       TCL_STATIC);
	return 0;
    }
    if ((rank == 2) &&
	(depth != 1)) {
	Tcl_SetResult (interp, "Bad SGI raster image (bad depth for 2D)", TCL_STATIC);
	return 0;
    }
    if ((rank == 3) &&
	((depth != 1) &&
	 (depth != 3) &&
	 (depth != 4))) {
	Tcl_SetResult (interp, "Bad SGI raster image (bad depth for 3D)", TCL_STATIC);
	return 0;
    }

    /*
     * The nice thing is that we can rely on the height and depth information
     * now, regardless of the #dimensions.
     */

    if (cmtype > sgi_colormap_map) {
	Tcl_SetResult (interp, "Bad SGI raster image (bad color map id)", TCL_STATIC);
	return 0;
    }
    if ((cmtype == sgi_colormap_dithered) &&
	(depth != 1)) {
	Tcl_SetResult (interp,
		       "Bad SGI raster image (dithered/depth mismatch)",
		       TCL_STATIC);
	return 0;
    }

    /*
     * Next, check for values and combinations we are not supporting.
     */

    if (bpp == 2) {
	Tcl_SetResult (interp, "unable to handle 2 bytes/pixel)", TCL_STATIC);
	return 0;
    }
    if (cmtype == sgi_colormap_screen) {
	Tcl_SetResult (interp, "Unable to handle color-indexed images)", TCL_STATIC);
	return 0;
    }
    if (cmtype == sgi_colormap_map) {
	Tcl_SetResult (interp, "Unable to handle color-map images", TCL_STATIC);
	return 0;
    }

    /*
     * Save results for caller.
     */

    info->w             = width;
    info->h             = height;
    info->d             = depth;
    info->bpp           = bpp;
    info->min           = minvalue;
    info->max           = maxvalue;
    info->storage       = storage;
    info->mapType       = cmtype;
    info->input         = buf;

    /*
     * Time to read the offset tables, if any.
     */

    if (storage == sgi_storage_rle) {
	int i, n = height*depth; /* #entries in a single table group */
	int pixstart, pixend;

	TRACE (("SGI (rle tables):   2x %d\n", 4*n));

	if (!crimp_buf_has (buf, 2*4*n)) {
	    Tcl_SetResult (interp,
			   "Bad SGI raster image (no space for RLE offset data)",
			   TCL_STATIC);
	    return 0;
	}

	info->ostart  = CRIMP_ALLOC_ARRAY (n, unsigned long);
	info->olength = CRIMP_ALLOC_ARRAY (n, unsigned long);

	TRACE (("SGI RLE Offsets @ %d\n", crimp_buf_tell (buf)));

	for (i = 0; i < n; i++) {
	    crimp_buf_read_uint32be (buf, &info->ostart[i]);
	}

	TRACE (("SGI RLE Lengths @ %d\n", crimp_buf_tell (buf)));

	for (i = 0; i < n; i++) {
	    crimp_buf_read_uint32be (buf, &info->olength[i]);
	}

	TRACE (("SGI Pixel Area  @ %d\n", crimp_buf_tell (buf)));

	DUMP (info->ostart, info->olength, height, depth);

	/*
	 * Now validate the offsets and lengths, they have to be properly
	 * inside of the image. Note: Offsets are absolute, i.e. relative to
	 * the beginning of the whole file.
	 */

	pixstart = crimp_buf_tell (buf);
	pixend   = crimp_buf_size (buf);

	TRACE (("SGI Pixel Start @ %d\n", pixstart));
	TRACE (("SGI Pixel End   @ %d\n", pixend));

	for (i = 0; i < n; i++) {
	    if ((info->ostart[i] < pixstart) ||
		((info->ostart[i] + info->olength[i]) > pixend)) {

		TRACE (("RLE Offset Error [%d] %d - (%d - %d) - %d\n\n", i,
			pixstart,
			info->ostart[i], info->ostart[i] + info->olength[i],
			pixend));

		Tcl_SetResult (interp,
			       "Bad SGI raster image (rle offset out of bounds)",
			       TCL_STATIC);
		return 0;
	    }
	}
    } else {
	int plength;

	info->ostart  = NULL;
	info->olength = NULL;

	/*
	 * Compute number of bytes needed for the pixel data and check that
	 * that much of data is present. Because of the validated height and
	 * depth values (== 1 for the lower dimensions) we can simply multiply
	 * everything without have to special case anything. The bytes/pixel
	 * can be left out of this due to us restricting it to 1 during
	 * validation of the header. The assert ensures that a change in that
	 * condition is caught.
	 */

	CRIMP_ASSERT (bpp == 1,"Unexpected byte/channel/pixel != 1");
	plength = width * height * depth; /* * bpp */

	TRACE (("SGI (pixel direct): %d", plength));

	if (!crimp_buf_has (buf, plength)) {
	    Tcl_SetResult (interp,
			   "Bad SGI raster image (Not enough space for pixel data)",
			   TCL_STATIC);
	    return 0;
	}
    }

    return 1;
}

int
sgi_read_pixels (sgi_info*      info,
		 crimp_image**  destination)
{
    crimp_buffer*  buf = info->input;
    crimp_image*   dst = NULL;
    int            result = 0;
    unsigned char* pixel;

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     *   Which may be irrevalent for RLE compressed pixels.
     *
     * 'sgi_read_header', see above, ensures these conditions.
     *
     * Information influencing the decoding priocess:
     * - #channels, aka 'depth'
     * - verbatim/rle
     * - normal/dithered (only for depth == 1).
     */

    pixel = crimp_buf_at (buf);

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

#ifdef SGI_TRACE
static void
dump_offsets (unsigned long* start, unsigned long* length, int h, int d)
{
    int i,j;

    printf ("SGI RLE Offsets [%dx%d]\n", h, d);
    printf ("SGI ==============\n");

    for (i = 0; i < d; i++) {
	for (j = 0; j < h; j++) {
	    printf ("SGI LINE [%3d,%3d] = %8d %8d\n", i, j, *start, *length);
	    start++;
	    length++;
	}
	printf ("SGI ==============\n");
    }
}
#endif

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
