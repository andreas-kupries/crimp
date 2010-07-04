# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

#package require Tk
package require critcl

proc take {varname} {
    upvar 1 $varname var
    return $var[set var ""]
}

# # ## ### ##### ######## #############
## Implementation.

catch {
    critcl::cheaders -g
    critcl::debug memory symbols
}
critcl::config tk 1
critcl::cheaders c/*.h
critcl::csources c/*.c
critcl::tsources crimp_tcl.tcl
critcl::cinit {
    crimp_imagetype_init ();
} {}
critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
    #include <image_type.h>
    #include <image.h>
    #include <color.h>
    #include <util.h>

    static int decodeImageObj(Tcl_Interp *interp, Tcl_Obj *imageObj, int *width,
    int *height, unsigned char **pixels)
    {
        int objc;
        Tcl_Obj **objv;
        if (Tcl_ListObjGetElements(interp, imageObj, &objc, &objv) != TCL_OK) {
            return TCL_ERROR;
        } else if (objc != 3) {
            Tcl_SetResult(interp, "invalid image format", TCL_STATIC);
            return TCL_ERROR;
        } else if (Tcl_GetIntFromObj(interp, objv[0], width ) != TCL_OK
                || Tcl_GetIntFromObj(interp, objv[1], height) != TCL_OK) {
            return TCL_ERROR;
        }

        int length;
        *pixels = Tcl_GetByteArrayFromObj(objv[2], &length);
        if (length != 4 * *width * *height || *width < 0 || *height < 0) {
            Tcl_SetResult(interp, "invalid image format", TCL_STATIC);
            return TCL_ERROR;
        }
        return TCL_OK;
    }

    static int getUnsharedImageObj(Tcl_Interp *interp, Tcl_Obj *inputObj,
    Tcl_Obj **outputObj, Tcl_Obj **dataObj)
    {
        *outputObj = inputObj;
        if (Tcl_ListObjIndex(interp, *outputObj, 2, dataObj) != TCL_OK) {
            return TCL_ERROR;
        } else if (Tcl_IsShared(*outputObj) || Tcl_IsShared(*dataObj)) {
            *outputObj = Tcl_DuplicateObj(*outputObj);
            *dataObj = Tcl_DuplicateObj(*dataObj);
            Tcl_ListObjReplace(interp, *outputObj, 2, 1, 1, dataObj);
        }
        return TCL_OK;
    }
}

# # ## ### ##### ######## #############
## Read and execute all .crimp files in the current directory.

foreach filename [lsort [glob -nocomplain [file join [file dirname [file normalize [info script]]] *.crimp]]] {
    set chan [open $filename]
    set name [gets $chan]
    set params "Tcl_Interp* interp"
    set number 2
    while {1} {
        incr number
        set line [gets $chan]
        if {$line eq ""} {
            break
        }
        append params " $line"
    }
    set body "\n#line $number \"[file tail $filename]\"\n[read $chan]"
    close $chan
    namespace eval ::crimp [list ::critcl::cproc $name $params ok $body]
}

# # ## ### ##### ######## #############
## Pull in the Tcl layer aggregating the C primitives into useful
## commands.
##
## NOTE: This is for the interactive use of crimp.tcl. When used as
##       plain package the 'tsources' declaration at the top ensures
##       the distribution and use of the Tcl layer.

source [file join [file dirname [file normalize [info script]]] crimp_tcl.tcl]

# # ## ### ##### ######## #############
## Ready. Export.

package provide crimp 1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
