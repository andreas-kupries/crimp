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

static int decode_rgbpacked (sgi_info* info, crimp_buffer* buf, crimp_image* dst);

static int decode_grey8     (sgi_info* info, crimp_buffer* buf, crimp_image* dst);
static int decode_rgb       (sgi_info* info, crimp_buffer* buf, crimp_image* dst);
static int decode_rgba      (sgi_info* info, crimp_buffer* buf, crimp_image* dst);

static int
decode_rle (crimp_buffer* buf, unsigned char* dst, int delta, int n, int start, int length);

static int decode_grey8_short (sgi_info* info, crimp_buffer* buf, crimp_image* dst);
static int decode_rgb_short   (sgi_info* info, crimp_buffer* buf, crimp_image* dst);
static int decode_rgba_short  (sgi_info* info, crimp_buffer* buf, crimp_image* dst);

static int
decode_rle_short (crimp_buffer* buf, unsigned char* dst, int delta, int n, int start, int length);

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

    unsigned int width, height, depth, bpp, rank;
    unsigned long minvalue, maxvalue, cmtypecode;
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
    crimp_buf_read_uint32be (buf, &cmtypecode);
    cmtype = cmtypecode;
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
    if ((cmtype == sgi_colormap_dithered) &&
	(bpp != 1)) {
	Tcl_SetResult (interp,
		       "Bad SGI raster image (dithered/bpp mismatch)",
		       TCL_STATIC);
	return 0;
    }

    /*
     * Next, check for values and combinations we are not supporting.
     */

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
	 * everything without have to special case anything.
	 */

	plength = width * height * depth * bpp;

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
     * - bytes/pixel (1..2, i.e byte or short).
     *   Note: Shorts are stored bigendian, and reduced to the
     *         MSB to fit them into the existing crimp image
     *         types.
     */

    switch (info->d) {
    case 1:
	if (info->mapType == sgi_colormap_dithered) {
	    CRIMP_ASSERT (info->bpp == 1,"Expected 1 byte/pixel for packed rgb");
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_rgbpacked (info, buf, dst);
	} else if (info->bpp == 2) {
	    dst    = crimp_new_grey8 (info->w, info->h);
	    result = decode_grey8_short (info, buf, dst);
	} else {
	    dst    = crimp_new_grey8 (info->w, info->h);
	    result = decode_grey8 (info, buf, dst);
	}
	break;
    case 3:
	if (info->bpp == 2) {
	    dst    = crimp_new_rgb (info->w, info->h);
	    result = decode_rgb_short (info, buf, dst);
	} else {
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_rgb (info, buf, dst);
	}
	break;
    case 4:
	if (info->bpp == 2) {
	    dst    = crimp_new_rgb (info->w, info->h);
	    result = decode_rgba_short (info, buf, dst);
	} else {
	    dst = crimp_new_rgb (info->w, info->h);
	    result = decode_rgba (info, buf, dst);
	}
	break;
    default:
	TRACE (("SGI unsupported format\n"));
	break;
    }

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

static int
decode_rgbpacked (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h, value, r, g, b;
    CRIMP_ASSERT_IMGTYPE (dst, rgb);
    TRACE (("SGI RGB packed\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	unsigned char* pixel = crimp_buf_at (buf);

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		value = *pixel ++;

		/* value = BBB.GGG.RR (bit-packed 3:3:2, ordered BGR) */
		/*         765 432 10 */

		b = (value & 0xe0) >> 5;
		g = (value & 0x1c) >> 2;
		r = (value & 0x03);

		R (dst, x, y) = r;
		G (dst, x, y) = g;
		B (dst, x, y) = b;
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int i;

	for (y = h-1, i = 0;
	     y >= 0;
	     y--, i++) {

	    /* Decompress into destination, avoiding a temp buffer */

	    TRACE (("SGI PIX DATA %8d", y));

	    if (!decode_rle (buf, &R (dst, 0, y), 3, w, os[i], ol[i])) {
		return 0;
	    }

	    /* Expand the bit packing in place */

	    for (x = 0; x < w; x++) {
		value = R (dst, x, y);

		/* value = BBB.GGG.RR (bit-packed 3:3:2, ordered BGR) */
		/*         765 432 10 */

		b = (value & 0xe0) >> 5;
		g = (value & 0x1c) >> 2;
		r = (value & 0x03);

		R (dst, x, y) = r;
		G (dst, x, y) = g;
		B (dst, x, y) = b;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX RGB ="));
	    for (x=0;x<w;x++) {
		TRACE ((" (%d, %d, %d)", R(dst,x,y), G(dst,x,y), B(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }
}

static int
decode_grey8 (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h;
    CRIMP_ASSERT_IMGTYPE (dst, grey8);
    TRACE (("SGI GREY8\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	unsigned char* pixel = crimp_buf_at (buf);

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		GREY8 (dst, x, y) = *pixel ++;
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int i;

	for (y = h-1, i = 0;
	     y >= 0;
	     y--, i++) {

	    TRACE (("SGI PIX DATA %8d", y));
	    if (!decode_rle (buf, &GREY8 (dst, 0, y), 1, w, os[i], ol[i])) {
		return 0;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX GREY8 ="));
	    for (x=0;x<w;x++) {
		TRACE ((" %d", GREY8(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }
}

decode_grey8_short (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h;
    CRIMP_ASSERT_IMGTYPE (dst, grey8);
    TRACE (("SGI GREY8 /SHORT\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	unsigned char* pixel = crimp_buf_at (buf);

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		GREY8 (dst, x, y) = *pixel; /* Read MSB */
		pixel += 2;                 /* Next short, LSB skipped */
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int i;

	for (y = h-1, i = 0;
	     y >= 0;
	     y--, i++) {

	    TRACE (("SGI PIX DATA %8d", y));
	    if (!decode_rle_short (buf, &GREY8 (dst, 0, y), 1, w, os[i], ol[i])) {
		return 0;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX GREY8 ="));
	    for (x=0;x<w;x++) {
		TRACE ((" %d", GREY8(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }
}

static int
decode_rgb (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h;
    CRIMP_ASSERT_IMGTYPE (dst, rgb);
    TRACE (("SGI RGB\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	int            n = w * h;
	unsigned char* r = crimp_buf_at (buf);
	unsigned char* g = r + n;
	unsigned char* b = g + n;

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		R (dst, x, y) = *r ++;
		G (dst, x, y) = *g ++;
		B (dst, x, y) = *b ++;
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int r, g, b;

	for (y = h-1, r = 0, g = h, b = h+h;
	     y >= 0;
	     y--, r++, g++, b++) {

	    TRACE (("SGI PIX DATA %8d R", y));
	    if (!decode_rle (buf, &R (dst, 0, y), 3, w, os[r], ol[r])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d G", y));
	    if (!decode_rle (buf, &G (dst, 0, y), 3, w, os[g], ol[g])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d B", y));
	    if (!decode_rle (buf, &B (dst, 0, y), 3, w, os[b], ol[b])) {
		return 0;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX RGB ="));
	    for (x=0;x<w;x++) {
		TRACE ((" (%d, %d, %d)", R(dst,x,y), G(dst,x,y), B(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }

    return 1;
}

static int
decode_rgb_short (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h;
    CRIMP_ASSERT_IMGTYPE (dst, rgb);
    TRACE (("SGI RGB /SHORT\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	int            n = w * h * sizeof (short);
	unsigned char* r = crimp_buf_at (buf);
	unsigned char* g = r + n;
	unsigned char* b = g + n;

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		/* Read only MSB, skip LSB */
		R (dst, x, y) = *r; r += 2;
		G (dst, x, y) = *g; g += 2;
		B (dst, x, y) = *b; b += 2;
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int r, g, b;

	for (y = h-1, r = 0, g = h, b = h+h;
	     y >= 0;
	     y--, r++, g++, b++) {

	    TRACE (("SGI PIX DATA %8d R", y));
	    if (!decode_rle_short (buf, &R (dst, 0, y), 3, w, os[r], ol[r])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d G", y));
	    if (!decode_rle_short (buf, &G (dst, 0, y), 3, w, os[g], ol[g])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d B", y));
	    if (!decode_rle_short (buf, &B (dst, 0, y), 3, w, os[b], ol[b])) {
		return 0;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX RGB ="));
	    for (x=0;x<w;x++) {
		TRACE ((" (%d, %d, %d)", R(dst,x,y), G(dst,x,y), B(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }

    return 1;
}

static int
decode_rgba (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h;
    CRIMP_ASSERT_IMGTYPE (dst, rgba);
    TRACE (("SGI RGBA\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	int            n = w * h;
	unsigned char* r = crimp_buf_at (buf);
	unsigned char* g = r + n;
	unsigned char* b = g + n;
	unsigned char* a = b + n;

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		R (dst, x, y) = *r ++;
		G (dst, x, y) = *g ++;
		B (dst, x, y) = *b ++;
		A (dst, x, y) = *a ++;
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int r, g, b, a;

	for (y = h-1, r = 0, g = h, b = g+h, a = b+h;
	     y >= 0;
	     y--, r++, g++, b++, a++) {

	    TRACE (("SGI PIX DATA %8d R", y));
	    if (!decode_rle (buf, &R (dst, 0, y), 4, w, os[r], ol[r])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d G", y));
	    if (!decode_rle (buf, &G (dst, 0, y), 4, w, os[g], ol[g])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d B", y));
	    if (!decode_rle (buf, &B (dst, 0, y), 4, w, os[b], ol[b])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d A", y));
	    if (!decode_rle (buf, &A (dst, 0, y), 4, w, os[a], ol[a])) {
		return 0;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX RGBA ="));
	    for (x=0;x<w;x++) {
		TRACE ((" (%d, %d, %d, %d)", R(dst,x,y), G(dst,x,y), B(dst,x,y), A(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }
}

static int
decode_rgba_short (sgi_info* info, crimp_buffer* buf, crimp_image* dst)
{
    int x, y, w, h;
    CRIMP_ASSERT_IMGTYPE (dst, rgba);
    TRACE (("SGI RGBA /SHORT\n"));

    w = info->w;
    h = info->h;

    if (info->storage == sgi_storage_verbatim) {
	int            n = w * h * sizeof (short);
	unsigned char* r = crimp_buf_at (buf);
	unsigned char* g = r + n;
	unsigned char* b = g + n;
	unsigned char* a = b + n;

	for (y = h-1; y >= 0; y--) {
	    for (x=0; x < w; x++) {
		/* Read only MSB, skip LSB */
		R (dst, x, y) = *r; r += 2;
		G (dst, x, y) = *g; g += 2;
		B (dst, x, y) = *b; b += 2;
		A (dst, x, y) = *a; a += 2;
	    }
	}
    } else {
	unsigned long* os = info->ostart;
	unsigned long* ol = info->olength;
	int r, g, b, a;

	for (y = h-1, r = 0, g = h, b = g+h, a = b+h;
	     y >= 0;
	     y--, r++, g++, b++, a++) {

	    TRACE (("SGI PIX DATA %8d R", y));
	    if (!decode_rle_short (buf, &R (dst, 0, y), 4, w, os[r], ol[r])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d G", y));
	    if (!decode_rle_short (buf, &G (dst, 0, y), 4, w, os[g], ol[g])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d B", y));
	    if (!decode_rle_short (buf, &B (dst, 0, y), 4, w, os[b], ol[b])) {
		return 0;
	    }

	    TRACE (("SGI PIX DATA %8d A", y));
	    if (!decode_rle_short (buf, &A (dst, 0, y), 4, w, os[a], ol[a])) {
		return 0;
	    }

#ifdef SGI_TRACE
	    TRACE (("SGI PIX RGBA ="));
	    for (x=0;x<w;x++) {
		TRACE ((" (%d, %d, %d, %d)", R(dst,x,y), G(dst,x,y), B(dst,x,y), A(dst,x,y)));
	    }
	    TRACE (("\n"));
#endif
	}
    }
}

static int
decode_rle (crimp_buffer* buf,
	    unsigned char* dst, int delta, int n,
	    int start, int length)
{
    int value, count, done = 0;
    unsigned char* src;

    TRACE ((" RLE (%d,%d): ", start, length));

    crimp_buf_moveto (buf, start);
    src = crimp_buf_at (buf);

    while (n >= 0) {
	value = *src ++;
	count = value & 0x7f;

	TRACE ((" %d -> %d", value, count));

	if (!count) {
	    TRACE ((" EOL"));
	    /* RLE packet type C - end of scanline */
	    done = 1;
	    break;
	}

	if (value & 0x80) {
	    /* RLE packet type A - literal pixels to copy */
	    TRACE (("=("));
	    while (count--) {
		if (!n) goto error;

		value = *src ++;
		TRACE ((" %d",value));
		*dst = value;
		dst += delta;
		n--;
	    }
	    TRACE ((")"));

	} else {
	    /* RLE packet type B - replicate next */
	    value = *src ++;
	    TRACE (("x(%d)",value));
	    while (count--) {
		if (!n) goto error;
		*dst = value;
		dst += delta;
		n--;
	    }
	}
    }

    TRACE (("\n"));

    if (!done) {
    error:
	TRACE (("SGI RLE rle/scanline mismatch"));
	return 0;
    }

    return 1;
}


static int
decode_rle_short (crimp_buffer* buf,
		  unsigned char* dst, int delta, int n,
		  int start, int length)
{
    int value, count, done = 0;
    unsigned short* src;

    TRACE ((" RLE SHORT (%d,%d): ", start, length));

    crimp_buf_moveto (buf, start);
    src = (unsigned short*) crimp_buf_at (buf);

    while (n >= 0) {
	value = *src ++;
	count = value & 0x007f;

	TRACE ((" %d -> %d", value, count));

	if (!count) {
	    TRACE ((" EOL"));
	    /* RLE packet type C - end of scanline */
	    done = 1;
	    break;
	}

	if (value & 0x0080) {
	    /* RLE packet type A - literal pixels to copy */
	    TRACE (("=("));
	    while (count--) {
		if (!n) goto error;

		value = (*src ++) >> 8; /* Restrict to MSB */
		TRACE ((" %d",value));
		*dst = value;
		dst += delta;
		n--;
	    }
	    TRACE ((")"));

	} else {
	    /* RLE packet type B - replicate next */
	    value = (*src ++) >> 8; /* Restrict to MSB */
	    TRACE (("x(%d)",value));
	    while (count--) {
		if (!n) goto error;
		*dst = value;
		dst += delta;
		n--;
	    }
	}
    }

    TRACE (("\n"));

    if (!done) {
    error:
	TRACE (("SGI RLE rle/scanline mismatch"));
	return 0;
    }

    return 1;
}

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
