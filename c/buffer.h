#ifndef CRIMP_BUFFER_H
#define CRIMP_BUFFER_H
/*
 * CRIMP :: Helper functions for the extraction of data from a buffer
 *          (8/16/32 bit words, signed/unsigned, big/small endian).
 *          INTERNAL.
 * (C) 2011.
 */

/*
 * API :: Core. 
 */

typedef struct crimp_buffer {
    unsigned char* buf;      /* Start of data */
    unsigned char* here;     /* Current byte, read location */
    unsigned char* sentinel; /* End of buffer, behind last byte */
    int            length;   /* Size of buffer, sentinel - buf */
} crimp_buffer;

#define crimp_buf_at(b) ((b)->here)

/*
 * BUILD ASSERTION: The buffer API assumes that a variable of type 'int' can
 * hold (at least) 4 bytes (See the crimp_read_*int32* functions).  Failure in
 * the line below tells us that this is not true for the chosen combination of
 * OS, compiler, and compiler flags.
 */

CRIMP_BUILD_ASSERT (sizeof(int) >= 4);

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_BUFFER_H */
