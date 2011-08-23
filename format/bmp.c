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

    if ((crimp_buf_size (buf) != fsize) ||
	(pixOffset % 2 != 0) ||
	!crimp_buf_check (buf, pixOffset)) {

	Tcl_SetResult (interp, "Bad BMP image (Invalid pixel data location)", TCL_STATIC);
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
	 *   2 : 4 Colors.
	 *   4 : 16 Colors.   Compressible (RLE4).
	 *   8 : 256 Colors.  Compressible (RLE8).
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
	     * Packed RGB formats, currently not supported. TODO.
	     */
	    Tcl_SetResult (interp, "Packed RGB BMP image not supported", TCL_STATIC);
	    return 0;
	case 24:
	    /*
	     * RGB formats.
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

	break;

    default:
	Tcl_SetResult (interp, "Unsupported BMP DIB image header", TCL_STATIC);
	return 0;
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

    CRIMP_ASSERT (info->numBits == 2, "Bad format");

    if (info->topdown) {
	/*
	 * Store the scan-lines from the top down.
	 */
	for (y = 0; y < info->h; y++) {
	    for (x = 0; x < info->w; x++) {
		GET_INDEX (v);

		va  = (v & 0x80) >> 7;
		CHECK_INDEX (va);
		map_color (info->colorMap, va, &R (destination, x, y));
		NEXTX;

		vb  = (v & 0x40) >> 6;
		CHECK_INDEX (vb);
		map_color (info->colorMap, vb, &R (destination, x, y));
		NEXTX;

		vc  = (v & 0x20) >> 5;
		CHECK_INDEX (vc);
		map_color (info->colorMap, vc, &R (destination, x, y));
		NEXTX;

		vd  = (v & 0x10) >> 4;
		CHECK_INDEX (vd);
		map_color (info->colorMap, vd, &R (destination, x, y));
		NEXTX;

		ve  = (v & 0x08) >> 3;
		CHECK_INDEX (ve);
		map_color (info->colorMap, ve, &R (destination, x, y));
		NEXTX;

		vf  = (v & 0x04) >> 2;
		CHECK_INDEX (vf);
		map_color (info->colorMap, vf, &R (destination, x, y));
		NEXTX;

		vg  = (v & 0x02) >> 1;
		CHECK_INDEX (vg);
		map_color (info->colorMap, vg, &R (destination, x, y));
		NEXTX;

		vh  = (v & 0x01);
		CHECK_INDEX (vh);
		map_color (info->colorMap, vh, &R (destination, x, y));
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
		map_color (info->colorMap, va, &R (destination, x, y));
		NEXTX;

		vb  = (v & 0x40) >> 6;
		CHECK_INDEX (vb);
		map_color (info->colorMap, vb, &R (destination, x, y));
		NEXTX;

		vc  = (v & 0x20) >> 5;
		CHECK_INDEX (vc);
		map_color (info->colorMap, vc, &R (destination, x, y));
		NEXTX;

		vd  = (v & 0x10) >> 4;
		CHECK_INDEX (vd);
		map_color (info->colorMap, vd, &R (destination, x, y));
		NEXTX;

		ve  = (v & 0x08) >> 3;
		CHECK_INDEX (ve);
		map_color (info->colorMap, ve, &R (destination, x, y));
		NEXTX;

		vf  = (v & 0x04) >> 2;
		CHECK_INDEX (vf);
		map_color (info->colorMap, vf, &R (destination, x, y));
		NEXTX;

		vg  = (v & 0x02) >> 1;
		CHECK_INDEX (vg);
		map_color (info->colorMap, vg, &R (destination, x, y));
		NEXTX;

		vh  = (v & 0x01);
		CHECK_INDEX (vh);
		map_color (info->colorMap, vh, &R (destination, x, y));
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
		map_color (info->colorMap, va, &R (destination, x, y));
		NEXTX;

		vb  = (v & 0x30) >> 4;
		CHECK_INDEX (vb);
		map_color (info->colorMap, vb, &R (destination, x, y));
		NEXTX;

		vc  = (v & 0x0C) >> 2;
		CHECK_INDEX (vc);
		map_color (info->colorMap, vc, &R (destination, x, y));
		NEXTX;

		vd  = (v & 0x03);
		CHECK_INDEX (vd);
		map_color (info->colorMap, vd, &R (destination, x, y));
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
		map_color (info->colorMap, va, &R (destination, x, y));
		NEXTX;

		vb  = (v & 0x30) >> 4;
		CHECK_INDEX (vb);
		map_color (info->colorMap, vb, &R (destination, x, y));
		NEXTX;

		vc  = (v & 0x0C) >> 2;
		CHECK_INDEX (vc);
		map_color (info->colorMap, vc, &R (destination, x, y));
		NEXTX;

		vd  = (v & 0x03);
		CHECK_INDEX (vd);
		map_color (info->colorMap, vd, &R (destination, x, y));
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

	while (!stop && ((crimp_buf_tell(buf) - base) < info->numPixelBytes)) {
	    CHECK_SPACE (2);
	    crimp_buf_read_uint8 (buf, &l);
	    switch (l) {
	    case 0:
		/* Escape clause.
		 */
		crimp_buf_read_uint8 (buf, &v);
		switch (v) {
		case 0: /* End of line */
		    x = 0;
		    y --;
		    break;
		case 1: /* End of bitmap */
		    stop = 1;
		    break;
		case 2: /* Jump */
		    CHECK_SPACE (2);
		    crimp_buf_read_uint8 (buf, &l); x += l;
		    crimp_buf_read_uint8 (buf, &v); y -= v; /* bottom-up! */
		    break;
		default:
		    /* Absolute mode: 3-255. l = length of pixel
		     * sequence. Convert that many indices.
		     */
		    l = v;
		    while (l) {
			GET_INDEX (v);

			va = (v & 0xF0) >> 4;
			CHECK_INDEX (va);
			map_color (info->colorMap, va, &R (destination, x, y));

			l --;
			x ++;

			if (x >= info->w) {;
			    x = 0;
			    y --;
			}

			if (!l) break;

			vb = (v & 0x0F);
			CHECK_INDEX (vb);
			map_color (info->colorMap, vb, &R (destination, x, y));

			l --;
			x ++;

			if (x >= info->w) {;
			    x = 0;
			    y --;
			}
		    }
		    crimp_buf_align (buf, 2);
		    break;
		}
		break;
	    default:
		/* Run-code. l = length of run. Get index to map and store this many times.
		 */
		crimp_buf_read_uint8 (buf, &v);
		CHECK_INDEX (v);
		va = (v & 0xF0) >> 4;	CHECK_INDEX (va);
		vb = (v & 0x0F);	CHECK_INDEX (vb);

		while (l) {
		    map_color (info->colorMap, va, &R (destination, x, y));
		    l --;
		    x ++;
		    if (x >= info->w) {
			x = 0;
			y --;
		    }
		    if (!l) break;
		    map_color (info->colorMap, vb, &R (destination, x, y));
		    l --;
		    x ++;
		    if (x >= info->w) {
			x = 0;
			y --;
		    }
		}
		break;
	    }
	}

	if ((crimp_buf_tell(buf) - base) != info->numPixelBytes) {
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
		map_color (info->colorMap, va, &R (destination, x, y));

		NEXTX;

		vb = (v & 0x0F);
		CHECK_INDEX (vb);

		map_color (info->colorMap, vb, &R (destination, x, y));
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
		map_color (info->colorMap, va, &R (destination, x, y));

		NEXTX;

		vb = (v & 0x0F);
		CHECK_INDEX (vb);

		map_color (info->colorMap, vb, &R (destination, x, y));
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

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

	while (!stop && ((crimp_buf_tell(buf) - base) < info->numPixelBytes)) {
	    CHECK_SPACE (2);
	    crimp_buf_read_uint8 (buf, &l);
	    switch (l) {
	    case 0:
		/* Escape clause.
		 */
		crimp_buf_read_uint8 (buf, &v);
		switch (v) {
		case 0: /* End of line */
		    x = 0;
		    y --;
		    break;
		case 1: /* End of bitmap */
		    stop = 1;
		    break;
		case 2: /* Jump */
		    CHECK_SPACE (2);
		    crimp_buf_read_uint8 (buf, &l); x += l;
		    crimp_buf_read_uint8 (buf, &v); y -= v; /* bottom-up! */
		    break;
		default:
		    /* Absolute mode: 3-255. l = length of pixel
		     * sequence. Convert that many indices.
		     */
		    l = v;
		    while (l) {
			GET_CHECK_INDEX (v);
			map_color (info->colorMap, v, &R (destination, x, y));
			l --;
			x ++;
			if (x < info->w) continue;
			x = 0;
			y --;
		    }
		    crimp_buf_align (buf, 2);
		    break;
		}
		break;
	    default:
		/* Run-code. l = length of run. Get index to map and store this many times.
		 */
		crimp_buf_read_uint8 (buf, &v);
		CHECK_INDEX (v);
		while (l) {
		    map_color (info->colorMap, v, &R (destination, x, y));
		    l --;
		    x ++;
		    if (x < info->w) continue;
		    x = 0;
		    y --;
		}
		break;
	    }
	}

	if ((crimp_buf_tell(buf) - base) != info->numPixelBytes) {
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
		map_color (info->colorMap, v, &R (destination, x, y));
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
		map_color (info->colorMap, v, &R (destination, x, y));
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

		crimp_buf_read_uint8 (buf, &v);  R (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  G (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  B (destination, x, y) = v;
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

		crimp_buf_read_uint8 (buf, &v);  R (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  G (destination, x, y) = v;
		crimp_buf_read_uint8 (buf, &v);  B (destination, x, y) = v;
	    }
	    crimp_buf_alignr (buf, base, 4);
	}
    }

    return 1;
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
    pix [2] = colorMap [index + 0]; /* Blue */
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
