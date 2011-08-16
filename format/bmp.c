/*
 * CRIMP :: BMP functions Definitions (Implementation).
 * See http://en.wikipedia.org/wiki/BMP_file_format
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include <buf.h>
#include <bmp.h>

/*
 * Definitions :: Core.
 */

int
crimp_bmp_process_header (Buf* buf,
			  int* w, int* h,
			  unsigned char **colorMap,
			  int* numBits, int* numCols, int* comp,
			  unsigned int* mask)
{
    unsigned int x;
    int c, i, compression, nBits, clrUsed, offBits;

    /*
     * See http://en.wikipedia.org/wiki/BMP_file_format
     *
     * Header
     *  0.. 1 - 2 - magic "BM" (ascii).
     *  2.. 5 - 4 - size of file in bytes
     *  6.. 7 - 2 - reserved
     *  8.. 9 - 2 - reserved
     * 10..13 - 4 - offset to pixel data
     *
     * DIB Header (multiple variants).
     */

    if (!crimp_buf_require (buf, 26))   { return 0; } /* 0..26 */
    if (!crimp_buf_strn (buf, 2, "BM")) { return 0; } /* 0..1 */

    crimp_buf_uint32le (buf, &fSize);
    crimp_buf_skip     (buf, 4); /* reserved */
    crimp_buf_uint32le (buf, &fSize);








    /* ? what header fields */
    crimp_buf_seek (buf, 13);
    crimp_buf_uint8 (buf, &x) ; if (!x) { return 0; } /* 13 */
    crimp_buf_uint8 (buf, &x) ; if (!x) { return 0; } /* 14 */
    crimp_buf_uint8 (buf, &x) ; if (!x) { return 0; } /* 15 -> 16*/

    crimp_buf_seek (buf, -16);
    crimp_buf_seek (buf, 8);

    crimp_buf_uint32le (buf, &offBits); /* 8..11 */
    crimp_buf_uint8    (buf, &c);       /* 12 -> 13 */

    crimp_buf_seek (buf, -13);

    if ((c == 40) || (c == 64)) {

	crimp_buf_seek (buf, 16);
	crimp_buf_uint32le (buf, w); /* 16..19 */
	crimp_buf_uint32le (buf, h); /* 20..23 */

	if (!crimp_buf_require (buf, 24))   { return 0; }
	/* 0..23 = 26..49 */

	crimp_buf_seek (buf, 2);
	crimp_buf_uint8 (buf, &nBits);       /* 2 */
	crimp_buf_seek (buf, 1);
	crimp_buf_uint8 (buf, compression);       /* 4 */

	crimp_buf_seek (buf, -5);
	crimp_buf_seek (buf, 20);

	crimp_buf_uint16le (buf, &clrUsed); /* 20..21 */
        offBits -= c+14;

	crimp_buf_seek (buf, -22);

    } else if (c == 12) {

	crimp_buf_seek (buf, 16);
	crimp_buf_uint16le (buf, w); /* 16..17 */
	crimp_buf_uint16le (buf, h); /* 18..19 */

	crimp_buf_seek (buf, -20);
	crimp_buf_seek (buf, 22);

	crimp_buf_uint8 (buf, &nBits);  /* 22 */

        compression = BI_RGB;
        clrUsed = 0;
    } else {
        return 0;
    }




    return 1;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
