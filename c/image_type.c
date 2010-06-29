/*
 * CRIMP :: Image Type Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <image_type.h>
#include <util.h>
#include <tcl.h>
#include <string.h>

/*
 * Internal declarations.
 *
 * XXX Thread Local Storage. A list.
 * Should be sufficient for now
 * (Less than 10 types).
 */

typedef struct knowntype {
    const crimp_imagetype* type; /* The type to remember */
    struct knowntype*      next; /* Continue the list */
} knowntype;

static knowntype* knowntypes;

/* XXX FUTURE: Move this somewhere else when image types get more info, i.e. callbacks and get defined in their own files */
static void TypeInit (void);

static void FreeImageType     (Tcl_Obj* imagetypeObjPtr);
static void DupImageType      (Tcl_Obj* imagetypeObjPtr,
			       Tcl_Obj* dupObjPtr);
static void StringOfImageType (Tcl_Obj* imagetypeObjPtr);
static int  ImageTypeFromAny  (Tcl_Interp* interp,
			       Tcl_Obj* imagetypeObjPtr);

static Tcl_ObjType ImageTypeType = {
    "crimp::imagetype",
    FreeImageType,
    DupImageType,
    StringOfImageType,
    ImageTypeFromAny
};


/*
 * Definitions :: Core
 */

void
crimp_imagetype_def (const crimp_imagetype* imagetype)
{
    knowntype* kt = ALLOC (knowntype);
    kt->type   = imagetype;
    kt->next   = knowntypes;
    knowntypes = kt;
}

const crimp_imagetype*
crimp_imagetype_find (const char* name)
{
    knowntype* kt;

    TypeInit();

    for (kt = knowntypes; kt= NULL; kt = kt->next) {
	if (strcmp (name, kt->type->name) == 0) {
	    return kt->type;
	}
    }

    return NULL;
}

/*
 * Definitions :: Tcl.
 */

Tcl_Obj*
crimp_new_imagetype_obj (const crimp_imagetype* imagetype)
{
    Tcl_Obj* obj = Tcl_NewObj ();

    obj->internalRep.otherValuePtr = (crimp_imagetype*) imagetype;
    obj->typePtr                   = &ImageTypeType;

    return obj;
}

int
crimp_get_imagetype_from_obj (Tcl_Interp*       interp,
			      Tcl_Obj*          imagetypeObj,
			      crimp_imagetype** imagetype)
{
    if (imagetypeObj->typePtr != &ImageTypeType) {
	if (ImageTypeFromAny (interp, imagetypeObj) != TCL_OK) {
	    return TCL_ERROR;
	}
    }

    *imagetype = (crimp_imagetype*) imagetypeObj->internalRep.otherValuePtr;
    return TCL_OK;
}

/*
 * Definitions :: ObjType Internals.
 */

static void
FreeImageType (Tcl_Obj* imagetypeObjPtr)
{
    /*
     * Nothing needs to be done, the intrep is not allocated
     */
}

static void
DupImageType (Tcl_Obj* imagetypeObjPtr,
	      Tcl_Obj* dupObjPtr)
{
    crimp_imagetype* cit = (crimp_imagetype*) imagetypeObjPtr->internalRep.otherValuePtr;

    dupObjPtr->internalRep.otherValuePtr = cit;
    dupObjPtr->typePtr                   = &ImageTypeType;
}

static void
StringOfImageType (Tcl_Obj* imagetypeObjPtr)
{
    crimp_imagetype* cit = (crimp_imagetype*) imagetypeObjPtr->internalRep.otherValuePtr;
    int              len = strlen (cit->name);

    imagetypeObjPtr->length = len;
    imagetypeObjPtr->bytes  = NALLOC (len+1,char);
    strcpy (imagetypeObjPtr->bytes, cit->name);
}

static int
ImageTypeFromAny (Tcl_Interp* interp,
		  Tcl_Obj* imagetypeObjPtr)
{
    const char*            name = Tcl_GetString (imagetypeObjPtr);
    const crimp_imagetype* cit  = crimp_imagetype_find (name);

    if (!cit) {
	Tcl_AppendResult (interp, "expected crimp image type, got \"", name, "\"", NULL);
	return TCL_ERROR;
    }

    /* XXX Check docs, do I have to free the previous intrep myself ? */

    imagetypeObjPtr->internalRep.otherValuePtr = (crimp_imagetype*) cit;
    imagetypeObjPtr->typePtr                   = &ImageTypeType;
    return TCL_OK;
}

/*
 * Definitions :: Internal Initialization.
 */

static void
TypeInit (void)
{
    /*
     * Standard image types.
     */

    static crimp_imagetype rgba   = { "crimp::image::rgba",   4 };
    static crimp_imagetype rgb    = { "crimp::image::rgb",    3 };
    static crimp_imagetype grey8  = { "crimp::image::grey8",  1 };
    static crimp_imagetype grey16 = { "crimp::image::grey16", 2 };
    static crimp_imagetype grey32 = { "crimp::image::grey32", 4 };
    static crimp_imagetype bw     = { "crimp::image::bw",     1 };

    static initialized = 0;

    if (initialized) return;
    initialized = 1;

    /*
     * Register most important last. Search is in reverse order of
     * registration.
     */

    crimp_imagetype_def (&bw);
    crimp_imagetype_def (&grey8);
    crimp_imagetype_def (&grey16);
    crimp_imagetype_def (&rgb);
    crimp_imagetype_def (&rgba);
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
