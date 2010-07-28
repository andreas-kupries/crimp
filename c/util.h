#ifndef CRIMP_UTIL_H
#define CRIMP_UTIL_H
/*
 * CRIMP :: Utility Declarations.
 * (C) 2010.
 */

/*
 * Convenience macros for the allocation of structures and arrays.
 */

#define DUPSTR(str)    ((char *) strcpy (ckalloc (strlen (str)+1), str))
#define DUP(p,type)    ((type *) memcpy (ALLOC (type), p, sizeof (type)))
#define ALLOC(type)    ((type *) ckalloc (sizeof (type)))
#define NALLOC(n,type) ((type *) ckalloc ((n) * sizeof (type)))

#define FreeIntRep(objPtr) \
    if ((objPtr)->typePtr != NULL && \
	    (objPtr)->typePtr->freeIntRepProc != NULL) { \
	(objPtr)->typePtr->freeIntRepProc(objPtr); \
	(objPtr)->typePtr = NULL; \
    }

/*
 * General math support.
 */

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define CLAMP(min, v, max) ((v) < (min) ? (min) : (v) < (max) ? (v) : (max))

#define RANGEOK(i,n) ((0 <= (i)) && (i < (n)))

/*
 * Assertions support in general, and asserting the proper range of an array
 * index especially.
 */

#undef  CRIMP_DEBUG
#define CRIMP_DEBUG 1

#ifdef CRIMP_DEBUG
#define XSTR(x) #x
#define STR(x) XSTR(x)
#define ASSERT(x,msg) if (!(x)) { Tcl_Panic (msg " (" #x "), in file " __FILE__ " @line " STR(__LINE__));}
#define ASSERT_BOUNDS(i,n) ASSERT (RANGEOK(i,n),"array index out of bounds: " STR(i) " > " STR(n))
#else
#define ASSERT(x,msg)
#define ASSERT_BOUNDS(i,n)
#endif


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_UTIL_H */
