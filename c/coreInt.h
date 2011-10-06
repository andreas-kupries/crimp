#ifndef CRIMP_CORE_INTERNAL_H
#define CRIMP_CORE_INTERNAL_H
/*
 * CRIMP :: Core Declarations :: INTERNAL
 * (C) 2011.
 */

#include <tcl.h>
#include <string.h>
#include <limits.h> /* HAVE_LIMITS_H check ? */

#undef USE_CRIMP_CORE_STUBS
#include <crimp_core/crimp_coreDecls.h>

/*
 * Helper macro for dealing with Tcl_ObjType's.
 */

#define FreeIntRep(objPtr) \
    if ((objPtr)->typePtr != NULL && \
	    (objPtr)->typePtr->freeIntRepProc != NULL) { \
	(objPtr)->typePtr->freeIntRepProc(objPtr); \
	(objPtr)->typePtr = NULL; \
    }


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_CORE_INTERNAL_H */
