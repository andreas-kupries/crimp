#ifndef CRIMP_UTIL_H
#define CRIMP_UTIL_H
/*
 * CRIMP :: Utility Declarations.
 * (C) 2010-2011.
 */

#include "common.h"
#include "crimp_config.h"
#include <f2c.h>

/*
 * Common declarations to access the FFT functions (fftpack).
 */

extern int rffti_ (integer *n, real *wsave);
extern int rfftf_ (integer *n, real* r, real *wsave);
extern int rfftb_ (integer *n, real* r, real *wsave);

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
 * - - -- --- ----- -------- ------------- ---------------------
 * Handle the environment configuration as supplied by crimp_config.h
 */

#ifndef C_HAVE_HYPOTF
#define hypotf(x,y) hypot(x,y)
#endif

#ifndef C_HAVE_SINF
#define sinf(x) sin(x)
#endif

#ifndef C_HAVE_COSF
#define cosf(x) cos(x)
#endif

#ifndef C_HAVE_EXPF
#define expf(x) exp(x)
#endif

#ifndef C_HAVE_SQRTF
#define sqrtf(x) sqrt(x)
#endif

#ifndef C_HAVE_ATAN2F
#define atan2f(x,y) atan(x,y)
#endif

#ifndef C_HAVE_LOGF
#define logf(x) log(x)
#endif

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_UTIL_H */
