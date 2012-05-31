#ifndef CRIMP_UTIL_H
#define CRIMP_UTIL_H
/*
 * CRIMP :: Utility Declarations.
 * (C) 2010-2011.
 */

#include "common.h"
#include "cutil.h"
#include "crimp_config.h"
#include <f2c.h>

/*
 * Common declarations to access the FFT functions (fftpack).
 */

extern int rffti_ (integer *n, real *wsave);
extern int rfftf_ (integer *n, real* r, real *wsave);
extern int rfftb_ (integer *n, real* r, real *wsave);

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
