/*
 * CRIMP :: Image Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <image.h>
#include <util.h>
#include <tcl.h>
#include <string.h>

/*
 * Internal declarations.
 */

static void FreeImage     (Tcl_Obj* imgObjPtr);
static void DupImage      (Tcl_Obj* imgObjPtr,
			   Tcl_Obj* dupObjPtr);
static void StringOfImage (Tcl_Obj* imgObjPtr);
static int  ImageFromAny  (Tcl_Interp* interp,
			   Tcl_Obj* imgObjPtr);

static Tcl_ObjType ImageType = {
    "tim::image",
    FreeImage,
    DupImage,
    StringOfImage,
    ImageFromAny
};

/*
 * Definitions :: Core.
 */

crimp_image*
crimp_new (const crimp_imagetype* type, int w, int h)
{
    /*
     * Note: Pixel storage and header describing it are allocated together.
     */

    int          size  = sizeof (crimp_image) + w * h * type->size;
    crimp_image* image = (crimp_image*) ckalloc (size);

    image->type  = type;
    image->w     = w;
    image->h     = h;

    return image;
}

crimp_image*
crimp_dup (crimp_image* image)
{
    int          size      = sizeof (crimp_image) + image->w * image->h * image->type->size;
    crimp_image* new_image = (crimp_image*) ckalloc (size);

    /*
     * Remember the note in function 'crimp_new' above.
     * Pixel storage and header are a single block.
     */

    memcpy (new_image, image, size);
    return new_image;
}

void
crimp_del (crimp_image* image)
{
    /*
     * Remember the note in function 'crimp_new' above.
     * Pixel storage and header are a single block.
     */

    ckfree ((char*) image);
}

/*
 * Definitions :: Tcl.
 */

Tcl_Obj*
crimp_new_image_obj (crimp_image* image)
{
    Tcl_Obj* obj = Tcl_NewObj ();

    obj->internalRep.otherValuePtr = image;
    obj->typePtr                   = &ImageType;

    return obj;
}

int
crimp_get_image_from_obj (Tcl_Interp* interp, Tcl_Obj* imageObj, crimp_image** image)
{
    if (imageObj->typePtr != &ImageType) {
	if (ImageFromAny (interp, imageObj) != TCL_OK) {
	    return TCL_ERROR;
	}
    }

    *image = (crimp_image*) imageObj->internalRep.otherValuePtr;
    return TCL_OK;
}

/*
 * Definitions :: ObjType Internals.
 */

static void
FreeImage (Tcl_Obj* imgObjPtr)
{
    crimp_del ((crimp_image*) imgObjPtr->internalRep.otherValuePtr);
}

static void
DupImage (Tcl_Obj* imgObjPtr, Tcl_Obj* dupObjPtr)
{
    crimp_image* ci  = (crimp_image*) imgObjPtr->internalRep.otherValuePtr;

    dupObjPtr->internalRep.otherValuePtr = crimp_dup (ci);
    dupObjPtr->typePtr                   = &ImageType;
}

static void
StringOfImage (Tcl_Obj* imgObjPtr)
{
    /* panic - No string rep for images */
    Tcl_Panic ("No string representation for images");

#if 0
Tcl_Obj *list[] = {
    Tcl_NewIntObj(pib.width), Tcl_NewIntObj(pib.height),
    Tcl_NewByteArrayObj(pib.pixelPtr, 4 * pib.width * pib.height)
};
    /* convert via a byte array to properly handle null bytes */
    temp = Tcl_NewByteArrayObj(buf, sizeof buf);
    Tcl_IncrRefCount(temp);
            
    str = Tcl_GetStringFromObj(temp, &obj->length);
    obj->bytes = Tcl_Alloc(obj->length + 1);
    memcpy(obj->bytes, str, obj->length + 1);
            
    Tcl_DecrRefCount(temp);

#endif

}

static int
ImageFromAny (Tcl_Interp* interp, Tcl_Obj* imgObjPtr)
{
    int       objc;
    Tcl_Obj **objv;
    int w, h, length;
    crimp_pixel_array pixel;
    crimp_image* ci;
    crimp_imagetype* ct;

    if (Tcl_ListObjGetElements(interp, imgObjPtr, &objc, &objv) != TCL_OK) {
	return TCL_ERROR;
    }

    if (objc != 4) {
    invalid:
	Tcl_SetResult(interp, "invalid image format", TCL_STATIC);
	return TCL_ERROR;
    }

    if ((crimp_get_imagetype_from_obj (interp, objv[0], &ct) != TCL_OK) ||
        (Tcl_GetIntFromObj            (interp, objv[1], &w) != TCL_OK) ||
	(Tcl_GetIntFromObj            (interp, objv[2], &h) != TCL_OK) ||
	(w < 0) || (h < 0))
	goto invalid;

    pixel = Tcl_GetByteArrayFromObj (objv[3], &length);
    if (length != (ct->size * w * h))
	goto invalid;

    ci = crimp_new (ct, w, h);
    memcpy(ci->pixel, pixel, length);

    /*
     * Kill the changed intrep (List, ByteArray) above.  While the previous
     * intrep may have been killed before this function was called, we
     * generated a new one during the conversion and have to get rid of it.
     */

    imgObjPtr->typePtr->freeIntRepProc (imgObjPtr);

    /*
     * Now we can put in our own intrep.
     */

    imgObjPtr->internalRep.otherValuePtr = ci;
    imgObjPtr->typePtr                   = &ImageType;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
