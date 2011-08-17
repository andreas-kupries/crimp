#ifndef CRIMP_io_bmp_H
#define CRIMP_io_bmp_H

/*
 * CRIMP :: BMP helper dclarations. INTERNAL. Do not export.
 * Copyright (c) 1997-2003 Jan Nijtmans    <nijtmans@users.sourceforge.net>
 * Copyright (c) 2002      Andreas Kupries <andreas_kupries@users.sourceforge.net>
 */

#include <crimp_core/crimp_coreDecls.h>

/* Compression types */
#define BI_RGB          0
#define BI_RLE8         1
#define BI_RLE4         2
#define BI_BITFIELDS    3

/* Structure for reading bit masks for compression type BI_BITFIELDS */
typedef struct {
  unsigned int mask;
  unsigned int shiftin;
  unsigned int shiftout;
} BitmapChannel;

extern int
bmp_read_header (crimp_buffer* buf,
		 int* w, int* h,
		 unsigned char **colorMap,
		 int* numBits, int* numCols, int* comp,
		 unsigned int* mask);


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_io_bmp_H */
