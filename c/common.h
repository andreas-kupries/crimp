#ifndef CRIMP_COMMON_H
#define CRIMP_COMMON_H
/*
 * CRIMP :: Common Declarations :: PUBLIC
 * (C) 2011.
 */

#define CRIMP_RANGEOK(i,n) ((0 <= (i)) && (i < (n)))

/*
 * Convenient checking of image types.
 */

#define CRIMP_ASSERT_IMGTYPE(image,imtype) \
    CRIMP_ASSERT ((image)->itype == crimp_imagetype_find ("crimp::image::" CRIMP_STR(imtype)), \
	    "expected image type " CRIMP_STR(imtype))

#define CRIMP_ASSERT_NOTIMGTYPE(image,imtype) \
    CRIMP_ASSERT ((image)->itype != crimp_imagetype_find ("crimp::image::" CRIMP_STR(imtype)), \
	    "unexpected image type " CRIMP_STR(imtype))

/*
 * Assertions support in general, and asserting the proper range of an array
 * index especially.
 */

#undef  CRIMP_DEBUG   /* Future: controlled by a user-specified critcl option */
#define CRIMP_DEBUG 1 /* */

#ifdef CRIMP_DEBUG
#define CRIMP_XSTR(x) #x
#define CRIMP_STR(x) CRIMP_XSTR(x)
#define CRIMP_ASSERT(x,msg) if (!(x)) { Tcl_Panic (msg " (" #x "), in file " __FILE__ " @line " CRIMP_STR(__LINE__));}
#define CRIMP_ASSERT_BOUNDS(i,n) CRIMP_ASSERT (CRIMP_RANGEOK(i,n),"array index out of bounds: " CRIMP_STR(i) " > " CRIMP_STR(n))
#else
#define CRIMP_ASSERT(x,msg)
#define CRIMP_ASSERT_BOUNDS(i,n)
#endif


/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
#endif /* CRIMP_COMMON_H */
