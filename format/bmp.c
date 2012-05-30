/*
 * CRIMP :: BMP functions Definitions (Implementation).
 * Reference
 *	http://en.wikipedia.org/wiki/BMP_file_format
 *	http://msdn.microsoft.com/en-us/library/dd183376
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include "bmp.h"

static int decode_2   (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static int decode_4   (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static int decode_16  (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static int decode_256 (bmp_info* info, crimp_buffer* buf, crimp_image* destination);
static int decode_rgb (bmp_info* info, crimp_buffer* buf, crimp_image* destination);

static int decode_pack16 (bmp_info* info, bmp_maskinfo* mi, crimp_buffer* buf, crimp_image* destination);
static int decode_pack32 (bmp_info* info, bmp_maskinfo* mi, crimp_buffer* buf, crimp_image* destination);

static void map_color (unsigned char* colorMap, int entrySize, int index, unsigned char* pix);

static void define_mask (bmp_maskinfo* mi, unsigned int mask);

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
bmp_read_header (Tcl_Interp*     interp,
		 crimp_buffer*   buf,
		 bmp_info*       info)
{
    unsigned long  fsize, pixOffset, c, w, compression, nPix, nColors;
    unsigned int   nMap, nBits, wi;
    int            h;
    int            topdown = 0; /* bottom-up storage, default */
    unsigned char* colorMap = 0;

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
	Tcl_SetResult (interp, "Not a BMP image", TCL_STATIC);
	return 0;
    }

    crimp_buf_read_uint32le (buf, &fsize);             /* BMP file size */
    crimp_buf_skip          (buf, 4);                  /* reserved */
    crimp_buf_read_uint32le (buf, &pixOffset);         /* offset to pixel data */

    /*
     * Check the internal consistency of the data retrieved so far
     */

    if (crimp_buf_size (buf) != fsize) {
	Tcl_SetResult (interp, "Bad BMP image (File size mismatch)", TCL_STATIC);
	return 0;
    } else if (!crimp_buf_check (buf, pixOffset)) {
	Tcl_SetResult (interp, "Bad BMP image (Bad pixel offset, out of range)", TCL_STATIC);
	return 0;
    } else if (pixOffset % 2 != 0) {
	Tcl_SetResult (interp, "Bad BMP image (Bad pixel offset, not word-aligned)", TCL_STATIC);
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
	Tcl_SetResult (interp, "Bad BMP image (Not enough space for header size)", TCL_STATIC);
	return 0;
    }
    crimp_buf_read_uint32le (buf, &c);     /* DIB header size */
    if (!crimp_buf_has      (buf, c-4)) {  /* Space for remaining DIB Header */
	Tcl_SetResult (interp, "Bad BMP image (Not enough space for header)", TCL_STATIC);
	return 0;
    }

    switch (c) {
    case 12:
	/*
	 * OS21XBITMAPHEADER. The old OS/2 header.
	 *
	 * 18..19 | 2 : Image width
	 * 20..21 | 2 : Image height
	 * 22..23 | 2 : Num Planes
	 * 24..24 | 2 : BitCount
	 * -------+---:-------------------
	 *          8 bytes + 4 byte size = 12
	 */

	crimp_buf_read_uint16le (buf, &wi);          /* width */
	crimp_buf_read_int16le  (buf, &h);           /* height */
	crimp_buf_skip          (buf, 2);            /* IGNORE planes */
	crimp_buf_read_uint16le (buf, &nBits);       /* bit count */
	w = wi;

	compression = bc_rgb;
	nColors     = 0;
	nMap        = 3;
	nPix        = 0;

	if ((nBits == 16) ||
	    (nBits == 32)) {
	    Tcl_SetResult (interp, "Bad BMP image (Invalid bpp for OS/2, packed RGB not supported)", TCL_STATIC);
	    return 0;
	}

	pixOffset = crimp_buf_tell (buf) +
	    nMap * (1 << nBits);

	break;
    case 64:
	/*
	 * BITMAPCORE2HEADER.
	 * An extension of the BITMAPINFOHEADER.
	 * Falling through.
	 */
    case 40:
	/*
	 * BITMAPINFOHEADER, aka DIB Header
	 * The most common variant, 40 byte long.
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
	 * -------+---:-------------------
	 *         36 bytes + 4 byte size = 40
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

	nMap = 4;
	break;

    default:
	TRACE (("DIB Header %u",c));
	Tcl_SetResult (interp, "Unsupported BMP DIB image header", TCL_STATIC);
	return 0;
    }

    /*
     * - BitCount
     *   1 : 2 Colors.   Bit unset => Color 0, Bit set => color 1.
     *   2 : 4 Colors.
     *   4 : 16 Colors.   Compressible (RLE4).
     *   8 : 256 Colors.  Compressible (RLE8).
     *  24 : RGB storage, no color table.
     *  -- - ----------------------------------------------
     *  16 : Packed RGB storage, no color table, have channel bitmasks
     *  32 : instead. For bc_rgb the masks are fixed, otherwise (bc_bitfield)
     *       they are stored in place of the color map.
     * -- - ----------------------------------------------
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
	 * Indexed pixel formats.
	 */
	if (!nColors) {
	    nColors = 1 << nBits;
	} else if (nColors > (1 << nBits)) {
	    Tcl_SetResult (interp, "Bad BMP image (color/bits mismatch)", TCL_STATIC);
	    return 0;
	}

	colorMap = crimp_buf_at (buf);
	break;
    case 16:
    case 32:
	/*
	 * Packed RGB formats use the colorMap pointer to communicate the
	 * channel masks, although if and only if bitfield compression is
	 * specified.
	 */
	if (compression == bc_bitfield) {
	    colorMap = crimp_buf_at (buf);
	}
    case 24:
	/*
	 * RGB formats, packed (16, 32) and unpacked (24).
	 */
	if (nColors) {
	    Tcl_SetResult (interp, "Bad BMP image (color/RGB mismatch)", TCL_STATIC);
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
	    Tcl_SetResult (interp, "Unsupported BMP image compression method", TCL_STATIC);
	    return 0;
	}
	if (((compression != bc_rle4)     && (nBits == 4)) ||
	    ((compression != bc_rle8)     && (nBits == 8)) ||
	    ((compression != bc_bitfield) && ((nBits == 16) || (nBits == 32)))) {
	    Tcl_SetResult (interp, "Bad BMP image (bits/compression mismatch)", TCL_STATIC);
	    return 0;
	}
    }

    /*
     * Pixel data is normally stored bottom up, i.e. bottom line first. A
     * negative image height (<0) indicates that the lines are stored
     * top-down instead. Top-down images cannot be compressed.
     */

    if (h < 0) {
	if ((compression != bc_rgb) &&
	    (compression != bc_bitfield)) {
	    Tcl_SetResult (interp, "Bad BMP image (height/compression mismatch)", TCL_STATIC);
	    return 0;
	}

	h       = -h;
	topdown = 1;
    }

    /* ASSERT h >= 0; */

    if (!nPix) {
	/*
	 * Derive the size of the pixel data array from the dimensions and
	 * bits/pixel. We cannot do this if one of the RLEx compression
	 * methods is specified.
	 */

	int rlength;
	if ((compression == bc_rle4) ||
	    (compression == bc_rle8)) {
	    Tcl_SetResult (interp, "Bad BMP image (compression/pixel data mismatch)", TCL_STATIC);
	    return 0;
	}

	/*
	 * rowLength = ceil ((nBits*width)/32) * 4;
	 * nPix = height * rowLength;
	 */

	rlength = (nBits * w) /32;
	if (rlength % 4 != 0) { rlength += 4 - (rlength % 4); }
	nPix = h * rlength * 4;
    }


    /*
     * Jump to the pixel data for the decoder.
     */

    crimp_buf_moveto (buf, pixOffset);
    if (!crimp_buf_has (buf, nPix)) {
	Tcl_SetResult (interp, "Bad BMP image (Not enough space for pixel data)", TCL_STATIC);
	return 0;
    }

    /*
     * Save results for caller.
     */

    info->w             = w;
    info->h             = h;
    info->colorMap      = colorMap;
    info->mapEntrySize  = nMap;
    info->numBits       = nBits;
    info->numColors     = nColors;
    info->mode          = compression;
    info->topdown       = topdown;
    info->numPixelBytes = nPix;
    info->input         = buf;

    return 1;
}

int
bmp_read_pixels (bmp_info*      info,
		 crimp_image*   destination)
{
    crimp_buffer* buf = info->input;
    bmp_maskinfo mi [3];

    CRIMP_ASSERT_IMGTYPE (destination, rgb);
    CRIMP_ASSERT ((info->w == crimp_w (destination)) &&
		  (info->h == crimp_h (destination)), "Dimension mismatch");

    /*
     * We assume that:
     * - The buffer is positioned at the start of the pixel data.
     * - nBits and compression mode match.
     *
     * 'bmp_read_header', see above, ensures these conditions.
     */

    if (!crimp_buf_has (buf, info->numPixelBytes)) {
	return 0;
    }

    switch (info->numBits) {
    case 1:
	CRIMP_ASSERT (info->colorMap,       "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 2, "Too many colors");

	return decode_2 (info, buf, destination);
	break;
    case 2:
	CRIMP_ASSERT (info->colorMap,       "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 4, "Too many colors");

	return decode_4 (info, buf, destination);
	break;
    case 4:
	CRIMP_ASSERT (info->colorMap,        "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 16, "Too many colors");

	return decode_16 (info, buf, destination);
	break;
    case 8:
	CRIMP_ASSERT (info->colorMap,         "Expected colorMap for pixel-packed BMP");
	CRIMP_ASSERT (info->numColors <= 256, "Too many colors");

	return decode_256 (info, buf, destination);
	break;
    case 24:
	CRIMP_ASSERT (!info->colorMap,"");

	return decode_rgb (info, buf, destination);
	break;

    case 16:
	if (info->mode == bc_bitfield) {
	    /* Stored masks
	     */
	    unsigned int* masks;
	    CRIMP_ASSERT (info->colorMap,"colormap is channel masks");
	    masks = (unsigned int*) info->colorMap;
	    define_mask (&mi[0], masks[0]); /* Red   */
	    define_mask (&mi[1], masks[1]); /* Green */
	    define_mask (&mi[2], masks[2]); /* Blue  */
	} else {
	    /* Fixed masks (5-5-5, 1 bit wasted)
	     */
	    CRIMP_ASSERT (!info->colorMap,"");
	    define_mask (&mi[0], 0x7c00); /* Red   */
	    define_mask (&mi[1], 0x03e0); /* Green */
	    define_mask (&mi[2], 0x001f); /* Blue  */
	}
	return decode_pack16 (info, mi, buf, destination);
	break;
    case 32:
	if (info->mode == bc_bitfield) {
	    /* Stored masks
	     */
	    unsigned int* masks;
	    CRIMP_ASSERT (info->colorMap,"colormap is channel masks");
	    masks = (unsigned int*) info->colorMap;
	    define_mask (&mi[0], masks[0]); /* Red   */
	    define_mask (&mi[1], masks[1]); /* Green */
	    define_mask (&mi[2], masks[2]); /* Blue  */
	} else {
	    /* Fixed masks (8-8-8, 8 bit wasted)
	     */
	    CRIMP_ASSERT (!info->colorMap,"");
	    define_mask (&mi[0], 0x00ff0000); /* Red   */
	    define_mask (&mi[1], 0x0000ff00); /* Green */
	    define_mask (&mi[2], 0x000000ff); /* Blue  */
	}
	return decode_pack32 (info, mi, buf, destination);
	break;

    default:
	CRIMP_ASSERT (0,"Unsupported number of bits/pixel");
    }

    CRIMP_ASSERT(0,"Not reached");
    return 0;
}

#define CHECK_SPACE(n)				\
    if (!crimp_buf_has (buf, (n))) { return 0; }

#define CHECK_INDEX(v) \
    if (info->numColors < (v)) { return 0; }

#define GET_INDEX(v)			\
    CHECK_SPACE (1);			\
    crimp_buf_read_uint8 (buf, &(v));

#define GET_CHECK_INDEX(v)	\
    GET_INDEX   (v);		\
    CHECK_INDEX (v);

#define NEXTX \
    x++ ; if (info->w <= x) break

#define MAP(v) \
    if ((x < 0) || (x >= info->w)) { return 0; } \
    if ((y < 0) || (y >= info->h)) { return 0; } \
    map_color (info->colorMap, info->mapEntrySize, (v), &R (destination, x, y))

static int
decode_2 (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Indexed data at 8 pixel/byte (Each pixel is 1 bit). Left to right is
     * MSB to LSB. Each scan-line is 4-aligned relative to its start. For each
     * octet we make sure that we have not run over the buffer-end, and for
     * each pixel that the color index found is within the limits declared by
     * the bitmap header.
     */

    int x, y;
    unsigned int v, va, vb, vc, vd, ve, vf, vg, vh;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 1, "Bad format");

    if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0x80) >> 7;
		CHECK_INDEX (va);
		MAP (va);
		NEXTX;

		vb  = (v & 0x40) >> 6;
		CHECK_INDEX (vb);
		MAP (vb);
		NEXTX;

		vc  = (v & 0x20) >> 5;
		CHECK_INDEX (vc);
		MAP (vc);
		NEXTX;

		vd  = (v & 0x10) >> 4;
		CHECK_INDEX (vd);
		MAP (vd);
		NEXTX;

		ve  = (v & 0x08) >> 3;
		CHECK_INDEX (ve);
		MAP (ve);
		NEXTX;

		vf  = (v & 0x04) >> 2;
		CHECK_INDEX (vf);
		MAP (vf);
		NEXTX;

		vg  = (v & 0x02) >> 1;
		CHECK_INDEX (vg);
		MAP (vg);
		NEXTX;

		vh  = (v & 0x01);
		CHECK_INDEX (vh);
		MAP (vh);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0x80) >> 7;
		CHECK_INDEX (va);
		MAP (va);
		NEXTX;

		vb  = (v & 0x40) >> 6;
		CHECK_INDEX (vb);
		MAP (vb);
		NEXTX;

		vc  = (v & 0x20) >> 5;
		CHECK_INDEX (vc);
		MAP (vc);
		NEXTX;

		vd  = (v & 0x10) >> 4;
		CHECK_INDEX (vd);
		MAP (vd);
		NEXTX;

		ve  = (v & 0x08) >> 3;
		CHECK_INDEX (ve);
		MAP (ve);
		NEXTX;

		vf  = (v & 0x04) >> 2;
		CHECK_INDEX (vf);
		MAP (vf);
		NEXTX;

		vg  = (v & 0x02) >> 1;
		CHECK_INDEX (vg);
		MAP (vg);
		NEXTX;

		vh  = (v & 0x01);
		CHECK_INDEX (vh);
		MAP (vh);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
}

static int
decode_4 (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Indexed data at 4 pixel/byte (Each pixel is 2 bits). Left to right is
     * MSB to LSB. Each scan-line is 4-aligned relative to its start. For each
     * quad-pixel we make sure that we have not run over the buffer-end, and
     * for each pixel that the color index found is within the limits declared
     * by the bitmap header.
     */

    int x, y;
    unsigned int v, va, vb, vc, vd;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 2, "Bad format");

    if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0xC0) >> 6;
		CHECK_INDEX (va);
		MAP (va);
		NEXTX;

		vb  = (v & 0x30) >> 4;
		CHECK_INDEX (vb);
		MAP (vb);
		NEXTX;

		vc  = (v & 0x0C) >> 2;
		CHECK_INDEX (vc);
		MAP (vc);
		NEXTX;

		vd  = (v & 0x03);
		CHECK_INDEX (vd);
		MAP (vd);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0xC0) >> 6;
		CHECK_INDEX (va);
		MAP (va);
		NEXTX;

		vb  = (v & 0x30) >> 4;
		CHECK_INDEX (vb);
		MAP (vb);
		NEXTX;

		vc  = (v & 0x0C) >> 2;
		CHECK_INDEX (vc);
		MAP (vc);
		NEXTX;

		vd  = (v & 0x03);
		CHECK_INDEX (vd);
		MAP (vd);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
}

static int
decode_16 (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Indexed data at 2 pixel/byte (Each pixel is 4 bits). Left to right is
     * MSB to LSB. For each double-pixel we make sure that we have not run
     * over the buffer-end, and for each pixel that the color index found is
     * within the limits declared by the bitmap header.
     *
     * May be compressed using RLE4 encoding.
     */

    int x, y;
    unsigned int l, v, va, vb;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 4, "Bad format");

    if (info->mode) {
	int stop = 0;

	CRIMP_ASSERT (info->mode == bc_rle4, "Bad format");

	/*
	 * Run-length encoded pixel data. The data is essentially instructions
	 * for a small virtual machine to set pixels.
	 */

	x = 0;
	y = info->h - 1;

	TRACE (("RLE4 Base  %d\n",base));
	TRACE (("RLE4 Stop  %d\n",crimp_buf_tell(buf)));
	TRACE (("RLE4 Delta %d\n",crimp_buf_tell(buf) - base));
	TRACE (("RLE4 Size  %u\n",info->numPixelBytes));
	TRACE (("RLE4 @ (  x   y)\n"));

	while (!stop && ((crimp_buf_tell(buf) - base) < info->numPixelBytes)) {
	    CHECK_SPACE (2);
	    crimp_buf_read_uint8 (buf, &l);

	    TRACE (("RLE4 @ (%3d %3d) /%3u ", x, y, l));

	    switch (l) {
	    case 0:
		/* Escape clause.
		 */
		crimp_buf_read_uint8 (buf, &v);
		switch (v) {
		case 0: /* End of line */
		    TRACE (("/%3u EOL\n", v));
		    x = 0;
		    y --;
		    break;
		case 1: /* End of bitmap */
		    TRACE (("/%3u EOB\n", v));
		    stop = 1;
		    break;
		case 2: /* Jump */
		    TRACE (("/%3u JUMP ",v));
		    CHECK_SPACE (2);
		    crimp_buf_read_uint8 (buf, &l); x += l;
		    crimp_buf_read_uint8 (buf, &v); y -= v; /* bottom-up! */
		    TRACE (("(dx %u dy %u)\n",l, v));
		    break;
		default:
		    /*
		     * Absolute mode: 3-255. l = length of pixel
		     * sequence. Convert that many indices. Such runs do not
		     * extend beyond the end of the current scan line. If a
		     * run does, it is an error. Changing to the next line is
		     * done with the EOL escape.
		     */
		    TRACE (("/%3u ",l));
		    l = v;
		    TRACE (("ABS %u : ",l));
		    while (l) {
			GET_INDEX (v);

			va = (v & 0xF0) >> 4;
			TRACE (("%u ",va));
			CHECK_INDEX (va);
			MAP (va);

			l --;
			x ++;

			if (!l) break;

			vb = (v & 0x0F);
			TRACE (("%u ",vb));
			CHECK_INDEX (vb);
			MAP (vb);

			l --;
			x ++;
		    }
		    TRACE (("\n"));
		    crimp_buf_alignr (buf, base, 2);
		    break;
		}
		break;
	    default:
		/*
		 * Run-code. l = length of run. Get index to map and store
		 * this many times. Such runs do not extend beyond the end of
		 * the current scan line. If a run does, it is an
		 * error. Changing to the next line is done with the EOL
		 * escape.
		 */
		crimp_buf_read_uint8 (buf, &v);

		TRACE (("/%3u RUN %u %u = ", v, l, v));

		va = (v & 0xF0) >> 4;	CHECK_INDEX (va);
		vb = (v & 0x0F);	CHECK_INDEX (vb);

		TRACE (("%u %u ", va, vb));

		while (l) {
		    TRACE (("a"));
		    MAP (va);

		    l --;
		    x ++;

		    if (!l) break;

		    TRACE (("b"));
		    MAP (vb);

		    l --;
		    x ++;
		}
		TRACE (("\n"));
		break;
	    }
	}

	if ((crimp_buf_tell(buf) - base) != info->numPixelBytes) {
	    TRACE (("RLE4 Base  %d\n",base));
	    TRACE (("RLE4 Stop  %d\n",crimp_buf_tell(buf)));
	    TRACE (("RLE4 Delta %d\n",crimp_buf_tell(buf) - base));
	    TRACE (("RLE4 Size  %u\n",info->numPixelBytes));
	    return 0;
	}
    } else if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */

	CRIMP_ASSERT (info->mode == bc_rgb, "Bad format");
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0xF0) >> 4;
		CHECK_INDEX (va);
		MAP (va);

		NEXTX;

		vb = (v & 0x0F);
		CHECK_INDEX (vb);
		MAP (vb);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */

	CRIMP_ASSERT (info->mode == bc_rgb, "Bad format");
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0xF0) >> 4;
		CHECK_INDEX (va);
		MAP (va);

		NEXTX;

		vb = (v & 0x0F);
		CHECK_INDEX (vb);
		MAP (vb);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    TRACE (("OK"));
    return 1;
}

static int
decode_256 (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Indexed data at 1 byte/pixel. For each pixel we make sure that we have
     * not run over the buffer-end, and that the color index found is within
     * the limits declared by the bitmap header.
     *
     * May be compressed using RLE8 encoding.
     */

    int x, y;
    unsigned int v, l;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 8, "Bad format");

    if (info->mode) {
	int stop = 0;

	CRIMP_ASSERT (info->mode == bc_rle8, "Bad format");

	/*
	 * Run-length encoded pixel data. The data is essentially instructions
	 * for a small virtual machine to set pixels.
	 */

	x = 0;
	y = info->h - 1;

	TRACE (("RLE8 Base  %d\n",base));
	TRACE (("RLE8 Stop  %d\n",crimp_buf_tell(buf)));
	TRACE (("RLE8 Delta %d\n",crimp_buf_tell(buf) - base));
	TRACE (("RLE8 Size  %u\n",info->numPixelBytes));
	TRACE (("RLE8 @ (  x   y)\n"));

	while (!stop && ((crimp_buf_tell(buf) - base) < info->numPixelBytes)) {
	    CHECK_SPACE (2);
	    crimp_buf_read_uint8 (buf, &l);

	    TRACE (("RLE8 @ (%3d %3d) /%3u ",x,y,l));

	    switch (l) {
	    case 0:
		/* Escape clause.
		 */
		crimp_buf_read_uint8 (buf, &v);
		switch (v) {
		case 0: /* End of line */
		    TRACE (("/%3u EOL\n",v));
		    x = 0;
		    y --;
		    break;
		case 1: /* End of bitmap */
		    TRACE (("/%3u EOB\n",v));
		    stop = 1;
		    break;
		case 2: /* Jump */
		    TRACE (("/%3u JUMP ",v));
		    CHECK_SPACE (2);
		    crimp_buf_read_uint8 (buf, &l); x += l;
		    crimp_buf_read_uint8 (buf, &v); y -= v; /* bottom-up! */
		    TRACE (("(dx %u dy %u)\n",l, v));
		    break;
		default:
		    /*
		     * Absolute mode: 3-255. l = length of pixel
		     * sequence. Convert that many indices. Such runs do not
		     * extend beyond the end of the current scan line. If a
		     * run does, it is an error. Changing to the next line is
		     * done with the EOL escape.
		     */
		    l = v;
		    TRACE (("/%3u ABS %u : ",v,l));
		    while (l) {
			GET_CHECK_INDEX (v);
			TRACE (("%u ",v));
			MAP (v);
			l --;
			x ++;
		    }
		    TRACE (("\n"));
		    crimp_buf_alignr (buf, base, 2);
		    break;
		}
		break;
	    default:
		/*
		 * Run-code. l = length of run. Get the index to map and store
		 * it this many times. Such runs do not extend beyond the end
		 * of the current scan line. If a run does, it is an
		 * error. Changing to the next line is done with the EOL
		 * escape.
		 */
		crimp_buf_read_uint8 (buf, &v);
		TRACE (("/%3u RUN %u %u ",v,l,v));
		CHECK_INDEX (v);
		while (l) {
		    TRACE (("."));
		    MAP (v);

		    l --;
		    x ++;
		}
		TRACE (("\n"));
		break;
	    }
	}

	if ((crimp_buf_tell(buf) - base) != info->numPixelBytes) {
	    TRACE (("RLE8 Base  %d\n",base));
	    TRACE (("RLE8 Stop  %d\n",crimp_buf_tell(buf)));
	    TRACE (("RLE8 Delta %d\n",crimp_buf_tell(buf) - base));
	    TRACE (("RLE8 Size  %u\n",info->numPixelBytes));
	    return 0;
	}
    } else if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */

	CRIMP_ASSERT (info->mode == bc_rgb, "Bad format");
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		GET_CHECK_INDEX (v);
		MAP (v);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */

	CRIMP_ASSERT (info->mode == bc_rgb, "Bad format");
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		GET_CHECK_INDEX (v);
		MAP (v);
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
}

static int
decode_rgb (bmp_info* info, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Uncompressed RGB data. Each pixel is represented by 3 bytes holding
     * red, green, and blue, in this order. Each scan-line is 4-aligned.
     */

    int x, y;
    unsigned int v;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 24, "Bad format");

    if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		CHECK_SPACE (3);

		crimp_buf_read_uint8 (buf, &v);  B (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  G (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  R (destination, x, y) = v;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		CHECK_SPACE (3);

		crimp_buf_read_uint8 (buf, &v);  B (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  G (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  R (destination, x, y) = v;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
}

static int
decode_pack16 (bmp_info* info, bmp_maskinfo* mi, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Packed RGB data. Each pixel is represented by 2 bytes. The channel
     * values are extracted using the specified masks. Each scan-line is
     * 4-aligned.
     */

    int x, y;
    unsigned int v;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 16, "Bad format");

    TRACE(("Pack16 MASK R %x >> %d << %d\n",mi[0].mask, mi[0].shiftin, mi[0].shiftout));
    TRACE(("Pack16 MASK G %x >> %d << %d\n",mi[1].mask, mi[1].shiftin, mi[1].shiftout));
    TRACE(("Pack16 MASK B %x >> %d << %d\n",mi[2].mask, mi[2].shiftin, mi[2].shiftout));

    if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		CHECK_SPACE (2);
		crimp_buf_read_uint16le (buf, &v);

		R (destination, x, y) = ((v & mi[0].mask) >> mi[0].shiftin) << mi[0].shiftout;
		G (destination, x, y) = ((v & mi[1].mask) >> mi[1].shiftin) << mi[1].shiftout;
		B (destination, x, y) = ((v & mi[2].mask) >> mi[2].shiftin) << mi[2].shiftout;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		CHECK_SPACE (2);
		crimp_buf_read_uint16le (buf, &v);

		R (destination, x, y) = ((v & mi[0].mask) >> mi[0].shiftin) << mi[0].shiftout;
		G (destination, x, y) = ((v & mi[1].mask) >> mi[1].shiftin) << mi[1].shiftout;
		B (destination, x, y) = ((v & mi[2].mask) >> mi[2].shiftin) << mi[2].shiftout;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
}

static int
decode_pack32 (bmp_info* info, bmp_maskinfo* mi, crimp_buffer* buf, crimp_image* destination)
{
    /*
     * Packed RGB data. Each pixel is represented by 4 bytes. The channel
     * values are extracted using the specified masks. Each scan-line is
     * 4-aligned.
     */

    int x, y;
    unsigned long v;
    int base = crimp_buf_tell (buf);

    CRIMP_ASSERT (info->numBits == 32, "Bad format");

    TRACE(("Pack32 MASK R %x >> %d << %d\n",mi[0].mask, mi[0].shiftin, mi[0].shiftout));
    TRACE(("Pack32 MASK G %x >> %d << %d\n",mi[1].mask, mi[1].shiftin, mi[1].shiftout));
    TRACE(("Pack32 MASK B %x >> %d << %d\n",mi[2].mask, mi[2].shiftin, mi[2].shiftout));

    if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		CHECK_SPACE (2);
		crimp_buf_read_uint32le (buf, &v);

		R (destination, x, y) = ((v & mi[0].mask) >> mi[0].shiftin) << mi[0].shiftout;
		G (destination, x, y) = ((v & mi[1].mask) >> mi[1].shiftin) << mi[1].shiftout;
		B (destination, x, y) = ((v & mi[2].mask) >> mi[2].shiftin) << mi[2].shiftout;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    } else {
	/*
	 * Store the scan-lines from the bottom up (default, regular)
	 */
	for (y = info->h - 1; y >= 0; y--) {
	    for (x = 0; x < info->w; x++) {
		CHECK_SPACE (2);
		crimp_buf_read_uint32le (buf, &v);

		R (destination, x, y) = ((v & mi[0].mask) >> mi[0].shiftin) << mi[0].shiftout;
		G (destination, x, y) = ((v & mi[1].mask) >> mi[1].shiftin) << mi[1].shiftout;
		B (destination, x, y) = ((v & mi[2].mask) >> mi[2].shiftin) << mi[2].shiftout;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
}

static void
map_color (unsigned char* colorMap, int entrySize, int index, unsigned char* pix)
{
    /*
     * Note how:
     * - Each colorMap entry is 4 bytes, with one byte ignored.
     * - The pixel uses RGB order for the bytes, whereas the colorMap uses BGR
     *   (inverted).
     */

    index *= entrySize;

    pix [0] = colorMap [index + 2]; /* Red */
    pix [1] = colorMap [index + 1]; /* Green */
    pix [2] = colorMap [index + 0]; /* Blue */
}

static void
define_mask (bmp_maskinfo* mi, unsigned int mask)
{
    int nbits, offset, bit;

    /* Save the mask first ... */

    mi->mask = mask;

    /* ... then compute the shift values needed to extract from or write to
     * the packed color channel.
     */

    nbits  = 0;
    offset = -1;

    for (bit = 0; bit < 32; bit++) {
	if (mask & 1) {
	    nbits++;
	    if (offset == -1) {
		offset = bit;
	    }
	}
	mask = mask >> 1;
    }

    mi->shiftin  = offset;
    mi->shiftout = 8 - nbits;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
