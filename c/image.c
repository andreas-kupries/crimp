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
#include <limits.h> /* HAVE_LIMITS_H check ? */

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
crimp_new (const crimp_imagetype* itype, int w, int h)
{
    /*
     * Note: Pixel storage and header describing it are allocated together.
     */

    int          size  = sizeof (crimp_image) + w * h * itype->size;
    crimp_image* image = (crimp_image*) ckalloc (size);

    image->itype = itype;
    image->w     = w;
    image->h     = h;

    return image;
}

crimp_image*
crimp_dup (crimp_image* image)
{
    int          size      = sizeof (crimp_image) + image->w * image->h * image->itype->size;
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

    Tcl_InvalidateStringRep (obj);
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
    crimp_image* ci  = (crimp_image*) imgObjPtr->internalRep.otherValuePtr;
    int length;
    Tcl_DString ds;

    Tcl_DStringInit (&ds);

    /* image type */
    Tcl_DStringAppendElement (&ds, ci->itype->name);

    /* image width */
    {
	char wstring [20];
	sprintf (wstring, "%u", ci->w);
	Tcl_DStringAppendElement (&ds, wstring);
    }

    /* image width */
    {
	char hstring [20];
	sprintf (hstring, "%u", ci->h);
	Tcl_DStringAppendElement (&ds, hstring);
    }

    /* image pixels */
    {
	/*
	 * Basic length of the various pieces going into the string, from type
	 * name, formatted width/height numbers, number of pixels.
	 */

	char* tmp;
	char* dst;
	int plen = ci->itype->size * ci->w * ci->h;
	int expanded, i;

	/*
	 * Now correct the length for the pixels. This is binary data, and the
	 * utf8 representation for 0 and anything >128 needs an additional
	 * byte each. Snarfed from UpdateStringOfByteArray in
	 * generic/tclBinary.c
	 */

	expanded = 0;
	for (i = 0; i < (ci->itype->size * ci->w * ci->h) && plen >= 0; i++) {
	    if ((ci->pixel[i] == 0) || (ci->pixel[i] > 127)) {
		plen ++;
		expanded = 1;
	    }
	}

	if (plen < 0) {
	    Tcl_Panic("max size for a Tcl value (%d bytes) exceeded", INT_MAX);
	}

	/*
	 * We need the temporary array because ...AppendElement below expects
	 * a 0-terminated string, and the pixels aren't
	 */

	dst = tmp = NALLOC (plen+1, char);
	if (expanded) {
	    /*
	     * If bytes have to be expanded we have to handle them 1-by-1.
	     */
	    for (i = 0; i < (ci->itype->size * ci->w * ci->h); i++) {
		dst += Tcl_UniCharToUtf(ci->pixel[i], dst);
	    }
	} else {
	    /*
	     * All bytes are represented by single chars. We can copy them as a
	     * block.
	     */
	    memcpy(dst, ci->pixel, (size_t) plen);
	    dst += plen;
	}
	*dst = '\0';

	/*
	 * Note that this adds another layer of quoting to the string:
	 * list quoting.
	 */
	Tcl_DStringAppendElement (&ds, tmp);
	ckfree (tmp);
    }

    length = Tcl_DStringLength (&ds);

    imgObjPtr->bytes  = NALLOC (length+1, char);
    imgObjPtr->length = length;

    memcpy (imgObjPtr->bytes, Tcl_DStringValue (&ds), length+1);

    Tcl_DStringFree (&ds);
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
     * Kill the old intrep. This was delayed as much as possible.
     */

    FreeIntRep (imgObjPtr);

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
