/*
 * CRIMP :: Volume Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <volume.h>
#include <image.h>
#include <util.h>
#include <tcl.h>
#include <string.h>
#include <limits.h> /* HAVE_LIMITS_H check ? */

/*
 * Internal declarations.
 */

static void FreeVolume     (Tcl_Obj* volObjPtr);
static void DupVolume      (Tcl_Obj* volObjPtr,
			    Tcl_Obj* dupObjPtr);
static void StringOfVolume (Tcl_Obj* volObjPtr);
static int  VolumeFromAny  (Tcl_Interp* interp,
			    Tcl_Obj* volObjPtr);

static Tcl_ObjType VolumeType = {
    "crimp::volume",
    FreeVolume,
    DupVolume,
    StringOfVolume,
    VolumeFromAny
};

/*
 * Definitions :: Core.
 */

crimp_volume*
crimp_vnew (const crimp_imagetype* itype, int w, int h, int d)
{
    /*
     * Note: Pixel storage and header describing it are allocated together.
     */

    size_t        size   = sizeof (crimp_volume) + RECT_VOLUME (w, h, d) * itype->size;
    crimp_volume* volume = (crimp_volume*) ckalloc (size);

    volume->itype = itype;
    volume->w     = w;
    volume->h     = h;
    volume->d     = d;
    volume->meta  = NULL;

    return volume;
}

crimp_volume*
crimp_vnewm (const crimp_imagetype* itype, int w, int h, int d, Tcl_Obj* meta)
{
    /*
     * Note: Pixel storage and header describing it are allocated together.
     */

    size_t        size   = sizeof (crimp_volume) + RECT_VOLUME (w, h, d) * itype->size;
    crimp_volume* volume = (crimp_volume*) ckalloc (size);

    volume->itype = itype;
    volume->w     = w;
    volume->h     = h;
    volume->d     = d;
    volume->meta  = meta;

    if (meta) {
	Tcl_IncrRefCount (meta);
    }

    return volume;
}

crimp_volume*
crimp_vdup (crimp_volume* volume)
{
    size_t        size      = sizeof (crimp_volume) + crimp_volume_vol (volume) * volume->itype->size;
    crimp_volume* new_volume = (crimp_volume*) ckalloc (size);

    /*
     * Remember the note in function 'crimp_new' above.
     * Pixel storage and header are a single block.
     */

    memcpy (new_volume, volume, size);
    if (volume->meta) {
	Tcl_IncrRefCount (volume->meta);
    }

    return new_volume;
}

void
crimp_vdel (crimp_volume* volume)
{
    /*
     * Remember the note in function 'crimp_new' above.
     * Pixel storage and header are a single block.
     */

    if (volume->meta) {
	Tcl_DecrRefCount (volume->meta);
    }
    ckfree ((char*) volume);
}

/*
 * Definitions :: Tcl.
 */

Tcl_Obj*
crimp_new_volume_obj (crimp_volume* volume)
{
    Tcl_Obj* obj = Tcl_NewObj ();

    Tcl_InvalidateStringRep (obj);
    obj->internalRep.otherValuePtr = volume;
    obj->typePtr                   = &VolumeType;

    return obj;
}

int
crimp_get_volume_from_obj (Tcl_Interp* interp, Tcl_Obj* volumeObj, crimp_volume** volume)
{
    if (volumeObj->typePtr != &VolumeType) {
	if (VolumeFromAny (interp, volumeObj) != TCL_OK) {
	    return TCL_ERROR;
	}
    }

    *volume = (crimp_volume*) volumeObj->internalRep.otherValuePtr;
    return TCL_OK;
}

/*
 * Definitions :: ObjType Internals.
 */

static void
FreeVolume (Tcl_Obj* volObjPtr)
{
    crimp_vdel ((crimp_volume*) volObjPtr->internalRep.otherValuePtr);
}

static void
DupVolume (Tcl_Obj* volObjPtr, Tcl_Obj* dupObjPtr)
{
    crimp_volume* cv  = (crimp_volume*) volObjPtr->internalRep.otherValuePtr;

    dupObjPtr->internalRep.otherValuePtr = crimp_vdup (cv);
    dupObjPtr->typePtr                   = &VolumeType;
}

static void
StringOfVolume (Tcl_Obj* volObjPtr)
{
    crimp_volume* cv  = (crimp_volume*) volObjPtr->internalRep.otherValuePtr;
    int length;
    Tcl_DString ds;

    Tcl_DStringInit (&ds);

    /* volume type */
    Tcl_DStringAppendElement (&ds, cv->itype->name);

    /* volume width */
    {
	char wstring [20];
	sprintf (wstring, "%u", cv->w);
	Tcl_DStringAppendElement (&ds, wstring);
    }

    /* volume height */
    {
	char hstring [20];
	sprintf (hstring, "%u", cv->h);
	Tcl_DStringAppendElement (&ds, hstring);
    }

    /* volume depth */
    {
	char dstring [20];
	sprintf (dstring, "%u", cv->d);
	Tcl_DStringAppendElement (&ds, dstring);
    }

    /* volume client data */
    if (cv->meta) {
	Tcl_DStringAppendElement (&ds, Tcl_GetString (cv->meta));
    } else {
	Tcl_DStringAppendElement (&ds, "");
    }

    /* volume voxels */
    {
	/*
	 * Basic length of the various pieces going into the string, from type
	 * name, formatted width/height numbers, number of voxels.
	 */

	char* tmp;
	char* dst;
	size_t sz = cv->itype->size * crimp_volume_vol (cv);
	int plen = sz; /* Tcl length for Tcl_Obj* bytes, 4g limit */
	int expanded, i;

	/*
	 * Now correct the length for the voxels. This is binary data, and the
	 * utf8 representation for 0 and anything >128 needs an additional
	 * byte each. Snarfed from UpdateStringOfByteArray in
	 * generic/tclBinary.c
	 */

	expanded = 0;
	for (i = 0; (i < sz) && (plen >= 0); i++) {
	    if ((cv->voxel[i] == 0) || (cv->voxel[i] > 127)) {
		plen ++;
		expanded = 1;
	    }
	}

	if (plen < 0) {
	    Tcl_Panic("max size for a Tcl value (%d bytes) exceeded", INT_MAX);
	}

	/*
	 * We need the temporary array because ...AppendElement below expects
	 * a 0-terminated string, and the voxels aren't
	 */

	dst = tmp = NALLOC (plen+1, char);
	if (expanded) {
	    /*
	     * If bytes have to be expanded we have to handle them 1-by-1.
	     */
	    for (i = 0; i < sz; i++) {
		dst += Tcl_UniCharToUtf(cv->voxel[i], dst);
	    }
	} else {
	    /*
	     * All bytes are represented by single chars. We can copy them as a
	     * block.
	     */
	    memcpy(dst, cv->voxel, (size_t) plen);
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

    volObjPtr->bytes  = NALLOC (length+1, char);
    volObjPtr->length = length;

    memcpy (volObjPtr->bytes, Tcl_DStringValue (&ds), length+1);

    Tcl_DStringFree (&ds);
}

static int
VolumeFromAny (Tcl_Interp* interp, Tcl_Obj* volObjPtr)
{
    int       objc;
    Tcl_Obj **objv;
    int w, h, d, length;
    crimp_pixel_array voxel;
    crimp_volume* cv;
    crimp_imagetype* ct;
    Tcl_Obj* meta;

    if (Tcl_ListObjGetElements(interp, volObjPtr, &objc, &objv) != TCL_OK) {
	return TCL_ERROR;
    }

    if (objc != 6) {
    invalid:
	Tcl_SetResult(interp, "invalid volume format", TCL_STATIC);
	return TCL_ERROR;
    }

    if ((crimp_get_imagetype_from_obj (interp, objv[0], &ct) != TCL_OK) ||
        (Tcl_GetIntFromObj            (interp, objv[1], &w) != TCL_OK) ||
	(Tcl_GetIntFromObj            (interp, objv[2], &h) != TCL_OK) ||
	(Tcl_GetIntFromObj            (interp, objv[3], &d) != TCL_OK) ||
	(w < 0) || (h < 0))
	goto invalid;

    voxel = Tcl_GetByteArrayFromObj (objv[5], &length);
    if (length != (ct->size * RECT_VOLUME (w, h, d)))
	goto invalid;

    meta = objv[4];

    cv = crimp_vnewm (ct, w, h, d, meta);
    memcpy(cv->voxel, voxel, length);

    /*
     * Kill the old intrep. This was delayed as much as possible.
     */

    FreeIntRep (volObjPtr);

    /*
     * Now we can put in our own intrep.
     */

    volObjPtr->internalRep.otherValuePtr = cv;
    volObjPtr->typePtr                   = &VolumeType;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
