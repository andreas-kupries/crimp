/*
 * CRIMP :: Utility Declarations.
 * (C) 2010.
 */

#define DUPSTR(str)    (char *) strcpy (ckalloc (strlen (str)+1), str)
#define DUP(p,type)    (type *) memcpy (ALLOC (type), p, sizeof (type))

#define ALLOC(type)    (type *) ckalloc (sizeof (type))
#define NALLOC(n,type) (type *) ckalloc ((n) * sizeof (type))


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
