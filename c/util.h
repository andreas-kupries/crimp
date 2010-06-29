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

/*
 * General math support.
 */

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define CLAMP(min, v, max) ((v) < (min) ? (min) : (v) < (max) ? (v) : (max))

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_UTIL_H */
