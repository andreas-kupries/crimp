/*
 * CRIMP :: BMP functions Definitions (Implementation).
 * See http://en.wikipedia.org/wiki/BMP_file_format
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include "bmp.h"

/*
 * Definitions :: Core.
 */

int
bmp_read_header (crimp_buffer* buf,
		 int* w, int* h,
		 unsigned char **colorMap,
		 int* numBits, int* numCols, int* comp,
		 unsigned int* mask)
{
    unsigned int fsize, pixOffset, c;

    unsigned int x;
    int i, compression, nBits, clrUsed, offBits;

    /*
     * Reference
     *	http://en.wikipedia.org/wiki/BMP_file_format
     *
     * Win Header
     *  0.. 1 | 2 : magic "BM" (ascii).
     *  2.. 5 | 4 : size of file in bytes
     *  6.. 7 | 2 : reserved (creator-id 1)
     *  8.. 9 | 2 : reserved (creator-id 2)
     * 10..13 | 4 : offset to pixel data, relative to start of file.
     */

    if (!crimp_buf_has   (buf, 14))      { return 0; } /* Space for Win Header */
    if (!crimp_buf_match (buf, 2, "BM")) { return 0; } /* BMP magic value */

    crimp_buf_read_uint32le (buf, &fsize);             /* BMP file size */
    crimp_buf_skip          (buf, 4);                  /* reserved */
    crimp_buf_read_uint32le (buf, &pixOffset);         /* offset to pixel data */

    /* Check internal consistency of the data retrieved so far */
    if ((crimp_buf_size (buf) != fsize) ||
	(pixOffset % 4 != 0) ||
	!crimp_buf_check (buf, pixOffset)) { return 0; }

    /*
     * DIB Header (multiple variants, distinguishable by size).
     *  0..3 | 4 : DIB header size, common to all variants.
     */

    if (!crimp_buf_has      (buf, 4))      { return 0; } /* Space for DIB Header size */
    crimp_buf_read_uint32le (buf, &c);                   /* DIB header size */
    if (!crimp_buf_has      (buf, c-4))    { return 0; } /* Space for remaining DIB Header */

#error TODO DIB header processing.

    return 1;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
