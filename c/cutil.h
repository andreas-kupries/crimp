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
#define MAXVAL_GREY32 (4294967295)

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
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_CORE_UTIL_H */
