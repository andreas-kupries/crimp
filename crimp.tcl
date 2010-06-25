#!/bin/sh
# The next line restarts with tclsh.\
exec tclsh "$0" ${1+"$@"}

set dir [file dirname [info script]]
lappend auto_path [file join $dir critcl.vfs lib]

package require Tk
package require critcl

proc take {varname} {
    upvar 1 $varname var
    return $var[set var ""]
}

critcl::config tk 1

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>

    #define MIN(a, b) ((a) < (b) ? (a) : (b))
    #define MAX(a, b) ((a) > (b) ? (a) : (b))
    #define CLAMP(min, v, max) ((v) < (min) ? (min) : (v) < (max) ? (v) : (max))

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

namespace eval crimp {namespace ensemble create}

foreach filename [lsort [glob -nocomplain [file join $dir *.crimp]]] {
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
    namespace ensemble configure ::crimp -subcommands [concat\
            [namespace ensemble configure crimp -subcommands] [list $name]]
    namespace eval ::crimp [list ::critcl::cproc $name $params ok $body]
    close $chan
}

set photo [image create photo -file [file join $dir conformer.png]]
set image [crimp import $photo]
label .l -image $photo
pack .l
scale .s -from -180 -to 180 -orient horizontal -command [list apply {
{photo image angle} {
    set s [expr {sin($angle * 0.017453292519943295769236907684886)}]
    set c [expr {cos($angle * 0.017453292519943295769236907684886)}]
    set matrix [list [list $c $s 0] [list [expr {-$s}] $c 0] [list $s $s 1]]
    crimp export $photo [crimp matrix $image $matrix]
}} $photo $image]
pack .s -fill x

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
