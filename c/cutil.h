#ifndef CRIMP_CORE_UTIL_H
#define CRIMP_CORE_UTIL_H
/*
 * CRIMP :: Core Utility Declarations.
 * (C) 2012.
 */

#include "common.h"

/*
 * Convenience macros for the allocation of structures and arrays.
 */

#define DUPSTR(str)    ((char *) strcpy (ckalloc (strlen (str)+1), str))
#define DUP(p,type)    ((type *) memcpy (ALLOC (type), p, sizeof (type)))

/*
 * General math support.
 */

#undef MIN
#undef MAX

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define CLAMP(min, v, max) ((v) < (min) ? (min) : (v) < (max) ? (v) : (max))
#define CLAMPT(min, t, v, max) ((v) < (min) ? (min) : (v) < (max) ? ((t) (v)) : (max))

#define MINVAL        (0)
#define MAXVAL_GREY8  (255)
#define MAXVAL_GREY16 (65535)
#define MAXVAL_GREY32 (4294967295UL)

#define MAXVAL_STR_GREY8  "255"
#define MAXVAL_STR_GREY16 "65535"
#define MAXVAL_STR_GREY32 "4294967295"

/*
 * compile-time sizeof calculations, via <limits.h>
 *
 * TODO: Look for <stdint.h>, create backward portable replacement for machine/compile 
 *       combinations which do not provide it.
 */

#include <limits.h>

#if UINT_MAX == 18446744073709551615UL /* 64-bit int */
#define CRIMP_LONG_SIZE 8
#elif UINT_MAX == MAXVAL_GREY32        /* 32-bit int */
#define CRIMP_INT_SIZE 4
#elif UINT_MAX == MAXVAL_GREY16        /* 16-bit int */
#define CRIMP_INT_SIZE 2
#elif UINT_MAX == MAXVAL_GREY8         /*  8-bit int */
#define CRIMP_INT_SIZE 1
#else
#error "Unable to determine sizeof(int)"
#endif

#if ULONG_MAX == 18446744073709551615UL /* 64-bit long */
#define CRIMP_LONG_SIZE 8
#elif ULONG_MAX == MAXVAL_GREY32        /* 32-bit long */
#define CRIMP_LONG_SIZE 4
#elif ULONG_MAX == MAXVAL_GREY16        /* 16-bit long */
#define CRIMP_LONG_SIZE 2
#elif ULONG_MAX == MAXVAL_GREY8         /*  8-bit long */
#define CRIMP_LONG_SIZE 1
#else
#error "Unable to determine sizeof(long)"
#endif

/*
 * Miscellaneous constants and machine-specific settings.
 */

#ifndef M_PI
#define M_PI (3.141592653589793238462643)
#endif

#ifdef _MSC_VER
#define inline __inline
#endif
#ifdef _AIX
#define inline
#endif
#ifdef __hpux
#define inline
#endif

/*
 * Generator for uniform random floating-point values in the interval [0..1].
 */
#define RAND_FLOAT() (rand() / (RAND_MAX + 1.0f))

/*
 * Generator for uniform random double-precision floating-point values in the interval [0..1].
 */
#define RAND_DOUBLE() (rand() / (RAND_MAX + ((double) 1)))

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_CORE_UTIL_H */
